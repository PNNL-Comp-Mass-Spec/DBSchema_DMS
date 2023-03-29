/****** Object:  StoredProcedure [dbo].[get_spectral_library_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_spectral_library_id]
/****************************************************
**
**  Desc:
**      Looks for an existing entry in T_Spectral_Library that matches the specified settings
**      If found, returns the spectral library ID and state
**      If not found, and if @allowAddNew = 1, adds a new row to T_Spectral_Library
**
**  Returns:
**    Spectral library ID, state, name, and storage path (server share), using output parameters @libraryId, @libraryStateId, @libraryName, and @storagePath
**
**  Auth:   mem
**  Date:   03/17/2023 mem - Initial Release
**          03/18/2023 mem - Rename parameters
**                         - Add output parameter @sourceJobShouldMakeLibrary
**                         - Append organism name to the storage path
**                         - Assign the source job to the spectral library if it has state 1 and @allowAddNew is enabled
**          03/19/2023 mem - Truncate protein collection lists to 110 characters
**                         - Remove the extension from legacy FASTA file names
**          03/28/2023 mem - Change @allowAddNew, @trimNTerminalMet, and @staticCysCarbamidomethyl from tinyint to bit
**          03/29/2023 mem - If the library state is 2 and @dmsSourceJob matches the Source_Job in T_Spectral_Library, assume the job failed and was re-started, and thus set @sourceJobShouldMakeLibrary to 1
**                         - Change tinyint parameters to smallint or bit
**
*****************************************************/
(
    @allowAddNew bit,
    @dmsSourceJob int = 0,
    @proteinCollectionList varchar(2000) = '',
    @organismDbFile varchar(128) = '',
    @fragmentIonMzMin real = 0,
    @fragmentIonMzMax real = 0,
    @trimNTerminalMet bit = 0,
    @cleavageSpecificity varchar(64) = '',
    @missedCleavages int = 0,
    @peptideLengthMin smallint = 0,
    @peptideLengthMax smallint = 0,
    @precursorMzMin real = 0,
    @precursorMzMax real = 0,
    @precursorChargeMin smallint = 0,
    @precursorChargeMax smallint = 0,
    @staticCysCarbamidomethyl bit = 0,
    @staticMods varchar(512) = '',
    @dynamicMods varchar(512) = '',
    @maxDynamicMods smallint = 0,
    @infoOnly tinyint = 0,
    @libraryId int = 0 output,
    @libraryStateId int = 0 output,
    @libraryName varchar(255) = '' output,
    @storagePath varchar(255) = '' output,
    @sourceJobShouldMakeLibrary bit = 0 output,
    @message varchar(255) = '' Output,
    @returnCode varchar(64) = '' Output
)
As
Begin
    Declare @myRowCount int = 0
    Declare @myError int = 0

    -- Default library name, without the suffix '.predicted.speclib'
    Declare @defaultLibraryName varchar(2000)           -- This is varchar(2000) for compatibility with @proteinCollectionList
    Declare @libraryNameHash varchar(64)

    Declare @hash varchar(64)
    Declare @defaultStoragePath varchar(255)

    Declare @commaPosition int
    Declare @periodLocation int

    Declare @proteinCollection varchar(255)
    Declare @organism varchar(128)

    Declare @libraryTypeId int
    Declare @libraryCreated Datetime

    Declare @existingSourceJob int
    Declare @existingHash varchar(64)

    Declare @actualSourceJob int

    Declare @logMessage varchar(1024)

    BEGIN TRY
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        Set @allowAddNew = Coalesce(@allowAddNew, 0)
        Set @dmsSourceJob = Coalesce(@dmsSourceJob, 0)

        Set @proteinCollectionList = Ltrim(Rtrim(Coalesce(@proteinCollectionList, '')));
        Set @organismDbFile = Ltrim(Rtrim(Coalesce(@organismDbFile, '')));
        Set @fragmentIonMzMin = Coalesce(@fragmentIonMzMin, 0);
        Set @fragmentIonMzMax = Coalesce(@fragmentIonMzMax, 0);
        Set @trimNTerminalMet = Coalesce(@trimNTerminalMet, 0);
        Set @cleavageSpecificity = Ltrim(Rtrim(Coalesce(@cleavageSpecificity, '')));
        Set @missedCleavages = Coalesce(@missedCleavages, 0);
        Set @peptideLengthMin = Coalesce(@peptideLengthMin, 0);
        Set @peptideLengthMax = Coalesce(@peptideLengthMax, 0);
        Set @precursorMzMin = Coalesce(@precursorMzMin, 0);
        Set @precursorMzMax = Coalesce(@precursorMzMax, 0);
        Set @precursorChargeMin = Coalesce(@precursorChargeMin, 0);
        Set @precursorChargeMax = Coalesce(@precursorChargeMax, 0);
        Set @staticCysCarbamidomethyl = Coalesce(@staticCysCarbamidomethyl, 0);
        Set @staticMods = Ltrim(Rtrim(Coalesce(@staticMods, '')));
        Set @dynamicMods = Ltrim(Rtrim(Coalesce(@dynamicMods, '')));
        Set @maxDynamicMods = Coalesce(@maxDynamicMods, 0);
        Set @infoOnly = Coalesce(@infoOnly, 0)

        Set @libraryId = 0
        Set @libraryStateId = 0
        Set @libraryName = ''
        Set @storagePath = ''
        Set @sourceJobShouldMakeLibrary = 0
        Set @message = ''
        Set @returnCode  = ''

        Set @message = ''
        Set @returnCode = ''

        ---------------------------------------------------
        -- Assure that the protein collection list is in the standard format
        ---------------------------------------------------

        If Len(@proteinCollectionList) > 0 And dbo.validate_na_parameter(@proteinCollectionList, 1) <> 'na'
        Begin
            exec s_standardize_protein_collection_list @protCollNameList = @proteinCollectionList OUTPUT, @message = @message Output
        End

        ---------------------------------------------------
        -- Remove any spaces in the static and dynamic mods
        ---------------------------------------------------

        Set @staticMods = Replace(@staticMods, ' ', '');
        Set @dynamicMods = Replace(@dynamicMods, ' ', '');

        ---------------------------------------------------
        -- Create the default name for the spectral library, using either the protein collection list or the organism DB file name
        -- If the default name is over 110 characters long, truncate to the first 110 characters and append the SHA-1 hash of the full name.
        ---------------------------------------------------

        If dbo.validate_na_parameter(@proteinCollectionList, 1) <> 'na'
        Begin
            Set @defaultLibraryName = @proteinCollectionList

            -- Lookup the organism associated with the first protein collection in the list
            Set @commaPosition = CharIndex(',', @proteinCollectionList)

            If @commaPosition > 0
                Set @proteinCollection = Left(@proteinCollectionList, @commaPosition - 1)
            Else
                Set @proteinCollection = @proteinCollectionList

            SELECT TOP 1 @organism = Organism_Name
            FROM S_V_Protein_Collections_by_Organism
            WHERE collection_name = @proteinCollection
            ORDER BY Organism_Name
            --
            Select @myRowCount = @@RowCount, @myError = @@Error

            If @myRowCount = 0
            Begin
                Set @logMessage = 'Protein collection not found in V_Protein_Collections_by_Organism; cannot determine the organism for ' + @proteinCollection
                exec post_log_entry 'Warning', @logMessage, 'get_spectral_library_id'

                Set @organism = 'Undefined'
            End

        End
        Else If dbo.validate_na_parameter(@organismDbFile, 1) <> 'na'
        Begin
            Set @defaultLibraryName = @organismDbFile

            -- Remove the extension (which should be .fasta)
            If @defaultLibraryName Like '%.fasta'
            Begin
                Set @defaultLibraryName = Left(@defaultLibraryName, Len(@defaultLibraryName) - Len('.fasta'))
            End
            Else If @defaultLibraryName Like '%.faa'
            Begin
                Set @defaultLibraryName = Left(@defaultLibraryName, Len(@defaultLibraryName) - Len('.faa'))
            End
            Else
            Begin
                -- Find the position of the last period
                Set @periodLocation = CharIndex('.', Reverse(@defaultLibraryName))

                If @periodLocation > 0
                Begin
                    Set @periodLocation = Len(@defaultLibraryName) - @periodLocation

                    Set @defaultLibraryName = Left(@defaultLibraryName, @periodLocation)
                End
            End

            -- Lookup the organism for @organismDbFile

            SELECT @organism = Org.OG_name
            FROM T_Organism_DB_File OrgFile
                 INNER JOIN T_Organisms Org
                   ON OrgFile.Organism_ID = Org.Organism_ID
            WHERE OrgFile.FileName = @organismDbFile
            --
            Select @myRowCount = @@RowCount, @myError = @@Error

            If @myRowCount = 0
            Begin
                Set @logMessage = 'Legacy FASTA file not found in T_Organism_DB_File; cannot determine the organism for ' + @organismDbFile
                exec post_log_entry 'Warning', @logMessage, 'get_spectral_library_id'

                Set @organism = 'Undefined'
            End
        End
        Else
        Begin
            -- Cannot create a new spectral library since both the protein collection list and organism DB file are blank or "na"'
            Set @defaultLibraryName = ''
        End

        If @defaultLibraryName <> ''
        Begin
            -- Replace commas with underscores
            Set @defaultLibraryName = Replace(@defaultLibraryName, ',', '_')

            If Len(@defaultLibraryName) > 110
            Begin
                ---------------------------------------------------
                -- Convert @defaultLibraryName to a SHA-1 hash (upper case hex string)
                --
                -- Use HashBytes() to get the full SHA-1 hash, as a varbinary
                -- Use Convert() to convert to text, truncating to only use the first 32 characters
                -- The '2' sent to Convert() means 'no 0x prefix'
                ---------------------------------------------------

                Set @libraryNameHash = CONVERT(varchar(64), HashBytes('SHA1', @defaultLibraryName), 2)

                -- Truncate the library name to 110 characters, then append an underscore and the first 8 characters of the hash
                --
                Set @defaultLibraryName = Substring(@defaultLibraryName, 1, 110)

                If Right(@defaultLibraryName, 1) <> '_'
                Begin
                    Set @defaultLibraryName = @defaultLibraryName + '_'
                End

                 Set @defaultLibraryName = @defaultLibraryName + Substring(@libraryNameHash, 1, 8)
            End
        End

        ---------------------------------------------------
        -- Determine the path where the spectrum library is stored
        ---------------------------------------------------

        SELECT @defaultStoragePath = Server
        FROM T_MiscPaths
        WHERE [Function] = 'Spectral_Library_Files'
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount = 0
        Begin
            Set @message = 'Function "Spectral_Library_Files" not found in table T_MiscPaths'
            Exec post_log_entry 'Error', @message, 'get_spectral_library_id'
            Set @returnCode = 'U5201'
            Return 5201;
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @logMessage = 'Error preparing to look for an existing spectral library file: ' + @message
        exec post_log_entry 'Error', @logMessage, 'get_spectral_library_id'

        Set @returnCode = 'U5202';
        Return 5202;
    END CATCH

    BEGIN TRY
        ---------------------------------------------------
        -- Look for an existing spectral library file
        ---------------------------------------------------

        SELECT @libraryId = Library_ID,
               @libraryName = Library_Name,
               @libraryStateId = Library_State_ID,
               @libraryTypeId = Library_Type_ID,
               @libraryCreated = Created,
               @existingSourceJob = Source_Job,
               @storagePath = Storage_Path,
               @existingHash = Settings_Hash
        FROM T_Spectral_Library
        WHERE  Protein_Collection_List    = @proteinCollectionList And
               Organism_DB_File           = @organismDbFile And
               Fragment_Ion_Mz_Min        = @fragmentIonMzMin And
               Fragment_Ion_Mz_Max        = @fragmentIonMzMax And
               Trim_N_Terminal_Met        = @trimNTerminalMet And
               Cleavage_Specificity       = @cleavageSpecificity And
               Missed_Cleavages           = @missedCleavages And
               Peptide_Length_Min         = @peptideLengthMin And
               Peptide_Length_Max         = @peptideLengthMax And
               Precursor_Mz_Min           = @precursorMzMin And
               Precursor_Mz_Max           = @precursorMzMax And
               Precursor_Charge_Min       = @precursorChargeMin And
               Precursor_Charge_Max       = @precursorChargeMax And
               Static_Cys_Carbamidomethyl = @staticCysCarbamidomethyl And
               Static_Mods                = @staticMods And
               Dynamic_Mods               = @dynamicMods And
               Max_Dynamic_Mods           = @maxDynamicMods
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount > 0
        Begin
            -- Match Found

            If @libraryStateID = 1
            Begin
                If @allowAddNew > 0 And @dmsSourceJob > 0
                Begin
                    If @infoOnly > 0
                    Begin
                        Set @message = 'Found existing spectral library ID ' + Cast(@libraryId As varchar(12)) +
                                       ' with state 1; would associate source job ' + Cast(@dmsSourceJob as varchar(12)) +
                                       ' with the creation of spectra library ' + @libraryName

                        Return 0;
                    End

                    UPDATE T_Spectral_Library
                    SET Library_State_ID = 2,
                        Source_Job = @dmsSourceJob
                    WHERE Library_ID = @libraryID AND
                          Library_State_ID = 1;

                    SELECT @actualSourceJob = Source_Job,
                           @libraryStateID = Library_State_ID
                    FROM T_Spectral_Library
                    WHERE Library_ID = @libraryID;

                    If @actualSourceJob = @dmsSourceJob
                    Begin
                        Set @message = 'Found existing spectral library ID ' + Cast(@libraryId As varchar(12)) +
                                       ' with state 1; associated source job ' + Cast(@dmsSourceJob as varchar(12)) +
                                       ' with the creation of spectra library ' + @libraryName

                        Set @sourceJobShouldMakeLibrary = 1
                    End
                    Else
                    Begin
                        Set @message = 'Found existing spectral library ID ' + Cast(@libraryId As varchar(12)) +
                                       ' with state 1; tried to associate with source job ' + Cast(@dmsSourceJob as varchar(12)) +
                                       ' but library is actually associated with job ' + Cast(@actualSourceJob As varchar(12)) +
                                       ': ' + @libraryName
                    End

                    Return 0;
                End
                Else
                Begin
                    Set @message = 'Found existing spectral library ID ' + Cast(@libraryId As varchar(12)) + ' with state 1'

                    If @allowAddNew > 0 And @dmsSourceJob <= 0
                    Begin
                        Set @message = @message + '; although @allowAddNew is enabled, @dmsSourceJob is 0, so not updating the state'
                    End

                    Set @message = @message + '; spectral library is not yet ready to use: ' + @libraryName
                    Return 0;
                End
            End
            Else
            Begin
                If @libraryStateID = 2 And @dmsSourceJob > 0 And @existingSourceJob = @dmsSourceJob
                Begin                
                    Set @message = 'Found existing spectral library ID ' + Cast(@libraryId As varchar(12)) +
                                   ' with state 2, already associated with job ' + Cast(@dmsSourceJob as varchar(12)) + ': ' + @libraryName

                    Set @sourceJobShouldMakeLibrary = 1
                End 
                Else
                Begin
                    Set @message = 'Found existing spectral library ID ' + Cast(@libraryId As varchar(12)) +
                                   ' with state ' + Cast(@libraryStateID as varchar(12)) + ': ' + @libraryName
                End

                Return 0
            End
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @logMessage = 'Error looking for an existing spectral library file: ' + @message
        exec post_log_entry 'Error', @logMessage, 'get_spectral_library_id'

        Set @returnCode = 'U5203';
        Return 5203;
    END CATCH

    BEGIN TRY
        ---------------------------------------------------
        -- Match not found
        ---------------------------------------------------

        Set @libraryId = 0
        Set @libraryStateId = 0
        Set @storagePath = @defaultStoragePath

        If @defaultLibraryName = ''
        Begin
            Set @message = 'Cannot create a new spectral library since both the protein collection list and organism DB file are blank or "na"'
            Print @message
            Set @returnCode = 'U5204'

            Return 5204;
        End

        -- Append the organism name to @storagePath
        If Len(LTrim(RTrim(Coalesce(@organism, '')))) = 0
            Set @organism = 'Undefined'

        Set @storagePath = dbo.combine_paths(@storagePath, @organism);

        ---------------------------------------------------
        -- Compute a SHA-1 hash of the settings
        ---------------------------------------------------

        Exec get_spectral_library_settings_hash
                @libraryId = 0,
                @proteinCollectionList = @proteinCollectionList,
                @organismDbFile = @organismDbFile,
                @fragmentIonMzMin = @fragmentIonMzMin,
                @fragmentIonMzMax = @fragmentIonMzMax,
                @trimNTerminalMet = @trimNTerminalMet,
                @cleavageSpecificity = @cleavageSpecificity,
                @missedCleavages = @missedCleavages,
                @peptideLengthMin = @peptideLengthMin,
                @peptideLengthMax = @peptideLengthMax,
                @precursorMzMin = @precursorMzMin,
                @precursorMzMax = @precursorMzMax,
                @precursorChargeMin = @precursorChargeMin,
                @precursorChargeMax = @precursorChargeMax,
                @staticCysCarbamidomethyl = @staticCysCarbamidomethyl,
                @staticMods = @staticMods,
                @dynamicMods = @dynamicMods,
                @maxDynamicMods = @maxDynamicMods,
                @hash = @hash Output;      -- Output argument


        ---------------------------------------------------
        -- Construct the library name by appending the first 8 characters of the settings hash, plus the filename suffix to the default library name
        ---------------------------------------------------

        Set @libraryName = @defaultLibraryName + '_' + Substring(@hash, 1, 8) + '.predicted.speclib'

        If @allowAddNew = 0
        Begin
            Set @message = 'Spectral library not found, and @allowAddNew is 0; not creating ' + @libraryName
            Print @message
            Return 0;
        End

        If @infoOnly > 0
        Begin
            Set @message = 'Would create a new spectral library named ' + @libraryName
            Print @message
            Return 0;
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @logMessage = 'Error preparing to add a new spectral library file: ' + @message
        exec post_log_entry 'Error', @logMessage, 'get_spectral_library_id'

        Set @returnCode = 'U5205';
        Return 5205;
    END CATCH

    BEGIN TRY
        ---------------------------------------------------
        -- Add a new spectral library, setting the state to 2 = In Progress
        ---------------------------------------------------

        Set @libraryStateId = 2

        INSERT INTO dbo.T_Spectral_Library (
            Library_Name, Library_State_ID, Library_Type_ID,
            Created, Source_Job, Comment,
            Storage_Path, Protein_Collection_List, Organism_DB_File,
            Fragment_Ion_Mz_Min, Fragment_Ion_Mz_Max, Trim_N_Terminal_Met,
            Cleavage_Specificity, Missed_Cleavages,
            Peptide_Length_Min, Peptide_Length_Max,
            Precursor_Mz_Min, Precursor_Mz_Max,
            Precursor_Charge_Min, Precursor_Charge_Max,
            Static_Cys_Carbamidomethyl, Static_Mods, Dynamic_Mods,
            Max_Dynamic_Mods, Settings_Hash
            )
        Values (
                @libraryName,
                @libraryStateId,
                1,      -- In-silico digest of a FASTA file via a DIA-NN analysis job
                GetDate(),
                @dmsSourceJob,
                '',     -- Comment
                @storagePath,
                @proteinCollectionList,
                @organismDbFile,
                @fragmentIonMzMin,
                @fragmentIonMzMax,
                @trimNTerminalMet,
                @cleavageSpecificity,
                @missedCleavages,
                @peptideLengthMin,
                @peptideLengthMax,
                @precursorMzMin,
                @precursorMzMax,
                @precursorChargeMin,
                @precursorChargeMax,
                @staticCysCarbamidomethyl,
                @staticMods,
                @dynamicMods,
                @maxDynamicMods,
                @hash
                )

        Set @libraryId = Scope_Identity()

        Set @sourceJobShouldMakeLibrary = 1

        Set @message = 'Created spectral library ID ' + Cast(@libraryId As varchar(12)) + ': ' + @libraryName
        Print @message

        Return 0

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @logMessage = 'Error adding a new spectral library file: ' + @message
        exec post_log_entry 'Error', @logMessage, 'get_spectral_library_id'

        Set @returnCode = 'U5206';
        Return 5206;

    END CATCH
END

GO
GRANT EXECUTE ON [dbo].[get_spectral_library_id] TO [DMSWebUser] AS [dbo]
GO

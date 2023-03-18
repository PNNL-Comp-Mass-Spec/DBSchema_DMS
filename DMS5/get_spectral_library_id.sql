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
**      If not found, and if @allow_add_new = 1, adds a new row to T_Spectral_Library
**
**  Returns:
**    Spectral library ID, state, name, and storage path (server share), using output parameters @library_id, @library_state_id, @library_name, and @storage_path
**
**  Auth:   mem
**  Date:   03/17/2023 mem - Initial Release
**
*****************************************************/
(
    @allow_add_new tinyint,
    @dms_source_job int = 0,
    @protein_collection_list varchar(2000) = '',
    @organism_db_file varchar(128) = '',
    @fragment_ion_mz_min real = 0,
    @fragment_ion_mz_max real = 0,
    @trim_n_terminal_met tinyint = 0,
    @cleavage_specificity varchar(64) = '',
    @missed_cleavages int = 0,
    @peptide_length_min tinyint = 0,
    @peptide_length_max tinyint = 0,
    @precursor_mz_min real = 0,
    @precursor_mz_max real = 0,
    @precursor_charge_min tinyint = 0,
    @precursor_charge_max tinyint = 0,
    @static_cys_carbamidomethyl tinyint = 0,
    @static_mods varchar(512) = '',
    @dynamic_mods varchar(512) = '',
    @max_dynamic_mods tinyint = 0,
    @infoOnly tinyint = 0,
    @library_id int = 0 output,
    @library_state_id int = 0 output,
    @library_name varchar(255) = '' output,
    @storage_path varchar(255) = '' output,
    @message varchar(255) = '' Output,
    @return_code varchar(64) = '' Output
)
As
Begin
    Declare @myRowCount int = 0
    Declare @myError int = 0
    
    -- Default library name, without the suffix '.predicted.speclib'
    Declare @default_library_name varchar(255)
    Declare @library_name_hash Varchar(64)

    Declare @hash varchar(64)
    Declare @default_storage_path Varchar(255)

    Declare @library_type_id int
    Declare @library_created Datetime

    Declare @existing_source_job int
    Declare @existing_hash varchar(64)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @allow_add_new = Coalesce(@allow_add_new, 0)
    Set @dms_source_job = Coalesce(@dms_source_job, 0)

    Set @protein_collection_list = Ltrim(Rtrim(Coalesce(@protein_collection_list, '')));
    Set @organism_db_file = Ltrim(Rtrim(Coalesce(@organism_db_file, '')));
    Set @fragment_ion_mz_min = Coalesce(@fragment_ion_mz_min, 0);
    Set @fragment_ion_mz_max = Coalesce(@fragment_ion_mz_max, 0);
    Set @trim_n_terminal_met = Coalesce(@trim_n_terminal_met, 0);
    Set @cleavage_specificity = Ltrim(Rtrim(Coalesce(@cleavage_specificity, '')));
    Set @missed_cleavages = Coalesce(@missed_cleavages, 0);
    Set @peptide_length_min = Coalesce(@peptide_length_min, 0);
    Set @peptide_length_max = Coalesce(@peptide_length_max, 0);
    Set @precursor_mz_min = Coalesce(@precursor_mz_min, 0);
    Set @precursor_mz_max = Coalesce(@precursor_mz_max, 0);
    Set @precursor_charge_min = Coalesce(@precursor_charge_min, 0);
    Set @precursor_charge_max = Coalesce(@precursor_charge_max, 0);
    Set @static_cys_carbamidomethyl = Coalesce(@static_cys_carbamidomethyl, 0);
    Set @static_mods = Ltrim(Rtrim(Coalesce(@static_mods, '')));
    Set @dynamic_mods = Ltrim(Rtrim(Coalesce(@dynamic_mods, '')));
    Set @max_dynamic_mods = Coalesce(@max_dynamic_mods, 0);
    Set @infoOnly = Coalesce(@infoOnly, 0)

    Set @message = ''
    Set @return_code = ''

    ---------------------------------------------------
    -- Assure that the protein collection list is in the standard format
    ---------------------------------------------------

    If Len(@protein_collection_list) > 0 And dbo.validate_na_parameter(@protein_collection_list, 1) <> 'na'
    Begin
        exec s_standardize_protein_collection_list @protCollNameList = @protein_collection_list OUTPUT, @message = @message Output
    End


    ---------------------------------------------------
    -- Remove any spaces in the static and dynamic mods
    ---------------------------------------------------

    Set @static_mods = Replace(@static_mods, ' ', '');
    Set @dynamic_mods = Replace(@dynamic_mods, ' ', '');
    
    ---------------------------------------------------
    -- Create the default name for the spectral library, using either the protein collection list or the organism DB file name
    -- If the default name is over 175 characters long, truncate to the first 175 characters and append the SHA-1 hash of the full name.
    ---------------------------------------------------

    If dbo.validate_na_parameter(@protein_collection_list, 1) <> 'na'
    Begin
        Set @default_library_name = @protein_collection_list
    End
    Else If dbo.validate_na_parameter(@organism_db_file, 1) <> 'na'
    Begin
        Set @default_library_name = @organism_db_file
    End
    Else
    Begin
        -- Cannot create a new spectral library since both the protein collection list and organism DB file are blank or "na"'
        Set @default_library_name = ''
    End
    
    If @default_library_name <> ''
    Begin
        -- Replace commas with underscores
        Set @default_library_name = Replace(@default_library_name, ',', '_')

        If Len(@default_library_name) > 175
        Begin
            ---------------------------------------------------
            -- Convert @default_library_name to a SHA-1 hash (upper case hex string)
            --
            -- Use HashBytes() to get the full SHA-1 hash, as a varbinary
            -- Use Convert() to convert to text, truncating to only use the first 32 characters
            -- The '2' sent to Convert() means 'no 0x prefix'
            ---------------------------------------------------

            Set @library_name_hash = CONVERT(varchar(64), HashBytes('SHA1', @default_library_name), 2)

            -- Truncate the library name to 175 characters, then append an underscore and the first 8 characters of the hash
            --
            Set @default_library_name = Substring(@default_library_name, 1, 175)

            If Right(@default_library_name, 1) <> '_'
            Begin
                Set @default_library_name = @default_library_name + '_'
            End

             Set @default_library_name = @default_library_name + Substring(@library_name_hash, 1, 8)
        End       
    End

    ---------------------------------------------------
    -- Determine the path where the spectrum library is stored
    ---------------------------------------------------
    
    SELECT @default_storage_path = Server
    FROM T_MiscPaths
    WHERE [Function] = 'Spectral_Library_Files'
    --
    Select @myRowCount = @@RowCount, @myError = @@Error

    If @myRowCount = 0
    Begin
        Set @message = 'Function "Spectral_Library_Files" not found in table T_MiscPaths'
        Exec post_log_entry 'Error', @message, 'get_spectral_library_id'
        Set @return_code = 'U5201'
        Return 5201;
    End

    ---------------------------------------------------
    -- Look for an existing spectral library file
    ---------------------------------------------------

    Declare @transactionName Varchar(64) = 'Look for spectral library'

    Begin Tran @transactionName

    SELECT @library_id = Library_ID,
           @library_name = Library_Name,
           @library_state_id = Library_State_ID,
           @library_type_id = Library_Type_ID,
           @library_created = Created,
           @existing_source_job = Source_Job,
           @storage_path = Storage_Path,
           @existing_hash = Settings_Hash
    FROM T_Spectral_Library
    WHERE  Protein_Collection_List    = @protein_collection_list And
           Organism_DB_File           = @organism_db_file And
           Fragment_Ion_Mz_Min        = @fragment_ion_mz_min And
           Fragment_Ion_Mz_Max        = @fragment_ion_mz_max And
           Trim_N_Terminal_Met        = @trim_n_terminal_met And
           Cleavage_Specificity       = @cleavage_specificity And
           Missed_Cleavages           = @missed_cleavages And
           Peptide_Length_Min         = @peptide_length_min And
           Peptide_Length_Max         = @peptide_length_max And
           Precursor_Mz_Min           = @precursor_mz_min And
           Precursor_Mz_Max           = @precursor_mz_max And
           Precursor_Charge_Min       = @precursor_charge_min And
           Precursor_Charge_Max       = @precursor_charge_max And
           Static_Cys_Carbamidomethyl = @static_cys_carbamidomethyl And
           Static_Mods                = @static_mods And
           Dynamic_Mods               = @dynamic_mods And
           Max_Dynamic_Mods           = @max_dynamic_mods
    --
    Select @myRowCount = @@RowCount, @myError = @@Error

    If @myRowCount > 0
    Begin
        -- Match Found
        Commit Tran @transactionName

        Set @message = 'Found existing spectral library ID ' + Cast(@library_id As Varchar(12)) + ': ' + @library_name
        Return 0
    End

    ---------------------------------------------------
    -- Match not found
    ---------------------------------------------------

    Set @library_id = 0
    Set @library_state_id = 0
    Set @storage_path = @default_storage_path

    If @default_library_name = ''
    Begin
        Set @message = 'Cannot create a new spectral library since both the protein collection list and organism DB file are blank or "na"'
        Print @message
        Set @return_code = 'U5202'

        Commit Tran @transactionName
        Return 5205;
    End
        
    ---------------------------------------------------
    -- Compute a SHA-1 hash of the settings
    ---------------------------------------------------

    Exec get_spectral_library_settings_hash
            @library_id = 0,
            @protein_collection_list = @protein_collection_list,
            @organism_db_file = @organism_db_file,
            @fragment_ion_mz_min = @fragment_ion_mz_min,
            @fragment_ion_mz_max = @fragment_ion_mz_max,
            @trim_n_terminal_met = @trim_n_terminal_met,
            @cleavage_specificity = @cleavage_specificity,
            @missed_cleavages = @missed_cleavages,
            @peptide_length_min = @peptide_length_min,
            @peptide_length_max = @peptide_length_max,
            @precursor_mz_min = @precursor_mz_min,
            @precursor_mz_max = @precursor_mz_max,
            @precursor_charge_min = @precursor_charge_min,
            @precursor_charge_max = @precursor_charge_max,
            @static_cys_carbamidomethyl = @static_cys_carbamidomethyl,
            @static_mods = @static_mods,
            @dynamic_mods = @dynamic_mods,
            @max_dynamic_mods = @max_dynamic_mods,
            @hash = @hash Output;      -- Output argument

                 
    ---------------------------------------------------
    -- Construct the library name by appending the first 8 characters of the settings hash, plus the filename suffix to the default library name
    ---------------------------------------------------

    Set @library_name = @default_library_name + '_' + Substring(@hash, 1, 8) + '.predicted.speclib'

    If @allow_add_new = 0
    Begin
        Set @message = 'Spectral library not found, and @allow_add_new is 0; not creating ' + @library_name
        Print @message

        Commit Tran @transactionName
        Return 0;
    End
    
    If @infoOnly > 0
    Begin
        Set @message = 'Would create a new spectral library named ' + @library_name
        Print @message

        Commit Tran @transactionName
        Return 0;
    End

    ---------------------------------------------------
    -- Add a new spectral library, setting the state to 2 = In Progress
    ---------------------------------------------------

    Set @library_state_id = 2

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
            @library_name, 
            @library_state_id,
            1,      -- In-silico digest of a FASTA file via a DIA-NN analysis job
            GetDate(),
            @dms_source_job,
            '',     -- Comment
            @storage_path,
            @protein_collection_list,
            @organism_db_file,
            @fragment_ion_mz_min,
            @fragment_ion_mz_max,
            @trim_n_terminal_met,
            @cleavage_specificity,
            @missed_cleavages,
            @peptide_length_min,
            @peptide_length_max,
            @precursor_mz_min,
            @precursor_mz_max,
            @precursor_charge_min,
            @precursor_charge_max,
            @static_cys_carbamidomethyl,
            @static_mods,
            @dynamic_mods,
            @max_dynamic_mods,
            @hash
            )

    Set @library_id = Scope_Identity()

    Commit Tran @transactionName

    Set @message = 'Created spectral library ID ' + Cast(@library_id As Varchar(12)) + ': ' + @library_name
    Print @message

    Return 0
END

GO

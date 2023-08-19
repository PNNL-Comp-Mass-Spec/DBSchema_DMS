/****** Object:  StoredProcedure [dbo].[add_output_file_archive_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_output_file_archive_entry]
/****************************************************
**
**  Desc: Adds a new entry to the T_Archived_Output_Files
**
**  Return values: Archived_File_ID (nonzero) : success, otherwise, error code
**
**  Arguments:
**    @proteinCollectionID          Protein collection ID (of the first protein collection, if combining multiple protein collections)
**    @crc32Authentication          CRC32 authentication hash (hash of the bytes in the file)
**    @fileModificationDate         File modification timestamp
**    @fileSize                     File size, in bytes
**    @proteinCount                 Protein count
**    @archivedFileType             Archived file type ('static' if a single protein collection; 'dynamic' if a combination of multiple protein collections)
**    @creationOptions              Creation options (e.g. 'seq_direction=forward,filetype=fasta')
**    @proteinCollectionString      Protein collection list (comma-separated list of protein collection names)
**    @collectionStringHash         SHA-1 hash of the protein collection list and creation options (separated by a forward slash)
**                                  For example, 'H_sapiens_UniProt_SPROT_2023-03-01,Tryp_Pig_Bov/seq_direction=forward,filetype=fasta' has SHA-1 hash '11822db6bbfc1cb23c0a728a0b53c3b9d97db1f5'
**    @archivedFilePath             Input/Output: archived file path
**
**  This procedure updates the filename in @archivedFilePath to replace 00000 with the file ID in T_Archived_Output_Files (padded using '000000')
**  For example,  '\\gigasax\DMS_FASTA_File_Archive\Dynamic\Forward\ID_00000_C1CEE570.fasta'
**  is changed to '\\gigasax\DMS_FASTA_File_Archive\Dynamic\Forward\ID_004226_C1CEE570.fasta'  
**
**  Auth:   kja
**  Date:   03/10/2006
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**          08/18/2023 mem - When checking for an existing row in T_Archived_Output_Files, use both @crc32Authentication and @collectionStringHash
**                         - Update the file ID in @archivedFilePath even if an existing entry is found in T_Archived_Output_Files
**
*****************************************************/
(
    @proteinCollectionID int,
    @crc32Authentication varchar(8),
    @fileModificationDate datetime,
    @fileSize bigint,
    @proteinCount int = 0,
    @archivedFileType varchar(64),
    @creationOptions varchar(250),
    @proteinCollectionString varchar(8000),
    @collectionStringHash varchar(40),
    @archivedFilePath varchar(250) output,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    -- Is the hash the right length?

    If LEN(@crc32Authentication) <> 8
    Begin
        Set @myError = -51000
        Set @message = 'Authentication hash must be 8 alphanumeric characters in length (0-9, A-F)'
        RAISERROR (@message, 10, 1)
        RETURN @myError
    End

    -- Does this hash code already exist?

    Declare @ArchiveEntryID int = 0

    SELECT TOP 1 @ArchiveEntryID = Archived_File_ID
    FROM dbo.T_Archived_Output_Files
    WHERE Authentication_Hash = @crc32Authentication AND
          Collection_List_Hex_Hash = Coalesce(@collectionStringHash, '')
    ORDER BY Archived_File_ID DESC
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Database retrieval error during hash duplication check'
        RAISERROR (@message, 10, 1)
        Return @myError
    End

    --  If @myRowCount > 0
    --  Begin

    --      Set @myError = -51009
    --      Set @message = 'SHA-1 Authentication Hash already exists for this collection'
    --      RAISERROR (@message, 10, 1)
    --      Return @myError
    --  End

    -- Does this protein collection even exist?

    If @proteinCollectionID Is Null
    Begin
        Set @myError = -51001
        Set @message = 'Protein collection ID is null'
        RAISERROR (@message, 10, 1)
        Return @myError
    End

    Declare @matchingProteinCollectionID int

    SELECT @matchingProteinCollectionID = ID
    FROM V_Collection_Picker
    WHERE ID = @proteinCollectionID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @myError = -51001
        Set @message = 'Protein collection ID does not exist: ' + CAST(@proteinCollectionID AS varchar(9))
        RAISERROR (@message, 10, 1)
        Return @myError
    End

    -- Is the archive path length valid?

    If LEN(LTrim(RTrim(Coalesce(@archivedFilePath, '')))) < 1
    Begin
        Set @myError = -51002
        Set @message = 'No archive path specified!'
        RAISERROR (@message, 10, 1)
        Return @myError
    End

    -- Check for existence of output file type in T_Archived_File_Types

    Declare @archivedFileTypeID int

    SELECT @archivedFileTypeID = Archived_File_Type_ID
    FROM T_Archived_File_Types
    WHERE File_Type_Name = @archivedFileType

    If Coalesce(@archivedFileTypeID, 0) < 1
    Begin
        Set @myError = -51003
        Set @message = 'archived_file_type does not exist: ' + Coalesce(@archivedFileType, '??')
        RAISERROR (@message, 10, 1)
        Return @myError
    End


/*-- Check for existence of sequence type in T_Output_Sequence_Types

    Declare @outputSequenceTypeID int

    SELECT @outputSequenceTypeID = Output_Sequence_Type_ID
        FROM T_Output_Sequence_Types
        WHERE Output_Sequence_Type = @outputSequenceType

    If @outputSequenceTypeID < 1
    Begin
        Set @myError = -51003
        Set @message = 'output_sequence_type does not exist'
        RAISERROR (@message, 10, 1)
        Return @myError
    End
*/


-- Does this path already exist?


--  SELECT Archived_File_ID
--      FROM T_Archived_Output_Files
--      WHERE (Archived_File_Path = @archivedFilePath)
--
--  SELECT @myError = @@error, @myRowCount = @@rowcount
--
--  If @myError <> 0
--  Begin
--      Set @@message = 'Database retrieval error during archive path duplication check'
--      RAISERROR (@@message, 10, 1)
--      Return @myError
--  End
--
--  If @myRowCount <> 0
--  Begin
--      Set @myError = -51010
--      Set @message = 'An archived file already exists at this location'
--      RAISERROR (@message, 10, 1)
--      Return @myError
--  End
--

    -- Determine the state of the entry based on provided data

    SELECT @myRowCount = COUNT(*)
    FROM T_Archived_Output_File_Collections_XRef
    WHERE Protein_Collection_ID = @proteinCollectionID

    Declare @archivedFileState varchar(64)

    If @myRowCount = 0
        Set @archivedFileState = 'original'
    Else
        Set @archivedFileState = 'modified'


    Declare @archivedFileStateID int

    SELECT @archivedFileStateID = Archived_File_State_ID
    FROM T_Archived_File_States
    WHERE Archived_File_State = @archivedFileState

    If @ArchiveEntryID > 0
    Begin
        Set @archivedFilePath = REPLACE(@archivedFilePath, '00000', RIGHT('000000' + CAST(@ArchiveEntryID AS VARCHAR),6))
    End
    Else
    Begin

        ---------------------------------------------------
        -- Start transaction
        ---------------------------------------------------

        Declare @transName varchar(32) = 'add_output_file_archive_entry'

        Begin transaction @transName

        ---------------------------------------------------
        -- Make the initial entry with what we have
        ---------------------------------------------------


    /*  INSERT INTO T_Archived_Output_Files (
            Archived_File_Type_ID,
            Archived_File_State_ID,
            Output_Sequence_Type_ID,
            Archived_File_Path,
            Creation_Options_String,
            SHA1Authentication,
            Archived_File_Creation_Date,
            File_Modification_Date,
            Filesize
        ) VALUES (
            @archivedFileTypeID,
            @archivedFileStateID,
            @outputSequenceTypeID,
            @archivedFilePath,
            @creationOptions,
            @sha1Authentication,
            GETDATE(),
            @fileModificationDate,
            @fileSize)
    */
        INSERT INTO T_Archived_Output_Files (
            Archived_File_Type_ID,
            Archived_File_State_ID,
            Archived_File_Path,
            Authentication_Hash,
            Archived_File_Creation_Date,
            File_Modification_Date,
            Creation_Options,
            Filesize,
            Protein_Count,
            Protein_Collection_List,
            Collection_List_Hex_Hash
        ) VALUES (
            @archivedFileTypeID,
            @archivedFileStateID,
            @archivedFilePath,
            @crc32Authentication,
            GETDATE(),
            @fileModificationDate,
            @creationOptions,
            @fileSize,
            @proteinCount,
            @proteinCollectionString,
            @collectionStringHash)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Insert operation failed: Archive File Entry for file with hash = "' + @crc32Authentication + '"'
            RAISERROR (@message, 10, 1)
            Return -51007
        End

        SELECT @ArchiveEntryID = @@Identity

        Set @archivedFilePath = REPLACE(@archivedFilePath, '00000', RIGHT('000000' + CAST(@ArchiveEntryID AS VARCHAR),6))

        UPDATE T_Archived_Output_Files
        Set Archived_File_Path = @archivedFilePath
        WHERE Archived_File_ID = @ArchiveEntryID

        ---------------------------------------------------
        -- Parse and Store Creation Options
        ---------------------------------------------------

        Declare @tmpOptionKeyword varchar(64) = ''
        Declare @tmpOptionKeywordID int
        Declare @tmpOptionValue varchar(64) = ''
        Declare @tmpOptionValueID int

        Declare @tmpOptionString varchar(512) = ''

        Declare @tmpEqualsPosition int = 0
        Declare @tmpStartPosition int = 0
        Declare @tmpEndPosition int = 0
        Declare @tmpCommaPosition int = 0

        Set @tmpCommaPosition = CHARINDEX(',', @creationOptions)

        If @tmpCommaPosition = 0
        Begin
            Set @tmpCommaPosition = LEN(@creationOptions)
        End

        WHILE(@tmpCommaPosition < LEN(@creationOptions))
        Begin
            Set @tmpCommaPosition = CHARINDEX(',', @creationOptions, @tmpStartPosition)
            If @tmpCommaPosition = 0
            Begin
                Set @tmpCommaPosition = LEN(@creationOptions) + 1
            End
            Set @tmpEndPosition = @tmpCommaPosition - @tmpStartPosition
            Set @tmpOptionString = LTRIM(SUBSTRING(@creationOptions, @tmpStartPosition, @tmpCommaPosition))
            Set @tmpEqualsPosition = CHARINDEX('=', @tmpOptionString)

            Set @tmpOptionKeyword = LEFT(@tmpOptionString, @tmpEqualsPosition - 1)
            Set @tmpOptionValue = RIGHT(@tmpOptionString, LEN(@tmpOptionString) - @tmpEqualsPosition)

            SELECT @tmpOptionKeywordID = Keyword_ID
            FROM T_Creation_Option_Keywords
            WHERE Keyword = @tmpOptionKeyword

            SELECT @myError = @@error, @myRowCount = @@rowcount
            If @myError > 0
            Begin
                Set @message = 'Database retrieval error during keyword validity check'
                Return @myError
            End

            If @myRowCount = 0
            Begin
                Set @message = 'Keyword: "' + @tmpOptionKeyword + '" not located'
                Return -50011
            End

            If @myError = 0 and @myRowCount > 0
            Begin
                SELECT @tmpOptionValueID = Value_ID
                FROM T_Creation_Option_Values
                WHERE Value_String = @tmpOptionValue

                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myError > 0
                Begin
                    Set @message = 'Database retrieval error during value validity check'
                End

                If @myRowCount = 0
                Begin
                    Set @message = 'Value: "' + @tmpOptionValue + '" not located'
                End

                If @myError = 0 and @myRowCount > 0
                Begin
                    INSERT INTO T_Archived_File_Creation_Options (
                        Keyword_ID,
                        Value_ID,
                        Archived_File_ID
                    ) VALUES (
                        @tmpOptionKeywordID,
                        @tmpOptionValueID,
                        @ArchiveEntryID)
                End

                If @myError <> 0
                Begin
                    rollback transaction @transName
                    Set @message = 'Insert operation failed: Creation Options'
                    RAISERROR (@message, 10, 1)
                    Return -51007
                End

            End

            Set @tmpStartPosition = @tmpCommaPosition + 1
        End

        INSERT INTO T_Archived_Output_File_Collections_XRef (
            Archived_File_ID,
            Protein_Collection_ID
        ) VALUES (
            @ArchiveEntryID,
            @proteinCollectionID)

        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Insert operation failed: Archive File Member Entry for "' + @proteinCollectionID + '"'
            RAISERROR (@message, 10, 1)
            Return -51011
        End

        commit transaction @transName

    End

    Return @ArchiveEntryID


GO
GRANT EXECUTE ON [dbo].[add_output_file_archive_entry] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_output_file_archive_entry] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_output_file_archive_entry] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_output_file_archive_entry] TO [svc-dms] AS [dbo]
GO

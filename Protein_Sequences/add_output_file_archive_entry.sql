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
**  Auth:   kja
**  Date:   03/10/2006
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
/*  @proteinCollectionID int,
    @sha1Authentication varchar(40),
    @fileModificationDate datetime,
    @fileSize bigint,
    @archivedFilePath varchar(250),
    @archivedFileType varchar(64),
    @outputSequenceType varchar(64),
    @creationOptions varchar(250),
    @message varchar(512) output
*/
    @proteinCollectionID int,
    @crc32Authentication varchar(8),
    @fileModificationDate datetime,
    @fileSize bigint,
    @proteinCount int = 0,
    @archivedFileType varchar(64),
    @creationOptions varchar(250),
    @proteinCollectionString VARCHAR (8000),
    @collectionStringHash varchar(40),
    @archivedFilePath varchar(250) output,
    @message varchar(512) output

)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

-- is the hash the right length?

    set @myError = 0
    if LEN(@crc32Authentication) <> 8
    begin
        set @myError = -51000
        set @msg = 'Authentication hash must be 8 alphanumeric characters in length (0-9, A-F)'
        RAISERROR (@msg, 10, 1)
    end



-- does this hash code already exist?

    declare @ArchiveEntryID int
    set @ArchiveEntryID = 0
    declare @skipOutputTableAdd int

    SELECT @ArchiveEntryID = Archived_File_ID
        FROM V_Archived_Output_Files
        WHERE (Authentication_Hash = @crc32Authentication)


    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myError <> 0
    begin
        set @msg = 'Database retrieval error during hash duplication check'
        RAISERROR (@msg, 10, 1)
        set @message = @msg
        Return @myError
    end

--  if @myRowCount > 0
--  begin

--      set @myError = -51009
--      set @msg = 'SHA-1 Authentication Hash already exists for this collection'
--      RAISERROR (@msg, 10, 1)
--      Return @myError
--  end



-- Does this protein collection even exist?


    SELECT ID FROM V_Collection_Picker
     WHERE (ID = @proteinCollectionID)


    SELECT @myError = @@error, @myRowCount = @@rowcount


    if @myRowCount = 0
    begin
        set @myError = -51001
        set @msg = 'Collection does not exist'
        RAISERROR (@msg, 10, 1)
        Return @myError
    end



-- Is the archive path length valid?

    if LEN(@archivedFilePath) < 1
    begin
        set @myError = -51002
        set @msg = 'No archive path specified!'
        RAISERROR (@msg, 10, 1)
        Return @myError
    end




-- Check for existence of output file type in T_Archived_File_Types

    declare @archivedFileTypeID int

    SELECT @archivedFileTypeID = Archived_File_Type_ID
        FROM T_Archived_File_Types
        WHERE File_Type_Name = @archivedFileType

    if @archivedFileTypeID < 1
    begin
        set @myError = -51003
        set @msg = 'archived_file_type does not exist'
        RAISERROR (@msg, 10, 1)
        Return @myError
    end


/*-- Check for existence of sequence type in T_Output_Sequence_Types

    declare @outputSequenceTypeID int

    SELECT @outputSequenceTypeID = Output_Sequence_Type_ID
        FROM T_Output_Sequence_Types
        WHERE Output_Sequence_Type = @outputSequenceType

    if @outputSequenceTypeID < 1
    begin
        set @myError = -51003
        set @msg = 'output_sequence_type does not exist'
        RAISERROR (@msg, 10, 1)
        Return @myError
    end
*/


-- Does this path already exist?


--  SELECT Archived_File_ID
--      FROM T_Archived_Output_Files
--      WHERE (Archived_File_Path = @archivedFilePath)
--
--  SELECT @myError = @@error, @myRowCount = @@rowcount
--
--  if @myError <> 0
--  begin
--      set @msg = 'Database retrieval error during archive path duplication check'
--      RAISERROR (@msg, 10, 1)
--      set @message = @msg
--      Return @myError
--  end
--
--  if @myRowCount <> 0
--  begin
--      set @myError = -51010
--      set @msg = 'An archived file already exists at this location'
--      RAISERROR (@msg, 10, 1)
--      Return @myError
--  end
--

--  if @myError <> 0
--  begin
--      set @message = @msg
--      Return @myError
--  end


-- Determine the state of the entry based on provided data

    SELECT Archived_File_ID
    FROM T_Archived_Output_File_Collections_XRef
    WHERE Protein_Collection_ID = @proteinCollectionID

    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myError <> 0
    begin
        set @msg = 'Database retrieval error'
        RAISERROR (@msg, 10, 1)
        set @message = @msg
        Return @myError
    end

    declare @archivedFileState varchar(64)

    if @myRowCount = 0
    begin
        SET @archivedFileState = 'original'
    end

    if @myRowCount > 0
    begin
        SET @archivedFileState = 'modified'
    end

    declare @archivedFileStateID int

    SELECT @archivedFileStateID = Archived_File_State_ID
    FROM T_Archived_File_States
    WHERE Archived_File_State = @archivedFileState





    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_output_file_archive_entry'
    begin transaction @transName






    ---------------------------------------------------
    -- Make the initial entry with what we have
    ---------------------------------------------------

    if @ArchiveEntryID = 0
    begin

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


        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @msg = 'Insert operation failed: Archive File Entry for file with hash = "' + @crc32Authentication + '"'
            RAISERROR (@msg, 10, 1)
            set @message = @msg
            Return -51007
        end


        SELECT @ArchiveEntryID = @@Identity

        set @archivedFilePath = REPLACE(@archivedFilePath, '00000', RIGHT('000000'+CAST(@ArchiveEntryID AS VARCHAR),6))

        UPDATE T_Archived_Output_Files
        SET Archived_File_Path = @archivedFilePath
        WHERE Archived_File_ID = @ArchiveEntryID

    ---------------------------------------------------
    -- Parse and Store Creation Options
    ---------------------------------------------------

    declare @tmpOptionKeyword varchar(64)
    SET @tmpOptionKeyword = ''
    declare @tmpOptionKeywordID int
    declare @tmpOptionValue varchar(64)
    set @tmpOptionValue = ''
    declare @tmpOptionValueID int

    declare @tmpOptionString varchar(512)
    SET @tmpOptionString = ''

    declare @tmpEqualsPosition int
    declare @tmpStartPosition int
    declare @tmpEndPosition int
    declare @tmpCommaPosition int

    SET @tmpEqualsPosition = 0
    SET @tmpStartPosition = 0
    SET @tmpEndPosition = 0
    SET @tmpCommaPosition = 0

    SET @tmpCommaPosition =  CHARINDEX(',', @creationOptions)
    if @tmpCommaPosition = 0
    begin
        SET @tmpCommaPosition = LEN(@creationOptions)
    end

        WHILE(@tmpCommaPosition < LEN(@creationOptions))
        begin
            SET @tmpCommaPosition = CHARINDEX(',', @creationOptions, @tmpStartPosition)
            if @tmpCommaPosition = 0
            begin
                SET @tmpCommaPosition = LEN(@creationOptions) + 1
            end
            SET @tmpEndPosition = @tmpCommaPosition - @tmpStartPosition
            SET @tmpOptionString = LTRIM(SUBSTRING(@creationOptions, @tmpStartPosition, @tmpCommaPosition))
            SET @tmpEqualsPosition = CHARINDEX('=', @tmpOptionString)

            SET @tmpOptionKeyword = LEFT(@tmpOptionString, @tmpEqualsPosition - 1)
            SET @tmpOptionValue = RIGHT(@tmpOptionString, LEN(@tmpOptionString) - @tmpEqualsPosition)

            SELECT @tmpOptionKeywordID = Keyword_ID
            FROM T_Creation_Option_Keywords
            WHERE Keyword = @tmpOptionKeyword

            SELECT @myError = @@error, @myRowCount = @@rowcount
            if @myError > 0
            begin
                SET @msg = 'Database retrieval error during keyword validity check'
                SET @message = @msg
                Return @myError
            end

            if @myRowCount = 0
            begin
                SET @msg = 'Keyword: "' + @tmpOptionKeyword + '" not located'
                SET @message = @msg
                Return -50011
            end



            if @myError = 0 and @myRowCount > 0
            begin
                SELECT @tmpOptionValueID = Value_ID
                FROM T_Creation_Option_Values
                WHERE Value_String = @tmpOptionValue

                SELECT @myError = @@error, @myRowCount = @@rowcount

                if @myError > 0
                begin
                    SET @msg = 'Database retrieval error during value validity check'
                    SET @message = @msg
                end

                if @myRowCount = 0
                begin
                    SET @msg = 'Value: "' + @tmpOptionValue + '" not located'
                    SET @message = @msg
                end

                if @myError = 0 and @myRowCount > 0
                begin
                INSERT INTO T_Archived_File_Creation_Options (
                    Keyword_ID,
                    Value_ID,
                    Archived_File_ID
                ) VALUES (
                    @tmpOptionKeywordID,
                    @tmpOptionValueID,
                    @ArchiveEntryID)

                end

                if @myError <> 0
                begin
                    rollback transaction @transName
                    set @msg = 'Insert operation failed: Creation Options'
                    RAISERROR (@msg, 10, 1)
                    set @message = @msg
                    Return -51007
                end



            end


            SET @tmpStartPosition = @tmpCommaPosition + 1
        end




        INSERT INTO T_Archived_Output_File_Collections_XRef (
            Archived_File_ID,
            Protein_Collection_ID
        ) VALUES (
            @ArchiveEntryID,
            @proteinCollectionID)

        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @msg = 'Insert operation failed: Archive File Member Entry for "' + @proteinCollectionID + '"'
            RAISERROR (@msg, 10, 1)
            set @message = @msg
            Return -51011
        end
    end


    commit transaction @transName

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

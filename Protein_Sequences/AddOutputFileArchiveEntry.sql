/****** Object:  StoredProcedure [dbo].[AddOutputFileArchiveEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddOutputFileArchiveEntry]
/****************************************************
**
**	Desc: Adds a new entry to the T_Archived_Output_Files
**
**	Return values: Archived_File_ID (nonzero) : success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 03/10/2006
**
**    
*****************************************************/
(
/*	@protein_collection_ID int,
	@sha1_authentication varchar(40),
	@file_modification_date datetime,
	@file_size bigint,
	@archived_file_path varchar(250),
	@archived_file_type varchar(64),
	@output_sequence_type varchar(64),
	@creation_options varchar(250),	 
	@message varchar(512) output
*/
	@protein_collection_ID int,
	@crc32_authentication varchar(8),
	@file_modification_date datetime,
	@file_size bigint,
	@protein_count int = 0,
	@archived_file_type varchar(64),
	@creation_options varchar(250),
	@protein_collection_string VARCHAR (8000),
	@collection_string_hash varchar(40),
	@archived_file_path varchar(250) output,	 
	@message varchar(512) output

)
As
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
	if LEN(@crc32_authentication) <> 8
	begin
		set @myError = -51000
		set @msg = 'Authentication hash must be 8 alphanumeric characters in length (0-9, A-F)'
		RAISERROR (@msg, 10, 1)
	end
	
	
	
-- does this hash code already exist?

	declare @Archive_Entry_ID int
	set @Archive_Entry_ID = 0
	declare @skipOutputTableAdd int

	SELECT @Archive_Entry_ID = Archived_File_ID
		FROM V_Archived_Output_Files
		WHERE (Authentication_Hash = @crc32_authentication)
		
	
	SELECT @myError = @@error, @myRowCount = @@rowcount

	if @myError <> 0
	begin
		set @msg = 'Database retrieval error during hash duplication check'
		RAISERROR (@msg, 10, 1)
		set @message = @msg
		return @myError
	end
	
--	if @myRowCount > 0
--	begin
		
--		set @myError = -51009
--		set @msg = 'SHA-1 Authentication Hash already exists for this collection'
--		RAISERROR (@msg, 10, 1)
--		return @myError
--	end
	
	
	
-- Does this protein collection even exist?
	
	 
	SELECT ID FROM V_Collection_Picker
	 WHERE (ID = @protein_collection_ID)
	 
	
	SELECT @myError = @@error, @myRowCount = @@rowcount

	 
	if @myRowCount = 0
	begin
		set @myError = -51001
		set @msg = 'Collection does not exist'
		RAISERROR (@msg, 10, 1)
		return @myError
	end
	
	
	
-- Is the archive path length valid?

	if LEN(@archived_file_path) < 1
	begin
		set @myError = -51002
		set @msg = 'No archive path specified!'
		RAISERROR (@msg, 10, 1)
		return @myError
	end
	



-- Check for existence of output file type in T_Archived_File_Types

	declare @archived_file_type_ID int

	SELECT @archived_file_type_ID = Archived_File_Type_ID 
		FROM T_Archived_File_Types 
		WHERE File_Type_Name = @archived_file_type

	if @archived_file_type_ID < 1
	begin
		set @myError = -51003
		set @msg = 'archived_file_type does not exist'
		RAISERROR (@msg, 10, 1)
		return @myError
	end


/*-- Check for existence of sequence type in T_Output_Sequence_Types

	declare @output_sequence_type_ID int

	SELECT @output_sequence_type_ID = Output_Sequence_Type_ID 
		FROM T_Output_Sequence_Types 
		WHERE Output_Sequence_Type = @output_sequence_type

	if @output_sequence_type_ID < 1
	begin
		set @myError = -51003
		set @msg = 'output_sequence_type does not exist'
		RAISERROR (@msg, 10, 1)
		return @myError
	end
*/
	
	
-- Does this path already exist?


--	SELECT Archived_File_ID
--		FROM T_Archived_Output_Files
--		WHERE (Archived_File_Path = @archived_file_path)
--		
--	SELECT @myError = @@error, @myRowCount = @@rowcount
--
--	if @myError <> 0
--	begin
--		set @msg = 'Database retrieval error during archive path duplication check'
--		RAISERROR (@msg, 10, 1)
--		set @message = @msg
--		return @myError
--	end
--	
--	if @myRowCount <> 0
--	begin
--		set @myError = -51010
--		set @msg = 'An archived file already exists at this location'
--		RAISERROR (@msg, 10, 1)
--		return @myError
--	end
--	
	  
--	if @myError <> 0
--	begin
--		set @message = @msg
--		return @myError
--	end
	
	
-- Determine the state of the entry based on provided data

	SELECT Archived_File_ID
	FROM T_Archived_Output_File_Collections_XRef
	WHERE Protein_Collection_ID = @protein_collection_ID
	
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	if @myError <> 0
	begin
		set @msg = 'Database retrieval error'
		RAISERROR (@msg, 10, 1)
		set @message = @msg
		return @myError
	end
	
	declare @archived_file_state varchar(64)
	
	if @myRowCount = 0
	begin
		SET @archived_file_state = 'original'
	end
	
	if @myRowCount > 0
	begin
		SET @archived_file_state = 'modified'
	end
	
	declare @archived_file_state_ID int
	
	SELECT @archived_file_state_ID = Archived_File_State_ID
	FROM T_Archived_File_States
	WHERE Archived_File_State = @archived_file_state
	
	
	
	
	
	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'AddOutputFileArchiveEntry'
	begin transaction @transName

	


			

	---------------------------------------------------
	-- Make the initial entry with what we have
	---------------------------------------------------
	
	if @Archive_Entry_ID = 0
	begin
	
/*	INSERT INTO T_Archived_Output_Files (
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
		@archived_file_type_ID,
		@archived_file_state_ID,
		@output_sequence_type_ID,
		@archived_file_path,
		@creation_options,
		@sha1_authentication,
		GETDATE(),
		@file_modification_date,
		@file_size)
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
		@archived_file_type_ID,
		@archived_file_state_ID,
		@archived_file_path,
		@crc32_authentication,
		GETDATE(),
		@file_modification_date,
		@creation_options,
		@file_size,
		@protein_count,
		@protein_collection_string,
		@collection_string_hash)


		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Insert operation failed: Archive File Entry for file with hash = "' + @crc32_authentication + '"'
			RAISERROR (@msg, 10, 1)
			set @message = @msg
			return -51007
		end
		
		
		SELECT @Archive_Entry_ID = @@Identity
		
		set @archived_file_path = REPLACE(@archived_file_path, '00000', RIGHT('000000'+CAST(@Archive_Entry_ID AS VARCHAR),6))
		
		UPDATE T_Archived_Output_Files
		SET Archived_File_Path = @archived_file_path
		WHERE Archived_File_ID = @Archive_Entry_ID
		
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
	
	SET @tmpCommaPosition =  CHARINDEX(',', @creation_options)
	if @tmpCommaPosition = 0
	begin
		SET	@tmpCommaPosition = LEN(@creation_options)
	end
	
		WHILE(@tmpCommaPosition < LEN(@creation_options))
		begin		
			SET @tmpCommaPosition = CHARINDEX(',', @creation_options, @tmpStartPosition)
			if @tmpCommaPosition = 0
			begin
				SET @tmpCommaPosition = LEN(@creation_options) + 1
			end
			SET @tmpEndPosition = @tmpCommaPosition - @tmpStartPosition
			SET @tmpOptionString = LTRIM(SUBSTRING(@creation_options, @tmpStartPosition, @tmpCommaPosition))
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
				return @myError
			end
			
			if @myRowCount = 0
			begin
				SET @msg = 'Keyword: "' + @tmpOptionKeyword + '" not located'
				SET @message = @msg
				return -50011
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
					@Archive_Entry_ID)
					
				end
				
				if @myError <> 0
				begin
					rollback transaction @transName
					set @msg = 'Insert operation failed: Creation Options'
					RAISERROR (@msg, 10, 1)
					set @message = @msg
					return -51007
				end

				
				
			end
			

			SET @tmpStartPosition = @tmpCommaPosition + 1
		end
		
		
		
	
		INSERT INTO T_Archived_Output_File_Collections_XRef (
			Archived_File_ID,
			Protein_Collection_ID
		) VALUES (
			@Archive_Entry_ID,
			@protein_collection_ID)		
	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Insert operation failed: Archive File Member Entry for "' + @protein_collection_ID + '"'
			RAISERROR (@msg, 10, 1)
			set @message = @msg
			return -51011
		end
	end

	
	commit transaction @transName
	
	return @Archive_Entry_ID

GO
GRANT EXECUTE ON [dbo].[AddOutputFileArchiveEntry] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddOutputFileArchiveEntry] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddOutputFileArchiveEntry] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddOutputFileArchiveEntry] TO [svc-dms] AS [dbo]
GO

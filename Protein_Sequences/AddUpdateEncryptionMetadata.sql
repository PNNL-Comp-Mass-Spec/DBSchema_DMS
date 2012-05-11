/****** Object:  StoredProcedure [dbo].[AddUpdateEncryptionMetadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateEncryptionMetadata
/****************************************************
**
**	Desc: Adds encryption metadata for private collections
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 04/14/2006
**
**
**		(-50001) = Protein Collection ID not in T_Protein_Collections
**    
*****************************************************/
	(
		@Protein_Collection_ID int,
		@Encryption_Passphrase varchar(64),
		@Passphrase_SHA1_Hash varchar(40),
		@message varchar(512) output
	)

AS
	SET NOCOUNT ON
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)
	declare @passPhraseID int

	---------------------------------------------------
	-- Does entry already exist?
	---------------------------------------------------
	
	SELECT Protein_Collection_ID
	FROM T_Protein_Collections
	WHERE Protein_Collection_ID = @Protein_Collection_ID

	SELECT @myError = @@error, @myRowCount = @@rowcount

	if @myError > 0
	begin
		set @msg = 'Error during Collection ID existence check'
		RAISERROR(@msg, 10, 1)
		return @myError
	end
	
	if @myRowCount = 0
	begin
		set @msg = 'Error during Collection ID existence check'
		RAISERROR(@msg, 10, 1)
		return -50001
	end
	
	---------------------------------------------------
	-- Start update transaction
	---------------------------------------------------
		
	declare @transName varchar(32)
	set @transName = 'AddUpdateEncryptionMetadata'
	begin transaction @transName
	
	---------------------------------------------------
	-- Update 'Contents_Encrypted' field
	---------------------------------------------------
	
	UPDATE T_Protein_Collections
	SET Contents_Encrypted = 1
	WHERE Protein_Collection_ID = @Protein_Collection_ID
	
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @msg = 'Encryption state update operation failed: "' + @Protein_Collection_ID + '"'
		RAISERROR (@msg, 10, 1)
		return -51007
	end

	---------------------------------------------------
	-- Add Passphrase to T_Encrypted_Collection_Passphrases
	---------------------------------------------------
	
	
	INSERT INTO T_Encrypted_Collection_Passphrases (
		Passphrase,
		Protein_Collection_ID
	) VALUES (
		@Encryption_Passphrase,
		@Protein_Collection_ID
	)
	
	SELECT @passPhraseID = @@Identity

	SELECT @myError = @@error, @myRowCount = @@rowcount

	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @msg = 'Passphrase insert operation failed: "' + @Protein_Collection_ID + '"'
		RAISERROR (@msg, 10, 1)
		return -51007
	end

	---------------------------------------------------
	-- Add Passphrase Hash to T_Passphrase_Hashes
	---------------------------------------------------
	
	
	INSERT INTO T_Passphrase_Hashes (
		Passphrase_SHA1_Hash,
		Protein_Collection_ID,
		Passphrase_ID
	) VALUES (
		@Passphrase_SHA1_Hash,
		@Protein_Collection_ID,
		@passphraseID
	)
	
	SELECT @myError = @@error, @myRowCount = @@rowcount

	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @msg = 'Passphrase hash insert operation failed: "' + @Protein_Collection_ID + '"'
		RAISERROR (@msg, 10, 1)
		return -51007
	end


	commit transaction @transName
	
	RETURN @passPhraseID

GO
GRANT EXECUTE ON [dbo].[AddUpdateEncryptionMetadata] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateEncryptionMetadata] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

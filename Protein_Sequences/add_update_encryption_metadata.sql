/****** Object:  StoredProcedure [dbo].[add_update_encryption_metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_encryption_metadata]
/****************************************************
**
**  Desc: Adds encryption metadata for private collections
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   04/14/2006
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
**
**      (-50001) = Protein Collection ID not in T_Protein_Collections
**
*****************************************************/
(
    @proteinCollectionID int,
    @encryptionPassphrase varchar(64),
    @passphraseSHA1Hash varchar(40),
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
    WHERE Protein_Collection_ID = @ProteinCollectionID

    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myError > 0
    begin
        set @msg = 'Error during Collection ID existence check'
        RAISERROR(@msg, 10, 1)
        Return @myError
    end

    if @myRowCount = 0
    begin
        set @msg = 'Error during Collection ID existence check'
        RAISERROR(@msg, 10, 1)
        Return -50001
    end

    ---------------------------------------------------
    -- Start update transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_update_encryption_metadata'
    begin transaction @transName

    ---------------------------------------------------
    -- Update 'Contents_Encrypted' field
    ---------------------------------------------------

    UPDATE T_Protein_Collections
    SET Contents_Encrypted = 1
    WHERE Protein_Collection_ID = @ProteinCollectionID

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Encryption state update operation failed: "' + @ProteinCollectionID + '"'
        RAISERROR (@msg, 10, 1)
        Return -51007
    end

    ---------------------------------------------------
    -- Add Passphrase to T_Encrypted_Collection_Passphrases
    ---------------------------------------------------


    INSERT INTO T_Encrypted_Collection_Passphrases (
        Passphrase,
        Protein_Collection_ID
    ) VALUES (
        @EncryptionPassphrase,
        @ProteinCollectionID
    )

    SELECT @passPhraseID = @@Identity

    SELECT @myError = @@error, @myRowCount = @@rowcount

    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Passphrase insert operation failed: "' + @ProteinCollectionID + '"'
        RAISERROR (@msg, 10, 1)
        Return -51007
    end

    ---------------------------------------------------
    -- Add Passphrase Hash to T_Passphrase_Hashes
    ---------------------------------------------------


    INSERT INTO T_Passphrase_Hashes (
        Passphrase_SHA1_Hash,
        Protein_Collection_ID,
        Passphrase_ID
    ) VALUES (
        @PassphraseSHA1Hash,
        @ProteinCollectionID,
        @passphraseID
    )

    SELECT @myError = @@error, @myRowCount = @@rowcount

    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Passphrase hash insert operation failed: "' + @ProteinCollectionID + '"'
        RAISERROR (@msg, 10, 1)
        Return -51007
    end


    commit transaction @transName

    Return @passPhraseID

GO
GRANT EXECUTE ON [dbo].[add_update_encryption_metadata] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[add_sha1_file_authentication] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_sha1_file_authentication]
/****************************************************
**
**  Desc: Adds a SHA1 fingerprint to a given Protein Collection Entry
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   04/15/2005
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @collectionID int,
    @crc32FileHash varchar(8),
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
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_crc32_file_authentication'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE T_Protein_Collections
    SET
        Authentication_Hash = @CRC32FileHash,
        DateModified = GETDATE()

    WHERE (Protein_Collection_ID = @CollectionID)


        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @msg = 'Update operation failed!'
            RAISERROR (@msg, 10, 1)
            return 51007
        end
    end

    commit transaction @transName

    return 0

GO
GRANT EXECUTE ON [dbo].[add_sha1_file_authentication] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

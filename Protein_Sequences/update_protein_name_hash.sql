/****** Object:  StoredProcedure [dbo].[update_protein_name_hash] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_protein_name_hash]
/****************************************************
**
**  Desc: Updates the SHA1 fingerprint for a given Protein Reference Entry
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**
**
**  Auth:   kja
**  Date:   03/13/2006
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @reference_ID int,
    @sha1Hash varchar(40),
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
    set @transName = 'update_protein_name_hash'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE T_Protein_Names
    SET
        Reference_Fingerprint = @sha1Hash
    WHERE (Reference_ID = @Reference_ID)


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
GRANT EXECUTE ON [dbo].[update_protein_name_hash] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

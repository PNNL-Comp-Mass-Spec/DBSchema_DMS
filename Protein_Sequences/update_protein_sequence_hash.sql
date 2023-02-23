/****** Object:  StoredProcedure [dbo].[UpdateProteinSequenceHash] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateProteinSequenceHash]
/****************************************************
**
**  Desc: Updates the SHA1 fingerprint for a given Protein Sequence Entry
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**
**
**  Auth:   kja
**  Date:   03/13/2006
**
*****************************************************/
(
    @Protein_ID int,
    @SHA1Hash varchar(40),
    @SEGUID varchar(27),
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
    set @transName = 'UpdateProteinSequenceHash'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE T_Proteins
    SET
        SHA1_Hash = @SHA1Hash,
        SEGUID = @SEGUID
    WHERE (Protein_ID = @Protein_ID)


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
GRANT EXECUTE ON [dbo].[UpdateProteinSequenceHash] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

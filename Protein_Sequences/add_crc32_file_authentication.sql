/****** Object:  StoredProcedure [dbo].[add_crc32_file_authentication] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_crc32_file_authentication]
/****************************************************
**
**  Desc: Adds a CRC32 fingerprint to a given Protein Collection Entry
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   04/15/2005
**          07/20/2015 mem - Added parameters @numProteins and @totalResidueCount
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @collectionID int,
    @crc32FileHash varchar(8),
    @message varchar(512) output,
    @numProteins int = 0,           -- The number of proteins for this protein collection; used to update T_Protein_Collections
    @totalResidueCount int = 0      -- The number of residues for this protein collection; used to update T_Protein_Collections
                                    -- If @numProteins is 0 or @totalResidueCount is 0 then T_Protein_Collections will not be updated
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''
    Set @numProteins = IsNull(@numProteins, 0)
    Set @totalResidueCount = IsNull(@totalResidueCount, 0)

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_crc32_file_authentication'
    begin transaction @transName


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

    If @numProteins > 0 And @totalResidueCount > 0
    Begin
        UPDATE T_Protein_Collections
        SET NumProteins = @numProteins,
            NumResidues = @totalResidueCount
        WHERE Protein_Collection_ID = @CollectionID
    End

    commit transaction @transName

    return 0

GO
GRANT EXECUTE ON [dbo].[add_crc32_file_authentication] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

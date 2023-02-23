/****** Object:  StoredProcedure [dbo].[update_file_archive_entry_collection_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_file_archive_entry_collection_list]
/****************************************************
**
**  Desc: Updates the SHA1 fingerprint for a given Protein Description Entry
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**
**
**  Auth:   kja
**  Date:   02/21/2007
**          02/11/2009 mem - Added parameter @CollectionListHexHash
**                         - Now storing @Sha1Hash in Authentication_Hash instead of in Collection_List_Hash
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @archived_File_Entry_ID int,
    @proteinCollectionList varchar(8000),
    @sha1Hash varchar(40),
    @message varchar(512) output,
    @collectionListHexHash varchar(128)
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
    set @transName = 'update_file_archive_entry_collection_list'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE T_Archived_Output_Files
    SET
        Protein_Collection_List = @ProteinCollectionList,
        Authentication_Hash =   @SHA1Hash,
        Collection_List_Hex_Hash  = @CollectionListHexHash
    WHERE (Archived_File_ID = @Archived_File_Entry_ID)


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
GRANT EXECUTE ON [dbo].[update_file_archive_entry_collection_list] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_file_archive_entry_collection_list] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_file_archive_entry_collection_list] TO [svc-dms] AS [dbo]
GO

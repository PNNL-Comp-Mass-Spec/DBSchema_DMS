/****** Object:  StoredProcedure [dbo].[update_file_archive_entry_collection_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_file_archive_entry_collection_list]
/****************************************************
**
**  Desc:
**      Updates the protein collection list and hash values in T_Archived_Output_Files for the given archived output file
**
**  Arguments:
**    @archivedFileEntryID      Archive output file ID
**    @proteinCollectionList    Protein collection list (comma-separated list of protein collection names)
**    @crc32Authentication      CRC32 authentication hash (hash of the bytes in the file)
**    @collectionListHexHash    SHA-1 hash of the protein collection list and creation options (separated by a forward slash)
**                              For example, 'H_sapiens_UniProt_SPROT_2023-03-01,Tryp_Pig_Bov/seq_direction=forward,filetype=fasta' has SHA-1 hash '11822db6bbfc1cb23c0a728a0b53c3b9d97db1f5'
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   02/21/2007
**          02/11/2009 mem - Added parameter @CollectionListHexHash
**                         - Now storing @crc32Authentication in Authentication_Hash instead of in Collection_List_Hash
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**          08/22/2023 mem - Rename argument @sha1Hash to @crc32Authentication
**
*****************************************************/
(
    @archivedFileEntryID int,
    @proteinCollectionList varchar(8000),
    @crc32Authentication varchar(40),
    @collectionListHexHash varchar(128),
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(256)

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'update_file_archive_entry_collection_list'

    Begin Transaction @transName

    Begin

        UPDATE T_Archived_Output_Files
        SET Protein_Collection_List = @ProteinCollectionList,
            Authentication_Hash =   @crc32Authentication,
            Collection_List_Hex_Hash  = @CollectionListHexHash
        WHERE Archived_File_ID = @ArchivedFileEntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @msg = 'Update operation failed!'
            RAISERROR (@msg, 10, 1)
            RETURN 51007
        End
    End

    Commit Transaction @transName

    RETURN 0

GO
GRANT EXECUTE ON [dbo].[update_file_archive_entry_collection_list] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_file_archive_entry_collection_list] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_file_archive_entry_collection_list] TO [svc-dms] AS [dbo]
GO

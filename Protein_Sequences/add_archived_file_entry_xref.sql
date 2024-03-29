/****** Object:  StoredProcedure [dbo].[add_archived_file_entry_xref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_archived_file_entry_xref]
/****************************************************
**
**  Desc: Adds an Archived File Entry to T_Archived_Output_File_Collections_XRef
**        For a given Protein Collection ID
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   03/17/2006 - kja
**          03/12/2014 - Now validating @CollectionID and @ArchivedFileID
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @collectionID int,
    @archivedFileID int,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    Set @message = ''

    -------------------------------------------------
    -- Verify the File ID and Collection ID
    ---------------------------------------------------

    If Not Exists (SELECT * FROM T_Protein_Collections WHERE Protein_Collection_ID = @CollectionID)
    Begin
        Set @message = 'Protein_Collection_ID ' + Convert(varchar(12), @CollectionID) + ' not found in T_Protein_Collections'
        Return 51000
    End

    If Not Exists (SELECT * FROM T_Archived_Output_Files WHERE Archived_File_ID = @ArchivedFileID)
    Begin
        Set @message = 'Archived_File_ID ' + Convert(varchar(12), @ArchivedFileID) + ' not found in T_Archived_Output_Files'
        Return 51001
    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_archived_file_entry_xref'
    begin transaction @transName

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT *
    FROM T_Archived_Output_File_Collections_XRef
    WHERE
        (Archived_File_ID = @ArchivedFileID AND
         Protein_Collection_ID = @CollectionID)

    SELECT @myError = @@error, @myRowCount = @@rowcount


    -------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @myRowCount = 0
    begin

        INSERT INTO T_Archived_Output_File_Collections_XRef (Archived_File_ID, Protein_Collection_ID)
        VALUES (@ArchivedFileID, @CollectionID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Insert operation failed!'
            RAISERROR (@message, 10, 1)
            return 51007
        end
    end

    commit transaction @transName

    return 0

GO
GRANT EXECUTE ON [dbo].[add_archived_file_entry_xref] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_archived_file_entry_xref] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_archived_file_entry_xref] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_archived_file_entry_xref] TO [svc-dms] AS [dbo]
GO

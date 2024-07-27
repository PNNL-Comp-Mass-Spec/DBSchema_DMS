/****** Object:  StoredProcedure [dbo].[delete_protein_collection_members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_protein_collection_members]
/****************************************************
**
**  Desc:    Deletes Protein Collection Member Entries from a given Protein Collection ID
**            Called by the Organism Database Handler when replacing the proteins for an existing protein collection
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   10/07/2004 kja - Initial version
**          07/20/2015 mem - Now setting NumProteins and TotalResidues to 0 in T_Protein_Collections
**          09/14/2015 mem - Added parameter @numProteinsForReload
**          07/27/2022 mem - Switch from FileName to Collection_Name
**                         - Rename argument to @collectionID
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/26/2024 mem - Allow protein collections with state Offline or Proteins_Deleted to have their protein collection member entries deleted (since they already should be deleted)
**
*****************************************************/
(
    @collectionID int,
    @message varchar(512) output,
    @numProteinsForReload int = 0        -- Number of proteins that will be associated with this collection after they are added to the database following this delete
)
AS
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @numProteinsForReload = IsNull(@numProteinsForReload, 0)
    Set @message = ''

    Declare @msg varchar(256)
    Declare @result int

    ---------------------------------------------------
    -- Check if collection is OK to delete
    ---------------------------------------------------

    If Not Exists (SELECT * FROM T_Protein_Collections WHERE Protein_Collection_ID = @collectionID)
    Begin
        Set @msg = 'Protein collection ID not found: ' + Cast(@collectionID as varchar(12))
        RAISERROR (@msg, 10, 1)
        return 51140
    End

    Declare @collectionState int

    SELECT @collectionState = Collection_State_ID
    FROM T_Protein_Collections
    WHERE Protein_Collection_ID = @collectionID

    Declare @collectionName varchar(128)
    Declare @stateName varchar(64)

    SELECT @collectionName = Collection_Name
    FROM T_Protein_Collections
    WHERE Protein_Collection_ID = @collectionID

    SELECT @stateName = State
    FROM T_Protein_Collection_States
    WHERE Collection_State_ID = @collectionState

    -- Protein collections with state Unknown, New, Provisional, Offline, or Proteins_Deleted can be updated
    -- Protein collections with state Production or Retired cannot be deleted
    If @collectionState IN (3, 4)
    Begin
        Set @msg = 'Cannot delete collection "' + @collectionName + '": ' + @stateName + ' collections are protected'
        RAISERROR (@msg,10, 1)

        return 51140
    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'delete_protein_collection_members'

    Begin transaction @transName

    ---------------------------------------------------
    -- delete the proteins for this protein collection
    ---------------------------------------------------

    DELETE FROM T_Protein_Collection_Members
    WHERE Protein_Collection_ID = @collectionID

    If @@error <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Delete from entries table was unsuccessful for collection',
            10, 1)
        return 51130
    End

    UPDATE T_Protein_Collections
    SET NumProteins = @numProteinsForReload,
        NumResidues = 0
    WHERE Protein_Collection_ID = @collectionID

    commit transaction @transname

    return 0

GO
GRANT EXECUTE ON [dbo].[delete_protein_collection_members] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

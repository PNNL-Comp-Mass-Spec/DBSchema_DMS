/****** Object:  StoredProcedure [dbo].[DeleteProteinCollection] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteProteinCollection]
/****************************************************
**
**  Desc: Deletes the given Protein Collection (use with caution)
**            Collection_State_ID must be 1 or 2
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/24/2008
**          02/23/2016 mem - Add Set XACT_ABORT on
**          06/20/2018 mem - Delete entries in T_Protein_Collection_Members_Cached
**                         - Add RAISERROR calls with severity level 11 (forcing the Catch block to be entered)
**    
*****************************************************/
(
    @Collection_ID int,
    @message varchar(512)='' output
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Set @message = ''
    
    Declare @msg varchar(256)

    Declare @Collection_Name varchar(128)
    Declare @State_Name varchar(64)
    
    Declare @ArchivedFileID int

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Declare @logErrors tinyint = 0

    Begin Try
        
        Set @CurrentLocation = 'Examine @collectionState in T_Protein_Collections'    
    
        ---------------------------------------------------
        -- Check if collection is OK to delete
        ---------------------------------------------------
        
        Declare @collectionState int
        
        SELECT @collectionState = Collection_State_ID
        FROM T_Protein_Collections
        WHERE Protein_Collection_ID = @Collection_ID
        --
        SELECT @myError = @@Error, @myRowCount = @@RowCount

        If @myRowCount = 0
        Begin
            Set @message = 'Collection_ID ' + Convert(varchar(12), @Collection_ID) + ' not found in T_Protein_Collections; unable to continue'
            Print @message
            Goto Done
        End
            
        SELECT @Collection_Name = FileName
        FROM T_Protein_Collections
        WHERE (Protein_Collection_ID = @Collection_ID)
        
        SELECT @State_Name = State
        FROM T_Protein_Collection_States
        WHERE (Collection_State_ID = @collectionState)                    

        If @collectionState > 2    
        Begin
            Set @msg = 'Cannot Delete collection "' + @Collection_Name + '": ' + @State_Name + ' collections are protected'
            RAISERROR (@msg, 10, 1)
                
            return 51140
        End
        
        Set @logErrors = 1
        ---------------------------------------------------
        -- Start transaction
        ---------------------------------------------------

        Declare @transName varchar(32)
        Set @transName = 'DeleteProteinCollection'
        Begin transaction @transName

        ---------------------------------------------------
        -- Delete the collection members
        ---------------------------------------------------

        exec @myError = DeleteProteinCollectionMembers @Collection_ID, @message = @message output

        If @myError <> 0
        Begin
            rollback transaction @transName
            RAISERROR ('Protein collection members deletion was unsuccessful', 10, 1)
            return 51130
        End
        
        -- Look for this collection's Archived_File_ID in T_Archived_Output_File_Collections_XRef
        Set @ArchivedFileID = -1
        SELECT TOP 1 @ArchivedFileID = Archived_File_ID
        FROM T_Archived_Output_File_Collections_XRef
        WHERE Protein_Collection_ID = @Collection_ID
        --
        SELECT @myError = @@Error, @myRowCount = @@RowCount

        -- Delete the entry from T_Archived_Output_File_Collections_XRef
        DELETE FROM T_Archived_Output_File_Collections_XRef
        WHERE Protein_Collection_ID = @Collection_ID 
        --
        SELECT @myError = @@Error, @myRowCount = @@RowCount

        If @myError <> 0
            RAISERROR ('Error deleting rows from T_Archived_Output_File_Collections_XRef', 11, 1)

        -- Delete the entry from T_Archived_Output_Files if not used in T_Archived_Output_File_Collections_XRef
        If Not Exists (SELECT * FROM T_Archived_Output_File_Collections_XRef where Archived_File_ID = @ArchivedFileID)
        Begin
            DELETE FROM T_Archived_Output_Files
            WHERE (Archived_File_ID = @ArchivedFileID)
            --
            SELECT @myError = @@Error, @myRowCount = @@RowCount

            If @myError <> 0
                RAISERROR ('Error deleting rows from T_Archived_Output_Files', 11, 1)
        End

        -- Delete the entry from T_Annotation_Groups
        DELETE FROM T_Annotation_Groups
        WHERE (Protein_Collection_ID = @Collection_ID)
        --
        SELECT @myError = @@Error, @myRowCount = @@RowCount

        If @myError <> 0
            RAISERROR ('Error deleting rows from T_Annotation_Groups', 11, 1)

        DELETE FROM T_Protein_Collection_Members_Cached
        WHERE (Protein_Collection_ID = @Collection_ID)
        --
        SELECT @myError = @@Error, @myRowCount = @@RowCount

        If @myError <> 0
            RAISERROR ('Error deleting rows from T_Protein_Collection_Members_Cached', 11, 1)

        -- Delete the entry from T_Protein_Collections
        DELETE FROM T_Protein_Collections
        WHERE Protein_Collection_ID = @Collection_ID
        --
        SELECT @myError = @@Error, @myRowCount = @@RowCount

        If @myError <> 0
            RAISERROR ('Error deleting rows from T_Protein_Collections', 11, 1)
        
        commit transaction @transname

    End Try
    Begin Catch
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Protein Collection ' + Cast(@Collection_ID As varchar(12))
            exec PostLogEntry 'Error', @logMessage, 'DeleteProteinCollection'
        End 

        Print @message
        If @myError <> 0
            Set @myError = 50000

    End Catch

Done:    
    return @myError


GO

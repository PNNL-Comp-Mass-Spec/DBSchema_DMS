/****** Object:  StoredProcedure [dbo].[DeleteProteinCollection] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE DeleteProteinCollection
/****************************************************
**
**	Desc: Deletes the given Protein Collection (use with caution)
**			Collection_State_ID must be 1 or 2
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	06/24/2008
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@Collection_ID int,
	@message varchar(512)='' output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	declare @Collection_Name varchar(128)
	declare @State_Name varchar(64)
	
	Declare @ArchivedFileID int

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try
		
		Set @CurrentLocation = 'Examine @collectionState in T_Protein_Collections'	
	
		---------------------------------------------------
		-- Check if collection is OK to delete
		---------------------------------------------------
		
		declare @collectionState int
		
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

		if @collectionState > 2	
		begin
			set @msg = 'Cannot Delete collection "' + @Collection_Name + '": ' + @State_Name + ' collections are protected'
			RAISERROR (@msg,10, 1)
				
			return 51140
		end
		
		---------------------------------------------------
		-- Start transaction
		---------------------------------------------------

		declare @transName varchar(32)
		set @transName = 'DeleteProteinCollection'
		begin transaction @transName

		---------------------------------------------------
		-- Delete the collection members
		---------------------------------------------------

		exec @myError = DeleteProteinCollectionMembers @Collection_ID, @message = @message output

		if @myError <> 0
		begin
			rollback transaction @transName
			RAISERROR ('Protein collection deletion was unsuccessful', 10, 1)
			return 51130
		end
		
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

		-- Delete the entry from T_Archived_Output_Files if not used in T_Archived_Output_File_Collections_XRef
		If Not Exists (SELECT * FROM T_Archived_Output_File_Collections_XRef where Archived_File_ID = @ArchivedFileID)
			DELETE FROM T_Archived_Output_Files
			WHERE (Archived_File_ID = @ArchivedFileID)

		-- Delete the entry from T_Annotation_Groups
		DELETE FROM T_Annotation_Groups
		WHERE (Protein_Collection_ID = @Collection_ID)

		-- Delete the entry from T_Protein_Collections
		DELETE FROM T_Protein_Collections
		WHERE Protein_Collection_ID = @Collection_ID
		
		commit transaction @transname

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'DeleteProteinCollection')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output

		if @@TranCount > 0
		Begin
			rollback transaction @transName
			RAISERROR ('Protein collection deletion was unsuccessful', 10, 1)
		End
		
		Goto Done
	End Catch

Done:	
	return @myError


GO

/****** Object:  StoredProcedure [dbo].[DeleteDataPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DeleteDataPackage
/****************************************************
**
**	Desc:	Deletes the data package, including deleting rows
**			in the associated tracking tables:
**				T_Data_Package_Analysis_Jobs
**				T_Data_Package_Datasets
**				T_Data_Package_Experiments
**				T_Data_Package_Biomaterial
**				T_Data_Package_EUS_Proposals
**
**			Use with caution!
**
**	Auth:	mem
**	Date:	04/08/2016 mem - Initial release
**			05/18/2016 mem - Log errors to T_Log_Entries
**
*****************************************************/
(
	@packageID INT,
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 1)

	BEGIN TRY 

		If Not Exists (SELECT * FROM T_Data_Package WHERE ID = @packageID)
		Begin
			Set @message = 'Data package ' + Cast(@packageID as varchar(9)) + ' not found in T_Data_Package'
			If @infoOnly <> 0
				Select @message AS Warning
			Else			
				Print @message
		End
		Else
		Begin
			If @infoOnly <> 0
			Begin
				---------------------------------------------------
				-- Preview the data package to be deleted
				---------------------------------------------------
				--
				SELECT [ID],
				       [Name],
				       [Package Type],
				       [Biomaterial Item Count],
				       [Experiment Item Count],
				       [EUS Proposals Count],
				       [Dataset Item Count],
				       [Analysis Job Item Count],
				       [Campaign Count],
				       [Total Item Count],
				       State,
				       [Share Path],
				       Description,
				       [Comment],
				       Owner,
				       Requester,
				       Created,
				       [Last Modified]
				FROM V_Data_Package_Detail_Report
				WHERE ID = @packageID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
			End
			Else
			Begin
				---------------------------------------------------
				-- Lookup the share path on Protoapps
				---------------------------------------------------
				--
				Declare @sharePath varchar(1024) = ''
			
				SELECT @sharePath = Share_Path
				FROM V_Data_Package_Paths
				WHERE ID = @packageID
				
				---------------------------------------------------
				-- Delete the associated items
				---------------------------------------------------
				--
				exec DeleteAllItemsFromDataPackage @packageID=@packageID, @mode='delete', @message=@message output
				
				If @message <> ''
				Begin
					Print @message
					Set @message = ''
				End
				
				DELETE FROM T_Data_Package
				WHERE ID = @packageID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myRowCount = 0
					Set @message = 'No rows were deleted from T_Data_Package for data package ' + Cast(@packageID as varchar(9)) + '; this is unexpected'					
				Else
					set @message = 'Deleted data package ' + Cast(@packageID as varchar(9)) + ' and all associated metadata'	
					
					
				---------------------------------------------------
				-- Display some messages
				---------------------------------------------------
				--

				Print @message
				Print ''
				Print 'Be sure to delete folder ' + @sharePath
				
			End
		End
		

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		Declare @msgForLog varchar(512) = ERROR_MESSAGE()
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		Exec PostLogEntry 'Error', @msgForLog, 'DeleteDataPackage'
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[DeleteDataPackage] TO [DDL_Viewer] AS [dbo]
GO

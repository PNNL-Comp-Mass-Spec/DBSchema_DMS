/****** Object:  StoredProcedure [dbo].[DeleteAllItemsFromDataPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DeleteAllItemsFromDataPackage
/****************************************************
**
**	Desc:
**  removes all existing items from data package
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	06/10/2009 grk - initial release
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/05/2016 mem - Add T_Data_Package_EUS_Proposals
**			05/18/2016 mem - Log errors to T_Log_Entries
**
*****************************************************/
(
	@packageID INT,
	@mode varchar(12) = 'delete',
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 

		---------------------------------------------------
		declare @transName varchar(32)
		set @transName = 'DeleteAllItemsFromDataPackage'
		begin transaction @transName

		DELETE FROM T_Data_Package_Analysis_Jobs
		WHERE Data_Package_ID  = @packageID
		
		DELETE FROM T_Data_Package_Datasets
		WHERE Data_Package_ID  = @packageID

		DELETE FROM T_Data_Package_Experiments
		WHERE Data_Package_ID  = @packageID
		
		DELETE FROM T_Data_Package_Biomaterial 
		WHERE Data_Package_ID = @packageID

		DELETE FROM T_Data_Package_EUS_Proposals 
		WHERE Data_Package_ID = @packageID

		---------------------------------------------------
		commit transaction @transName

 		---------------------------------------------------
		-- update item counts
		---------------------------------------------------

		exec UpdateDataPackageItemCounts @packageID, @message output, @callingUser

		UPDATE T_Data_Package
		SET Last_Modified = GETDATE()
		WHERE ID = @packageID

 	---------------------------------------------------
 	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		Declare @msgForLog varchar(512) = ERROR_MESSAGE()
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		Exec PostLogEntry 'Error', @msgForLog, 'DeleteAllItemsFromDataPackage'
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError


GO
GRANT EXECUTE ON [dbo].[DeleteAllItemsFromDataPackage] TO [DMS_SP_User] AS [dbo]
GO

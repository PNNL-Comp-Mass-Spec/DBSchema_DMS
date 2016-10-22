/****** Object:  StoredProcedure [dbo].[UpdateDataPackageItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateDataPackageItems
/****************************************************
**
**	Desc:
**      Updates data package items in list according to command mode
**		This procedure is used by web page "DMS Data Package Detail Report" (data_package/show)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	05/21/2009
**          06/10/2009 grk - changed size of item list to max
**          05/23/2010 grk - factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          03/07/2012 grk - changed data type of @itemList from varchar(max) to text
**			12/31/2013 mem - Added support for EUS Proposals
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/07/2016 mem - Switch to udfParseDelimitedList
**			05/18/2016 mem - Add parameter @infoOnly
**			10/19/2016 mem - Update #TPI to use an integer field for data package ID
**
*****************************************************/
(
	@packageID int,						-- Data package ID
	@itemType varchar(128),				-- analysis_jobs, datasets, experiments, biomaterial, or proposals
	@itemList text,						-- Comma separated list of items
	@comment varchar(512),
	@mode varchar(12) = 'update',		-- 'add', 'update', 'comment', 'delete'
	@message varchar(512) = '' output,
	@callingUser varchar(128) = '',
	@infoOnly tinyint = 0
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	declare @wasModified tinyint
	set @wasModified = 0


	BEGIN TRY 
		---------------------------------------------------
		DECLARE @entityName VARCHAR(32)
		SELECT @entityName = 
			CASE 
				WHEN @itemType IN ('analysis_jobs', 'job', 'jobs')	THEN 'Job'
				WHEN @itemType IN ('datasets', 'dataset')			THEN 'Dataset'
				WHEN @itemType IN ('experiments', 'experiment')		THEN 'Experiment'
				WHEN @itemType = 'biomaterial'						THEN 'Biomaterial'
				WHEN @itemType = 'proposals'						THEN 'EUSProposal'
			ELSE ''
			END 
		--
		IF IsNull(@entityName, '') = ''
			RAISERROR('Item type "%s" is unrecognized', 11, 14, @itemType)		
		
		Declare @logUsage tinyint = 0
		
		If @logUsage > 0
		Begin
			Declare @usageMessage varchar(255) = 'Updating ' + @entityName + 's for data package ' + Cast(@packageID as varchar(12))
			Exec PostLogEntry 'Debug', @usageMessage, 'UpdateDataPackageItems'
		End

		---------------------------------------------------
		-- Create and populate a temporary table using the XML in @paramListXML
		---------------------------------------------------
		--
		CREATE TABLE #TPI(
			DataPackageID int not null,				-- Data package ID
			Type varchar(50) null,					-- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
			Identifier varchar(256) null			-- Job ID, Dataset ID, Experiment Id, Cell_Culture ID, or EUSProposal ID
		)
		INSERT INTO #TPI(DataPackageID, Type, Identifier) 
		SELECT @packageID, @entityName, Value
		FROM dbo.udfParseDelimitedList(@itemList, ',')
		
		---------------------------------------------------
		-- Apply the changes
		---------------------------------------------------
		--
		exec @myError = UpdateDataPackageItemsUtility
									@comment,
									@mode,
									@message output,
									@callingUser,
									@infoOnly = @infoOnly
		if @myError <> 0
			RAISERROR(@message, 11, 14)
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		Declare @msgForLog varchar(512) = ERROR_MESSAGE()
		
		-- Rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		Exec PostLogEntry 'Error', @msgForLog, 'UpdateDataPackageItems'
		
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateDataPackageItems] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItems] TO [PNL\D3M578] AS [dbo]
GO

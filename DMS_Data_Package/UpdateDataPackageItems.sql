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
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**    Auth: grk
**    Date: 05/21/2009
**          06/10/2009 grk - changed size of item list to max
**          05/23/2010 grk - factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          03/07/2012 grk - changed data type of @itemList from varchar(max) to text
**			12/31/2013 mem - Added support for EUS Proposals
**
*****************************************************/
(
	@packageID int,
	@itemType varchar(128),
	@itemList text,
	@comment varchar(512),
	@mode varchar(12) = 'update',
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	declare @wasModified tinyint
	set @wasModified = 0

	---------------------------------------------------
	-- Test mode for debugging
	---------------------------------------------------
	if @mode = 'Test'
	begin
		set @message = 'Test Mode'
		return 1
	end

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 
		---------------------------------------------------
		DECLARE @typ VARCHAR(32)
		select @typ = CASE WHEN @itemType = 'analysis_jobs' THEN 'Job'
					 WHEN @itemType = 'datasets' THEN 'Dataset'
					 WHEN @itemType = 'experiments' THEN 'Experiment'
					 WHEN @itemType = 'biomaterial' THEN 'Biomaterial'
					 WHEN @itemType = 'proposals' THEN 'EUSProposal'
					 ELSE ''
				END 
		--
		IF @typ = ''
			RAISERROR('Item type "%s" unrecognized', 11, 14, @itemType)		
		
		---------------------------------------------------
		CREATE TABLE #TPI(
			Package varchar(50) null,
			Type varchar(50) null,
			Identifier varchar(256) null
		)
		INSERT INTO #TPI(Identifier, Type, Package) 
		SELECT Item, @typ, @packageID FROM MakeTableFromText(@itemList)
		
		---------------------------------------------------
		exec @myError = UpdateDataPackageItemsUtility
									@comment,
									@mode,
									@message output,
									@callingUser
		if @myError <> 0
			RAISERROR(@message, 11, 14)
		
 	---------------------------------------------------
 	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
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
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItems] TO [PNL\D3M580] AS [dbo]
GO

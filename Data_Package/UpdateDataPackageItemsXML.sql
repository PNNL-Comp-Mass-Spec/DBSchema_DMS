/****** Object:  StoredProcedure [dbo].[UpdateDataPackageItemsXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDataPackageItemsXML
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
**          06/10/2009 grk - initial release
**          05/23/2010 grk - factored out grunt work into new sproc UpdateDataPackageItemsUtility
**
*****************************************************/
(
	@paramListXML varchar(max),
	@comment varchar(512),
	@mode varchar(12) = 'update',
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	declare @itemCountChanged int
	set @itemCountChanged = 0

	declare @wasModified int
	set @wasModified = 0

	-- these are necessary to avoid XML throwing errors
	-- when this stored procedure is called from web page
	--
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_NULLS ON
	SET ANSI_PADDING ON
	SET ANSI_WARNINGS ON

	---------------------------------------------------
	-- Test mode for debugging
	---------------------------------------------------
	if @mode = 'test'
	begin
		declare @s varchar(8000)
		set @s = 'Test Monkey:'
		select @s = @s + ', ' + Identifier from #TPI

		set @message = @s
		return 1
	end

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 
		---------------------------------------------------
		CREATE TABLE #TPI(
			Package varchar(50) null,
			Type varchar(50) null,
			Identifier varchar(256) null
		)

		declare @xml xml
		set @xml = @paramListXML

		INSERT INTO #TPI (Package, Type, Identifier)
		SELECT 
			xmlNode.value('@pkg', 'varchar(50)') [Package],
			xmlNode.value('@type', 'varchar(50)') [Type],
			xmlNode.value('@id', 'varchar(256)') [Identifier]
		FROM   @xml.nodes('//item') AS R(xmlNode)

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
GRANT EXECUTE ON [dbo].[UpdateDataPackageItemsXML] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItemsXML] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItemsXML] TO [PNL\D3M580] AS [dbo]
GO

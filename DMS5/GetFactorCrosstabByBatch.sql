/****** Object:  StoredProcedure [dbo].[GetFactorCrosstabByBatch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetFactorCrosstabByBatch
/****************************************************
**
**	Desc: 
**		Returns the factors associated with the
**		run requests in the specified batch
**
**	Auth:	mem
**	Date:	02/18/2010
**			02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**			03/02/2010 grk - added status field to requested run
**			03/17/2010 grk - added filtering for request name contains
**			03/18/2010 grk - eliminated call to GetFactorCrosstabByFactorID
**			02/17/2012 mem - Updated to delete data from #REQS only if @NameContains is not blank
**    
*****************************************************/
(
	@BatchID int,
	@NameContains VARCHAR(48) = '',
	@infoOnly tinyint = 0,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	Declare @msg varchar(256)
	
	Declare @Sql varchar(max)
	Declare @CrossTabSql varchar(max)
	Declare @FactorNameList varchar(max)

	-----------------------------------------
	-- temp tables to hold list of requests
	-- and factors
	-----------------------------------------
	--
	CREATE TABLE #REQS (
		Request int
	)
	--
	CREATE Table #FACTORS (
		FactorID INT,
		FactorName VARCHAR(128) NULL 
	)

	If IsNull(@BatchID, 0) > 0
	Begin
		-----------------------------------------
		-- Populate #REQS with the requests that correspond to batch @BatchID
		-----------------------------------------
		--
		DECLARE @itemList VARCHAR(48)
		SET @itemList = CONVERT(varchar(12), @BatchID)
		EXEC @myError = GetRequestedRunsFromItemList
								@itemList,
								'Batch_ID',
								@message OUTPUT
		--
		IF @myError <> 0
			RETURN @myError
	End
	
	If IsNull(@NameContains, '') <> ''
	Begin
		-----------------------------------------
		-- filter by request name
		-----------------------------------------
		-- 
		DELETE FROM
			#REQS
		WHERE
			NOT EXISTS (
				SELECT ID
				FROM T_Requested_Run
				WHERE
					ID = Request AND
					RDS_Name LIKE '%' + @NameContains + '%'
			)
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	End
	
	-----------------------------------------
	-- Build the Sql for obtaining the factors 
	-- for the requests
	-----------------------------------------
	--
	DECLARE @colList VARCHAR(256)
	SET @colList = ' ''x'' as Sel, BatchID, Name, Status, Dataset_ID, Request, Block, [Run Order]'
	--
	DECLARE @FactorNameContains VARCHAR(48)
	SET @FactorNameContains = ''
	--
	EXEC @myError = MakeFactorCrosstabSQL
						@colList,
						@FactorNameContains,
						@Sql OUTPUT,
						@message OUTPUT
	--
	IF @myError <> 0
		RETURN @myError
	
	-----------------------------------------
	-- run dynamic SQL, or dump it
	-----------------------------------------
	--
	If @infoOnly <> 0
		Print @Sql
	Else
		Exec (@Sql)
	
	--
	return @myError

GO
GRANT EXECUTE ON [dbo].[GetFactorCrosstabByBatch] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetFactorCrosstabByBatch] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetFactorCrosstabByBatch] TO [PNL\D3M578] AS [dbo]
GO

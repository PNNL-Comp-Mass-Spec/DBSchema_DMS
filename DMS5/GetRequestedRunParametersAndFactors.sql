/****** Object:  StoredProcedure [dbo].[GetRequestedRunParametersAndFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetRequestedRunParametersAndFactors]
/****************************************************
**
**  Desc: 
**  Returns the run parameters and factors associated with the
**  run requests in the input list
**
**  Auth: grk 
**  Date: 03/28/2013
**        03/28/2013 grk - cloned from GetFactorCrosstabByBatch
**    
*****************************************************/
(
	@itemList TEXT,
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

	-----------------------------------------
	-- populate temp table from request list
	-----------------------------------------
	--
	INSERT INTO #REQS (Request)
	SELECT Item 
	FROM dbo.MakeTableFromList(@itemList)

/*
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
*/	

	-----------------------------------------
	-- Build the Sql for obtaining the factors 
	-- for the requests
	-----------------------------------------
	--	N'Request, Name, Status, Batch, Experiment, Experiment_ID, Instrument, Dataset, Dataset_ID, Block, Run_Order, Cart, LC_Col'
	EXEC @myError = MakeFactorCrosstabSQL_Ex
					@colList = N'Request, Name, Status, Batch, Experiment, Dataset, Instrument, Cart, LC_Col, Block, Run_Order',
					@Sql = @Sql OUTPUT,
					@message = @message OUTPUT						
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
GRANT EXECUTE ON [dbo].[GetRequestedRunParametersAndFactors] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetRequestedRunParametersAndFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetRequestedRunParametersAndFactors] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetRequestedRunParametersAndFactors] TO [PNL\D3M580] AS [dbo]
GO

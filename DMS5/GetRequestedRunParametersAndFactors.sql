/****** Object:  StoredProcedure [dbo].[GetRequestedRunParametersAndFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.GetRequestedRunParametersAndFactors
/****************************************************
**
**  Desc:
**		Returns the run parameters and factors associated with the run requests in the input list
**
**		This is used by http://dms2.pnl.gov/requested_run_batch_blocking/grid
**
**  Auth:   grk
**  Date:   03/28/2013 grk - Cloned from GetFactorCrosstabByBatch
**          01/05/2023 mem - Add view name to comment
**
*****************************************************/
(
	@itemList TEXT,
	@infoOnly tinyint = 0,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	= 0
	Declare @myError int	= 0

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
	-- Build the Sql for obtaining the factors for the requests
	--
	-- These columns correspond to view V_Requested_Run_Unified_List_Ex
	-----------------------------------------
	--
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
GRANT VIEW DEFINITION ON [dbo].[GetRequestedRunParametersAndFactors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetRequestedRunParametersAndFactors] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetRequestedRunParametersAndFactors] TO [DMS2_SP_User] AS [dbo]
GO

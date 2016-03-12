/****** Object:  StoredProcedure [dbo].[GetRequestedRunFactorsForExport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetRequestedRunFactorsForExport
/****************************************************
**
**	Desc: 
**		Returns the factors associated with the
**		run requests given by the itemList
**
**	Auth:	grk
**	Date:	03/22/2010
**	03/22/2010 grk - initial release
**    
*****************************************************/
(
	@itemList TEXT,
	@itemType VARCHAR(32) = 'Batch_ID',
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
	-- populate it with list of requests
	-----------------------------------------
	--
	EXEC @myError = GetRequestedRunsFromItemList
							@itemList,
							@itemType,
							@message OUTPUT
	--
	IF @myError <> 0
		RETURN @myError

	--
	IF @myError <> 0
		RETURN @myError
/*
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
*/
	-----------------------------------------
	-- Build the Sql for obtaining the factors 
	-- for the requests
	-----------------------------------------
	--
	DECLARE @colList VARCHAR(256)
	SET @colList = 'BatchID, Name,  Status,  Request,  Dataset_ID,  Dataset,  Experiment,  Experiment_ID,  Block,  [Run Order] '
	-- 
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
	-- run dynamic SQL
	-----------------------------------------
	--
	--Print @Sql
	Exec (@Sql)
	
	--
	return @myError

GO
GRANT EXECUTE ON [dbo].[GetRequestedRunFactorsForExport] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetRequestedRunFactorsForExport] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetRequestedRunFactorsForExport] TO [PNL\D3M578] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetRequestedRunFactorsForExport] TO [RBAC-DMS_User] AS [dbo]
GO

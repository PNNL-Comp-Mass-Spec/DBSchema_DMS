/****** Object:  StoredProcedure [dbo].[GetRequestedRunFactorsForEdit] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetRequestedRunFactorsForEdit
/****************************************************
**
**	Desc: 
**		Returns the factors associated with the
**		run requests given by the itemList
**
**	Auth:	grk
**	Date:	02/20/2010
**	03/02/2010 grk - added status field to requested run
**	03/08/2010 grk - improved field validation
**	03/18/2010 grk - eliminated call to GetFactorCrosstabByFactorID
**    
*****************************************************/
(
	@itemList TEXT,
	@itemType VARCHAR(32) = 'Batch_ID',
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

/* FUTURE:
	Code to add to filter requests by request name
	if and when this feature is needed
	New argument: @NameContains VARCHAR(48)
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
	SET @colList = ' ''x'' as Sel, BatchID, Experiment, Dataset, [Name], Status, Request'
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
GRANT VIEW DEFINITION ON [dbo].[GetRequestedRunFactorsForEdit] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetRequestedRunFactorsForEdit] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetRequestedRunFactorsForEdit] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[GetFactorCrosstabByFactorID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetFactorCrosstabByFactorID
/****************************************************
**
**	Desc: 
**		Returns the factors defined by the FactorID entries
**		in temporary table #Tmp_FactorItems (which must be
**		created by the calling procedure)
**
**		CREATE Table #Tmp_FactorItems (
**			FactorID int
**		)
**
**	Auth:	mem
**	Date:	02/18/2010
**			02/19/2010 grk - tweaked logic that creates @FactorNameList
**    
*****************************************************/
(
	@GenerateSQLOnly tinyint = 0,			-- If non-zero, then generates the Sql required to return the results, but doesn't actually return the results
	@CrossTabSql varchar(max)='' OUTPUT,
	@FactorNameList varchar(max)='' OUTPUT,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @GenerateSQLOnly = IsNull(@GenerateSQLOnly, 0)
	Set @CrossTabSql = ''
	Set @FactorNameList = ''
	Set @message = ''

	If Not Exists (SELECT * FROM #Tmp_FactorItems)
	Begin
		Set @CrossTabSql = 'SELECT Type, TargetID FROM T_Factor WHERE 1 = 2'
		
		If @GenerateSQLOnly = 0
		Begin
			-- Return an empty table
			Exec (@CrossTabSql)
			Set @message = '#Tmp_FactorItems is empty; nothing to return'
			Set @myError = 0
		End
	End
	Else
	Begin

		-----------------------------------------
		-- Determine the factor names defined by the 
		-- factor entries in #Tmp_FactorItems
		-----------------------------------------
		--
--old	Set @FactorNameList = NULL
		Set @FactorNameList = ''

--old	SELECT @FactorNameList = Coalesce(@FactorNameList + ',' + '[' + Src.Name + ']', '[' + Src.Name + ']')
		SELECT @FactorNameList = @FactorNameList + CASE WHEN @FactorNameList = '' THEN '' ELSE ',' END + '[' + Src.Name + ']'
		FROM T_Factor Src
			INNER JOIN #Tmp_FactorItems I
			ON Src.FactorID = I.FactorID
		GROUP BY Src.Name

		-----------------------------------------
		-- Return the factors, displayed as a crosstab (PivotTable)
		-----------------------------------------
		--
		Set @CrossTabSql = ''
		Set @CrossTabSql = @CrossTabSql + ' SELECT PivotResults.Type, PivotResults.TargetID,' + @FactorNameList
		Set @CrossTabSql = @CrossTabSql + ' FROM (SELECT Src.Type, Src.TargetID, Src.Name, Src.Value'
		Set @CrossTabSql = @CrossTabSql +       ' FROM  T_Factor Src INNER JOIN #Tmp_FactorItems I ON Src.FactorID = I.FactorID'
		Set @CrossTabSql = @CrossTabSql +       ') AS DataQ'
		Set @CrossTabSql = @CrossTabSql +       ' PIVOT ('
		Set @CrossTabSql = @CrossTabSql +       '   MAX(Value) FOR Name IN ( ' + @FactorNameList + ' ) '
		Set @CrossTabSql = @CrossTabSql +       ' ) AS PivotResults'

		
		If @GenerateSQLOnly = 0
		Begin
			Exec (@CrossTabSql)
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
		End

	End

	--
	return @myError

GO
GRANT EXECUTE ON [dbo].[GetFactorCrosstabByFactorID] TO [DMS2_SP_User] AS [dbo]
GO

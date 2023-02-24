/****** Object:  StoredProcedure [dbo].[make_factor_crosstab_sql_ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_factor_crosstab_sql_ex]
/****************************************************
**
**  Desc:
**      Returns dynamic SQL for a requested run factors crosstab query
**      Allows for specifying the view to query
**
**      The calling procedure must create temporary tables #REQS and #FACTORS
**
**      CREATE TABLE #REQS (
**          Request int
**      )
**
**      CREATE Table #FACTORS (
**          FactorID INT,
**          FactorName VARCHAR(128) NULL
**      )
**
**  Auth:   grk
**  Date:   03/28/2013 grk - Cloned from make_factor_crosstab_sql
**          11/11/2022 mem - Exclude unnamed factors when querying T_Factor
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @colList varchar(256),
    @viewName varchar(256) = 'V_Requested_Run_Unified_List_Ex',
    @sql varchar(max) OUTPUT,
    @message varchar(512) = '' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @msg varchar(256)

    Declare @CrossTabSql varchar(max)
    Declare @FactorNameList varchar(max)

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    -----------------------------------------

    -- Populate #FACTORS
    -- If none of the members of this batch has entries in T_Factors, #FACTORS will be empty (that's OK)
    -- Factor names in T_Factor should not be empty, but exclude empty strings for safety
    --
    INSERT INTO #FACTORS( FactorID, FactorName )
    SELECT Src.FactorID,
           Src.Name
    FROM T_Factor Src
         INNER JOIN #REQS
           ON Src.TargetID = #REQS.Request
    WHERE Src.Type = 'Run_Request' AND
          LTrim(RTrim(Src.Name)) <> ''
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error

    -----------------------------------------
    -- Determine the factor names defined by the
    -- factor entries in #FACTORS
    -----------------------------------------
    --
    Set @FactorNameList = ''
    --
    SELECT
        @FactorNameList = @FactorNameList + CASE WHEN @FactorNameList = '' THEN '' ELSE ',' END + '[' + Src.Name + ']'
    FROM T_Factor Src
        INNER JOIN #FACTORS I
        ON Src.FactorID = I.FactorID
    GROUP BY Src.Name

    -----------------------------------------
    -- SQL for factors as crosstab (PivotTable)
    -----------------------------------------
    --
    Set @CrossTabSql = ''
    Set @CrossTabSql = @CrossTabSql + ' SELECT PivotResults.Type, PivotResults.TargetID,' + @FactorNameList
    Set @CrossTabSql = @CrossTabSql + ' FROM (SELECT Src.Type, Src.TargetID, Src.Name, Src.Value'
    Set @CrossTabSql = @CrossTabSql +       ' FROM  T_Factor Src INNER JOIN #FACTORS I ON Src.FactorID = I.FactorID'
    Set @CrossTabSql = @CrossTabSql +       ') AS DataQ'
    Set @CrossTabSql = @CrossTabSql +       ' PIVOT ('
    Set @CrossTabSql = @CrossTabSql +       '   MAX(Value) FOR Name IN ( ' + @FactorNameList + ' ) '
    Set @CrossTabSql = @CrossTabSql +       ' ) AS PivotResults'

    -----------------------------------------
    -- Build dynamic SQL
    -----------------------------------------
    --
    Set @FactorNameList = IsNull(@FactorNameList, '')
    Set @Sql = ''
    Set @Sql = @Sql + 'SELECT ' + @colList + ' '

    If @FactorNameList <> ''
        Set @Sql = @Sql + ', ' + @FactorNameList

    Set @Sql = @Sql + ' FROM ( SELECT * FROM ' + @viewName + ' WHERE Request IN (SELECT Request FROM #REQS) '
    Set @Sql = @Sql + ' ) UQ '

    If @FactorNameList <> ''
        Set @Sql = @Sql + ' LEFT OUTER JOIN (' + @CrossTabSql + ') CrosstabQ ON UQ.Request = CrossTabQ.TargetID'

GO
GRANT VIEW DEFINITION ON [dbo].[make_factor_crosstab_sql_ex] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[make_factor_crosstab_sql_ex] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[make_factor_crosstab_sql_ex] TO [DMS2_SP_User] AS [dbo]
GO

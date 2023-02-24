/****** Object:  StoredProcedure [dbo].[MakeFactorCrosstabSQL] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MakeFactorCrosstabSQL]
/****************************************************
**
**  Desc:
**      Returns dynamic SQL for a requested run factors crosstab query,
**      using view V_Requested_Run_Unified_List
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
**  Date:   03/22/2010 grk - Initial release
**          11/11/2022 mem - Exclude unnamed factors when querying T_Factor
**          01/24/2023 mem - Add example value for @colList
**
*****************************************************/
(
    @colList varchar(256),              -- Example: ' ''x'' as sel, batch_id, experiment, dataset, name, status, request'
    @FactorNameContains varchar(48) = '',
    @Sql varchar(max) OUTPUT,
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

/* FUTURE:
    Code to allow filtering by factor name,
    when and if it is needed

    -----------------------------------------
    -- Filter factors by name
    -----------------------------------------
    --
    IF @FactorNameContains <> ''
    BEGIN
        DELETE FROM #FACTORS
        WHERE NOT FactorName LIKE '%' + @FactorNameContains + '%'
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
    END
*/

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

    Set @Sql = @Sql + ' FROM ( SELECT * FROM V_Requested_Run_Unified_List WHERE Request IN (SELECT Request FROM #REQS) '
    Set @Sql = @Sql + ' ) UQ '

    If @FactorNameList <> ''
        Set @Sql = @Sql + ' LEFT OUTER JOIN (' + @CrossTabSql + ') CrosstabQ ON UQ.Request = CrossTabQ.TargetID'


GO
GRANT VIEW DEFINITION ON [dbo].[MakeFactorCrosstabSQL] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MakeFactorCrosstabSQL] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeFactorCrosstabSQL] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[compile_usage_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[compile_usage_stats]
/****************************************************
**
**  Desc:
**      Counts the number of tables, rows, columns, and cells in this database
**
**  Return values: 0 if no error; otherwise error code
**
**  Auth:   mem
**  Date:   03/28/2008
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @displayStats tinyint = 1,              -- If non-zero, then the values will be displayed as a ResultSet
    @tables int = 0 output,
    @rows int = 0 output,
    @columns int = 0 output,
    @cells bigint = 0 output,
    @spaceUsageMB real = 0 output,
    @message varchar(255) = '' OUTPUT
)
AS
    set nocount on

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    set @DisplayStats = IsNull(@DisplayStats, 1)
    set @Tables = 0
    set @Rows = 0
    set @Columns = 0
    set @Cells = 0
    set @SpaceUsageMB = 0
    Set @message = ''

    ---------------------------------------------------
    -- Obtain the stats using 3 system tables and the view V_Table_Size_Summary
    ---------------------------------------------------

    SELECT  @Tables = COUNT(DISTINCT LookupQ.Table_Name),
            @Rows = SUM(TSS.Table_Row_Count),
            @Columns = SUM(LookupQ.ColumnCount),
            @Cells = SUM(Convert(bigint, LookupQ.ColumnCount) * Convert(bigint, TSS.Table_Row_Count)),
            @SpaceUsageMB = SUM(Space_Used_MB)
    FROM (  SELECT T.[Name] AS Table_Name, COUNT(*) AS ColumnCount
            FROM sys.columns C INNER JOIN
                 sys.objects O ON C.Object_ID = O.Object_ID INNER JOIN
                 sys.tables T ON T.Name = O.Name
            WHERE (T.[Name] <> 'dtproperties')
            GROUP BY T.[Name]
         ) LookupQ INNER JOIN
         V_Table_Size_Summary TSS ON LookupQ.Table_Name = TSS.Table_Name

    If @DisplayStats <> 0
        SELECT DB_Name() as DBName,
                @Tables AS [Tables],
                @Rows As [Rows],
                @Columns AS [Columns],
                @Cells As [Cells],
                @SpaceUsageMB As [SpaceUsageMB]

Done:

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[compile_usage_stats] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[compile_usage_stats] TO [Limited_Table_Write] AS [dbo]
GO

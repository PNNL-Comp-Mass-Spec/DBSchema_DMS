/****** Object:  StoredProcedure [dbo].[get_query_row_count_proc] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_query_row_count_proc]
/****************************************************
**
**  Desc:
**      Return the number of rows in the given table or view that match the given where clause (use an empty string if no where clause)
**
**      The row count is obtained from table T_Query_Row_Counts if it contains a recent query result
**      If the row count info is out-of-date, the table or view is re-queried and the cached value in T_Query_Row_Counts is updated
**
**  Arguments:
**    @objectName       Table or view to query
**    @whereClause      Where clause for filtering data; use an empty string if no filters are in use
**    @rowCount         Output: number of matching rows
**    @message          Status message
**
**  Example usage:
**
**      EXEC get_query_row_count_proc 'v_dataset_list_report_2', '', @rowCount = @rowCount Output
**
**      EXEC get_query_row_count_proc 'v_analysis_job_list_report_2', 'dataset like ''qc_mam_23%''', @rowCount = @rowCount Output
**
**  Auth:   mem
**  Date:   05/22/2024 mem - Initial version
**          05/25/2024 mem - Increment column Usage in T_Query_Row_Counts
**          06/13/2024 mem - When adding a new row to T_Query_Row_Counts, look for a default refresh interval value in table T_Query_Row_Count_Default_Refresh_Interval
**
*****************************************************/
(
    @objectName varchar(255),
    @whereClause varchar(4000),
    @rowCount bigint = 0 output,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @queryID int
    Declare @lastRefresh DateTime
    Declare @usage int
    Declare @refreshIntervalHours numeric(9,3)
    Declare @rowCountAgeHours numeric(9,3)

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    Set @objectName  = LTrim(RTrim(Coalesce(@objectName, '')));
    Set @whereClause = LTrim(RTrim(Coalesce(@whereClause, '')));
    Set @rowCount = 0

    If @objectName = ''
    Begin
        Print 'Warning: Object name is an empty string';

        RETURN 20000;
    End

    If @whereClause LIKE 'WHERE %'
    Begin
        -- Remove the WHERE keyword
        Set @whereClause = LTrim(RTrim(substring(@whereClause, 6, 4000)));
    End

    ------------------------------------------------
    -- Look for a cached row count
    ------------------------------------------------

    SELECT @queryID = Query_ID,
           @rowCount = Row_Count,
           @lastRefresh = Last_Refresh,
           @usage = Usage,
           @refreshIntervalHours = Refresh_Interval_Hours
    FROM T_Query_Row_Counts
    WHERE Object_Name  = @objectName AND
          Where_Clause = @whereClause;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        Set @rowCountAgeHours = DateDiff(second, @lastRefresh, GetDate()) / 3600.0;

        If @rowCountAgeHours < @refreshIntervalHours
        Begin
            -- Use the cached row count value, but first update columns last_used and usage
            UPDATE T_Query_Row_Counts
            SET Last_Used = GetDate(),
                Usage = @usage + 1
            WHERE Query_ID = @queryID;

            PRINT 'Using row count obtained ' + Cast(Round(@rowCountAgeHours, 2) AS varchar(20)) + ' hours ago (will refresh after ' +
                  Convert(varchar(40), DATEADD(second, Cast(@refreshIntervalHours * 60 * 60 as int), @lastRefresh), 120)
                      + ')'

            RETURN 0;
        End
    End
    Else
    Begin
        Set @queryID = -1
        Set @usage = 0
    End

    ------------------------------------------------
    -- Query the table or view to count the number of matching rows
    ------------------------------------------------

    Declare @parameterizedSQL nvarchar(500)

    If @whereClause = ''
    Begin
        Set @parameterizedSQL =
                   'SELECT @rowCount = COUNT(*) ' +
                   'FROM ' + QUOTENAME(@objectName)
    End
    Else
    Begin
        Set @parameterizedSQL =
                   'SELECT @rowCount = COUNT(*) ' +
                   'FROM ' + QUOTENAME(@objectName) + ' ' +
                   'WHERE ' +  @whereClause
    End

    Print 'Query: ' +  @parameterizedSQL

    Declare @paramDef nvarchar(500) = '@rowCount bigint output'

    Execute sp_executesql @parameterizedSQL, @paramDef, @rowCount = @rowCount output

    If @queryID <= 0
    Begin
        -- Look for a default refresh interval
        SELECT @refreshIntervalHours = Refresh_Interval_Hours
        FROM T_Query_Row_Count_Default_Refresh_Interval
        WHERE Object_Name = @objectName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            -- A default is not defined; use 4 hours
            Set @refreshIntervalHours = 4
        End

        INSERT INTO T_Query_Row_Counts (Object_Name, Where_Clause, Row_Count, Usage, Refresh_Interval_Hours)
        VALUES (@objectName, @whereClause, @rowCount, 1, @refreshIntervalHours);
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        RETURN @myError
    End

    UPDATE T_Query_Row_Counts
    SET Row_Count = @rowCount,
        Last_Used = GetDate(),
        Last_Refresh = GetDate(),
        Usage = @usage + 1
    WHERE Query_ID = @queryID;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_query_row_count_proc] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_query_row_count_proc] TO [DMS_SP_User] AS [dbo]
GO

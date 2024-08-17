/****** Object:  StoredProcedure [dbo].[find_log_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[find_log_entry]
/****************************************************
**
**  Desc:
**      Returns result set of main log satisfying the search parameters
**
**      This procedure is used by unit tests in class StoredProcedureTests in the PRISM Class Library
**
**  Example usage:
**      exec find_log_entry @EntryType = 'Normal', @MessageText = 'Complete', @maxRowCount = 50
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   08/23/2006
**          12/20/2006 mem - Now querying V_Log_Report using dynamic SQL (Ticket #349)
**          01/24/2008 mem - Switched the @i_ variables to use the datetime data type (Ticket #225)
**          03/23/2017 mem - Use Try_Convert instead of Convert
**                         - Use sp_executesql
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          01/05/2023 mem - Use new column names in V_Log_Report
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/05/2023 mem - Add @maxRowCount and rename procedure arguments
**
*****************************************************/
(
    @entryID varchar(20) = '',
    @postedBy varchar(64) = '',
    @postingTimeAfter varchar(20) = '',
    @postingTimeBefore varchar(20) = '',
    @entryType varchar(32) = '',
    @messageText varchar(500) = '',
    @maxRowCount int = 50,
    @message varchar(512) ='' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @sql nvarchar(4000)
    Declare @sqlWhere nvarchar(3800)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    DECLARE @entryIDValue int = Try_Parse(@EntryID as int)

    DECLARE @postedByWildcard varchar(64) = '%' + @PostedBy + '%'

    DECLARE @earliestPostingTime datetime = Try_Parse(@postingTimeAfter as datetime)
    DECLARE @latestPostingTime datetime  = Try_Parse(@postingTimeBefore as datetime)

    DECLARE @typeWildcard varchar(32) = '%' + @EntryType + '%'

    DECLARE @messageWildcard varchar(500) = '%' + @MessageText + '%'

    Set @maxRowCount = Coalesce(@maxRowCount, 0)

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    --
    If @maxRowCount > 0
        Set @sql = ' SELECT TOP ' + Cast(@maxRowCount AS varchar(12)) + ' * FROM V_Log_Report'
    Else
        Set @sql = ' SELECT * FROM V_Log_Report'

    Set @sqlWhere = ''
    If @entryIDValue > 0
        Set @sqlWhere = @sqlWhere + ' AND ([Entry] = @entryIDValue)'
    If Len(@PostedBy) > 0
        Set @sqlWhere = @sqlWhere + ' AND ([Posted_By] LIKE @postedByWildcard )'
    If Len(@postingTimeAfter) > 0
        Set @sqlWhere = @sqlWhere + ' AND ([Entered] >= @earliestPostingTime )'
    If Len(@postingTimeBefore) > 0
        Set @sqlWhere = @sqlWhere + ' AND ([Entered] < @latestPostingTime )'
    If Len(@EntryType) > 0
        Set @sqlWhere = @sqlWhere + ' AND ([Type] LIKE @typeWildcard )'
    If Len(@MessageText) > 0
        Set @sqlWhere = @sqlWhere + ' AND ([Message] LIKE @messageWildcard)'

    If Len(@sqlWhere) > 0
    Begin
        -- One or more filters are defined
        -- Remove the first AND from the start of @sqlWhere and add the word WHERE
        Set @sqlWhere = 'WHERE ' + Substring(@sqlWhere, 6, Len(@sqlWhere) - 5)
        Set @sql = @sql + ' ' + @sqlWhere
    End

    If @maxRowCount > 0
        Set @sql = @sql + ' ORDER BY entry Desc'
    Else
        Set @sql = @sql + ' ORDER BY entry Asc'

    ---------------------------------------------------
    -- Run the query
    ---------------------------------------------------
    --
    Declare @sqlParams NVarchar(2000) = N'@entryIDValue int, @postedByWildcard varchar(64), @earliestPostingTime datetime, @latestPostingTime datetime, @typeWildcard varchar(32), @messageWildcard varchar(500)'

    EXEC sp_executesql @sql, @sqlParams, @entryID, @postedByWildcard, @earliestPostingTime, @latestPostingTime, @typeWildcard, @messageWildcard
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error occurred attempting to execute query'
        RAISERROR (@message, 10, 1)
        Return 51007
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[find_log_entry] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_log_entry] TO [DMSReader] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_log_entry] TO [Limited_Table_Write] AS [dbo]
GO

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
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @entry varchar(20) = '',
    @postedBy varchar(64) = '',
    @postingTime_After varchar(20) = '',
    @postingTime_Before varchar(20) = '',
    @entryType varchar(32) = '',
    @messageText varchar(500) = '',
    @message varchar(512) ='' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @sql nvarchar(4000)
    Declare @W nvarchar(3800)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    DECLARE @entryID int = Try_Parse(@Entry as int)
    --
    DECLARE @postedByWildcard varchar(64) = '%' + @PostedBy + '%'
    --
    DECLARE @earlistPostingTime datetime = Try_Parse(@PostingTime_After as datetime)
    DECLARE @latestPostingTime datetime = Try_Parse(@PostingTime_Before as datetime)
    --
    DECLARE @typeWildcard varchar(32) = '%' + @EntryType + '%'
    --
    DECLARE @messageWildcard varchar(500) = '%' + @MessageText + '%'
    --

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    --
    Set @sql = ' SELECT * FROM V_Log_Report'

    Set @W = ''
    If Len(@Entry) > 0
        Set @W = @W + ' AND ([Entry] = @entryID)'
    If Len(@PostedBy) > 0
        Set @W = @W + ' AND ([Posted_By] LIKE @postedByWildcard )'
    If Len(@PostingTime_After) > 0
        Set @W = @W + ' AND ([Entered] >= @earlistPostingTime )'
    If Len(@PostingTime_Before) > 0
        Set @W = @W + ' AND ([Entered] < @latestPostingTime )'
    If Len(@EntryType) > 0
        Set @W = @W + ' AND ([Type] LIKE @typeWildcard )'
    If Len(@MessageText) > 0
        Set @W = @W + ' AND ([Message] LIKE @messageWildcard)'

    If Len(@W) > 0
    Begin
        -- One or more filters are defined
        -- Remove the first AND from the start of @W and add the word WHERE
        Set @W = 'WHERE ' + Substring(@W, 6, Len(@W) - 5)
        Set @sql = @sql + ' ' + @W
    End

    ---------------------------------------------------
    -- Run the query
    ---------------------------------------------------
    --
    Declare @sqlParams NVarchar(2000) = N'@entryID int, @postedByWildcard varchar(64), @earlistPostingTime datetime, @latestPostingTime datetime, @typeWildcard varchar(32), @messageWildcard varchar(500)'

    EXEC sp_executesql @sql, @sqlParams, @entryID, @postedByWildcard, @earlistPostingTime, @latestPostingTime, @typeWildcard, @messageWildcard
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error occurred attempting to execute query'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[find_log_entry] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_log_entry] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_log_entry] TO [DMSReader] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_log_entry] TO [Limited_Table_Write] AS [dbo]
GO

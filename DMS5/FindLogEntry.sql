/****** Object:  StoredProcedure [dbo].[FindLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindLogEntry]
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
**                           - Use sp_executesql
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @Entry varchar(20) = '',
    @PostedBy varchar(64) = '',
    @PostingTime_After varchar(20) = '',
    @PostingTime_Before varchar(20) = '',
    @EntryType varchar(32) = '',
    @MessageText varchar(500) = '',
    @message varchar(512) ='' output
)
As
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    declare @sql nvarchar(4000)
    declare @W nvarchar(3800)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    DECLARE @entryID int = TRY_CONVERT(int, @Entry)
    --
    DECLARE @postedByWildcard varchar(64) = '%' + @PostedBy + '%'
    --
    DECLARE @earlistPostingTime datetime = TRY_CONVERT(datetime, @PostingTime_After)
    DECLARE @latestPostingTime datetime = TRY_CONVERT(datetime, @PostingTime_Before)
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
        Set @W = @W + ' AND ([Posted By] LIKE @postedByWildcard )'
    If Len(@PostingTime_After) > 0
        Set @W = @W + ' AND ([Posting Time] >= @earlistPostingTime )'
    If Len(@PostingTime_Before) > 0
        Set @W = @W + ' AND ([Posting Time] < @latestPostingTime )'
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
GRANT VIEW DEFINITION ON [dbo].[FindLogEntry] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindLogEntry] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindLogEntry] TO [DMSReader] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindLogEntry] TO [Limited_Table_Write] AS [dbo]
GO

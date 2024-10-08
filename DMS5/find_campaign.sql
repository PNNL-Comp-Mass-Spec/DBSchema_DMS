/****** Object:  StoredProcedure [dbo].[find_campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[find_campaign]
/****************************************************
**
**  Desc:
**      Returns result set of Campaigns
**      satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/31/2006
**          12/20/2006 mem - Now querying V_Campaign_Detail_Report_Ex using dynamic SQL (Ticket #349)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @campaign varchar(50) = '',
    @project varchar(50) = '',
    @projectMgr varchar(103) = '',
    @pi varchar(103) = '',
    @comment varchar(500) = '',
    @created_After varchar(20) = '',
    @created_Before varchar(20) = '',
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    declare @S varchar(4000)
    declare @W varchar(3800)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    -- future: this could get more complicated

    ---------------------------------------------------
    -- Convert input fields
    ---------------------------------------------------

    DECLARE @iCampaign varchar(50)
    SET @iCampaign = '%' + @Campaign + '%'
    --
    DECLARE @iProject varchar(50)
    SET @iProject = '%' + @Project + '%'
    --
    DECLARE @iProjectMgr varchar(103)
    SET @iProjectMgr = '%' + @ProjectMgr + '%'
    --
    DECLARE @iPI varchar(103)
    SET @iPI = '%' + @PI + '%'
    --
    DECLARE @iComment varchar(500)
    SET @iComment = '%' + @Comment + '%'
    --
    DECLARE @iCreated_after datetime
    DECLARE @iCreated_before datetime
    SET @iCreated_after = CONVERT(datetime, @Created_After)
    SET @iCreated_before = CONVERT(datetime, @Created_Before)
    --

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    Set @S = ' SELECT * FROM V_Campaign_Detail_Report_Ex'

    Set @W = ''
    If Len(@Campaign) > 0
        Set @W = @W + ' AND ([Campaign] LIKE ''' + @iCampaign + ''' )'
    If Len(@Project) > 0
        Set @W = @W + ' AND ([Project] LIKE ''' + @iProject + ''' )'
    If Len(@ProjectMgr) > 0
        Set @W = @W + ' AND ([ProjectMgr] LIKE ''' + @iProjectMgr + ''' )'
    If Len(@PI) > 0
        Set @W = @W + ' AND ([PI] LIKE ''' + @iPI + ''' )'
    If Len(@Comment) > 0
        Set @W = @W + ' AND ([Comment] LIKE ''' + @iComment + ''' )'

    If Len(@Created_After) > 0
        Set @W = @W + ' AND ([Created] >= ''' + Convert(varchar(32), @iCreated_after, 121) + ''' )'
    If Len(@Created_Before) > 0
        Set @W = @W + ' AND ([Created] < ''' + Convert(varchar(32), @iCreated_before, 121) + ''' )'

    If Len(@W) > 0
    Begin
        -- One or more filters are defined
        -- Remove the first AND from the start of @W and add the word WHERE
        Set @W = 'WHERE ' + Substring(@W, 6, Len(@W) - 5)
        Set @S = @S + ' ' + @W
    End

    Set @S = @S + ' ORDER BY Campaign'

    ---------------------------------------------------
    -- Run the query
    ---------------------------------------------------
    EXEC (@S)
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
GRANT VIEW DEFINITION ON [dbo].[find_campaign] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_campaign] TO [Limited_Table_Write] AS [dbo]
GO

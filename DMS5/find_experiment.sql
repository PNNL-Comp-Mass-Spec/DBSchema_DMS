/****** Object:  StoredProcedure [dbo].[FindExperiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[FindExperiment]
/****************************************************
**
**  Desc:
**      Returns result set of Experiments
**      satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/06/2005
**          12/20/2006 mem - Now querying V_Find_Experiment using dynamic SQL (Ticket #349)
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @Experiment varchar(50) = '',
    @Researcher varchar(50) = '',
    @Organism varchar(50) = '',
    @Reason varchar(500) = '',
    @Comment varchar(500) = '',
    @Created_After varchar(20) = '',
    @Created_Before varchar(20) = '',
    @Campaign varchar(50) = '',
    @CellCultures varchar(1024) = '',
    @ID varchar(20) = '',
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

    DECLARE @iExperiment varchar(50)
    SET @iExperiment = '%' + @Experiment + '%'
    --
    DECLARE @iResearcher varchar(50)
    SET @iResearcher = '%' + @Researcher + '%'
    --
    DECLARE @iOrganism varchar(50)
    SET @iOrganism = '%' + @Organism + '%'
    --
    DECLARE @iReason varchar(500)
    SET @iReason = '%' + @Reason + '%'
    --
    DECLARE @iComment varchar(500)
    SET @iComment = '%' + @Comment + '%'
    --
    DECLARE @iCreated_after datetime
    DECLARE @iCreated_before datetime
    SET @iCreated_after = CONVERT(datetime, @Created_After)
    SET @iCreated_before = CONVERT(datetime, @Created_Before)
    --
    DECLARE @iCampaign varchar(50)
    SET @iCampaign = '%' + @Campaign + '%'
    --
    DECLARE @iCellCultures varchar(1024)
    SET @iCellCultures = '%' + @CellCultures + '%'
    --
    DECLARE @iID int
    SET @iID = CONVERT(int, @ID)
    --

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    Set @S = ' SELECT * FROM V_Find_Experiment'

    Set @W = ''
    If Len(@Experiment) > 0
        Set @W = @W + ' AND ([Experiment] LIKE ''' + @iExperiment + ''' )'
    If Len(@Researcher) > 0
        Set @W = @W + ' AND ([Researcher] LIKE ''' + @iResearcher + ''' )'
    If Len(@Organism) > 0
        Set @W = @W + ' AND ([Organism] LIKE ''' + @iOrganism + ''' )'
    If Len(@Reason) > 0
        Set @W = @W + ' AND ([Reason] LIKE ''' + @iReason + ''' )'
    If Len(@Comment) > 0
        Set @W = @W + ' AND ([Comment] LIKE ''' + @iComment + ''' )'

    If Len(@Created_After) > 0
        Set @W = @W + ' AND ([Created] >= ''' + Convert(varchar(32), @iCreated_after, 121) + ''' )'
    If Len(@Created_Before) > 0
        Set @W = @W + ' AND ([Created] < ''' + Convert(varchar(32), @iCreated_before, 121) + ''' )'

    If Len(@Campaign) > 0
        Set @W = @W + ' AND ([Campaign] LIKE ''' + @iCampaign + ''' )'
    If Len(@CellCultures) > 0
        Set @W = @W + ' AND ([Cell Cultures] LIKE ''' + @iCellCultures + ''' )'
    If Len(@ID) > 0
        Set @W = @W + ' AND ([ID] = ' + Convert(varchar(19), @iID) + ' )'

    If Len(@W) > 0
    Begin
        -- One or more filters are defined
        -- Remove the first AND from the start of @W and add the word WHERE
        Set @W = 'WHERE ' + Substring(@W, 6, Len(@W) - 5)
        Set @S = @S + ' ' + @W
    End

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
GRANT VIEW DEFINITION ON [dbo].[FindExperiment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExperiment] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExperiment] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindExperiment] TO [Limited_Table_Write] AS [dbo]
GO

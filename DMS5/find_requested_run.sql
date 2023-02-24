/****** Object:  StoredProcedure [dbo].[Find_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Find_Requested_Run]
/****************************************************
**
**  Desc:
**      Returns result set of requested/scheduled runs
**      satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/15/2006
**          12/20/2006 mem - Now querying V_Find_Requested_Run using dynamic SQL (Ticket #349)
**          04/27/2007 grk - Added LC Cart field and dropped some never-used fields (Ticket #447)
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @RequestID varchar(20) = '',
    @RequestName varchar(128) = '',
    @Experiment varchar(50) = '',
    @Instrument varchar(128) = '',
    @LCCart varchar(128) = '',
    @Requester varchar(50) = '',
    @Created_After varchar(20) = '',
    @Created_Before varchar(20) = '',
    @WorkPackage varchar(50) = '',
    @Usage varchar(50) = '',
    @Proposal varchar(10) = '',
    @Comment varchar(244) = '',
    @Wellplate varchar(50) = '',
    @Well varchar(50) = '',
    @Batch varchar(20) = '',
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

    DECLARE @iRequestID int
    SET @iRequestID = CONVERT(int, @RequestID)
    --
    DECLARE @iRequestName varchar(128)
    SET @iRequestName = '%' + @RequestName + '%'
    --
    DECLARE @iExperiment varchar(50)
    SET @iExperiment = '%' + @Experiment + '%'
    --
    DECLARE @iInstrument varchar(128)
    SET @iInstrument = '%' + @Instrument + '%'
    --
    DECLARE @iLCCart varchar(128)
    SET @iLCCart = '%' + @LCCart + '%'
    --
    DECLARE @iRequester varchar(50)
    SET @iRequester = '%' + @Requester + '%'
    --
    DECLARE @iCreated_after datetime
    DECLARE @iCreated_before datetime
    SET @iCreated_after = CONVERT(datetime, @Created_After)
    SET @iCreated_before = CONVERT(datetime, @Created_Before)
    --
    DECLARE @iWorkPackage varchar(50)
    SET @iWorkPackage = '%' + @WorkPackage + '%'
    --
    DECLARE @iUsage varchar(50)
    SET @iUsage = '%' + @Usage + '%'
    --
    DECLARE @iProposal varchar(10)
    SET @iProposal = '%' + @Proposal + '%'
    --
    DECLARE @iComment varchar(244)
    SET @iComment = '%' + @Comment + '%'
    --
    DECLARE @iWellplate varchar(50)
    SET @iWellplate = '%' + @Wellplate + '%'
    --
    DECLARE @iWell varchar(50)
    SET @iWell = '%' + @Well + '%'
    --
    DECLARE @iBatch int
    SET @iBatch = CONVERT(int, @Batch)
    --

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    Set @S = ' SELECT * FROM V_Find_Requested_Run'
    Set @W = ''
    If Len(@RequestID) > 0
        Set @W = @W + ' AND ([Request_ID] = ' + Convert(varchar(19), @iRequestID) + ' )'
    If Len(@RequestName) > 0
        Set @W = @W + ' AND ([Request_Name] LIKE ''' + @iRequestName + ''' )'
    If Len(@Experiment) > 0
        Set @W = @W + ' AND ([Experiment] LIKE ''' + @iExperiment + ''' )'
    If Len(@Instrument) > 0
        Set @W = @W + ' AND ([Instrument] LIKE ''' + @iInstrument + ''' )'
    If Len(@LCCart) > 0
        Set @W = @W + ' AND ([LC Cart] LIKE ''' + @iLCCart + ''' )'
    If Len(@Requester) > 0
        Set @W = @W + ' AND ([Requester] LIKE ''' + @iRequester + ''' )'
    If Len(@Created_After) > 0
        Set @W = @W + ' AND ([Created] >= ''' + Convert(varchar(32), @iCreated_after, 121) + ''' )'
    If Len(@Created_Before) > 0
        Set @W = @W + ' AND ([Created] < ''' + Convert(varchar(32), @iCreated_before, 121) + ''' )'
    If Len(@WorkPackage) > 0
        Set @W = @W + ' AND ([Work_Package] LIKE ''' + @iWorkPackage + ''' )'
    If Len(@Usage) > 0
        Set @W = @W + ' AND ([Usage] LIKE ''' + @iUsage + ''' )'
    If Len(@Proposal) > 0
        Set @W = @W + ' AND ([Proposal] LIKE ''' + @iProposal + ''' )'
    If Len(@Comment) > 0
        Set @W = @W + ' AND ([Comment] LIKE ''' + @iComment + ''' )'
    If Len(@Wellplate) > 0
        Set @W = @W + ' AND ([Wellplate] LIKE ''' + @iWellplate + ''' )'
    If Len(@Well) > 0
        Set @W = @W + ' AND ([Well] LIKE ''' + @iWell + ''' )'
    If Len(@Batch) > 0
        Set @W = @W + ' AND ([Batch] = ' + Convert(varchar(19), @iBatch) + ' )'

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
GRANT VIEW DEFINITION ON [dbo].[Find_Requested_Run] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Find_Requested_Run] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Find_Requested_Run] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Find_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO

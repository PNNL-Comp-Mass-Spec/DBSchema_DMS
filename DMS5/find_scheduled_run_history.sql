/****** Object:  StoredProcedure [dbo].[find_scheduled_run_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[find_scheduled_run_history]
/****************************************************
**
**  Desc:
**      Returns result set of Scheduled Run History satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/15/2006
**          12/20/2006 mem - Now querying V_Find_Scheduled_Run_History using dynamic SQL (Ticket #349)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          01/12/2024 mem - Use renamed column Requester in V_Find_Scheduled_Run_History
**                         - Rename argument to @requester
**
*****************************************************/
(
    @requestID varchar(20) = '',
    @requestName varchar(128) = '',
    @reqCreated_After varchar(20) = '',
    @reqCreated_Before varchar(20) = '',
    @experiment varchar(50) = '',
    @dataset varchar(128) = '',
    @dscreated_After varchar(20) = '',
    @dscreated_Before varchar(20) = '',
    @workPackage varchar(50) = '',
    @campaign varchar(50) = '',
    @requester varchar(50) = '',
    @instrument varchar(128) = '',
    @runType varchar(50) = '',
    @comment varchar(244) = '',
    @batch varchar(20) = '',
    @blockingFactor varchar(50) = '',
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @S varchar(4000)
    Declare @W varchar(3800)

    ---------------------------------------------------
    -- Convert input fields
    ---------------------------------------------------

    Declare @iRequest_ID int              = CONVERT(int, @RequestID)
    Declare @iRequest_Name varchar(128)   = '%' + @RequestName + '%'
    Declare @iReq_Created_after datetime  = CONVERT(datetime, @ReqCreated_After)
    Declare @iReq_Created_before datetime = CONVERT(datetime, @ReqCreated_Before)
    Declare @iExperiment varchar(50)      = '%' + @Experiment + '%'
    Declare @iDataset varchar(128)        = '%' + @Dataset + '%'
    Declare @iDS_created_after datetime   = CONVERT(datetime, @DScreated_After)
    Declare @iDS_created_before datetime  = CONVERT(datetime, @DScreated_Before)
    Declare @iWork_Package varchar(50)    = '%' + @WorkPackage + '%'
    Declare @iCampaign varchar(50)        = '%' + @Campaign + '%'
    Declare @iRequester varchar(50)       = '%' + @Requester + '%'
    Declare @iInstrument varchar(128)     = '%' + @Instrument + '%'
    Declare @iRun_Type varchar(50)        = '%' + @RunType + '%'
    Declare @iComment varchar(244)        = '%' + @Comment + '%'
    Declare @iBatch int                   = CONVERT(int, @Batch)
    Declare @iBlocking_Factor varchar(50) = '%' + @BlockingFactor + '%'

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    Set @S = ' SELECT * FROM V_Find_Scheduled_Run_History'

    Set @W = ''
    If Len(@RequestID) > 0
        Set @W = @W + ' AND ([Request_ID] = ' + Convert(varchar(19), @iRequest_ID) + ' )'
    If Len(@RequestName) > 0
        Set @W = @W + ' AND ([Request_Name] LIKE ''' + @iRequest_Name + ''' )'
    If Len(@ReqCreated_After) > 0
        Set @W = @W + ' AND ([Req_Created] >= ''' + Convert(varchar(32), @iReq_Created_after, 121) + ''' )'
    If Len(@ReqCreated_Before) > 0
        Set @W = @W + ' AND ([Req_Created] < ''' + Convert(varchar(32), @iReq_Created_before, 121) + ''' )'
    If Len(@Experiment) > 0
        Set @W = @W + ' AND ([Experiment] LIKE ''' + @iExperiment + ''' )'
    If Len(@Dataset) > 0
        Set @W = @W + ' AND ([Dataset] LIKE ''' + @iDataset + ''' )'
    If Len(@DScreated_After) > 0
        Set @W = @W + ' AND ([DS_created] >= ''' + Convert(varchar(32), @iDS_created_after, 121) + ''' )'
    If Len(@DScreated_Before) > 0
        Set @W = @W + ' AND ([DS_created] < ''' + Convert(varchar(32), @iDS_created_before, 121) + ''' )'
    If Len(@WorkPackage) > 0
        Set @W = @W + ' AND ([Work_Package] LIKE ''' + @iWork_Package + ''' )'
    If Len(@Campaign) > 0
        Set @W = @W + ' AND ([Campaign] LIKE ''' + @iCampaign + ''' )'
    If Len(@Requester) > 0
        Set @W = @W + ' AND ([Requester] LIKE ''' + @iRequester + ''' )'
    If Len(@Instrument) > 0
        Set @W = @W + ' AND ([Instrument] LIKE ''' + @iInstrument + ''' )'
    If Len(@RunType) > 0
        Set @W = @W + ' AND ([Run_Type] LIKE ''' + @iRun_Type + ''' )'
    If Len(@Comment) > 0
        Set @W = @W + ' AND ([Comment] LIKE ''' + @iComment + ''' )'
    If Len(@Batch) > 0
        Set @W = @W + ' AND ([Batch] = ' + Convert(varchar(19), @iBatch) + ' )'
    If Len(@BlockingFactor) > 0
        Set @W = @W + ' AND ([Blocking_Factor] LIKE ''' + @iBlocking_Factor + ''' )'

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

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[find_scheduled_run_history] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_scheduled_run_history] TO [Limited_Table_Write] AS [dbo]
GO

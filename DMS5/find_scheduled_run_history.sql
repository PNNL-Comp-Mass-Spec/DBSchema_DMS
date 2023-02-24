/****** Object:  StoredProcedure [dbo].[Find_Scheduled_Run_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[find_scheduled_run_history]
/****************************************************
**
**  Desc:
**      Returns result set of Scheduled Run History
**      satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/15/2006
**          12/20/2006 mem - Now querying V_find_scheduled_run_history using dynamic SQL (Ticket #349)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
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
    @requestor varchar(50) = '',
    @instrument varchar(128) = '',
    @runType varchar(50) = '',
    @comment varchar(244) = '',
    @batch varchar(20) = '',
    @blockingFactor varchar(50) = '',
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

    DECLARE @iRequest_ID int
    SET @iRequest_ID = CONVERT(int, @RequestID)
    --
    DECLARE @iRequest_Name varchar(128)
    SET @iRequest_Name = '%' + @RequestName + '%'
    --
    DECLARE @iReq_Created_after datetime
    DECLARE @iReq_Created_before datetime
    SET @iReq_Created_after = CONVERT(datetime, @ReqCreated_After)
    SET @iReq_Created_before = CONVERT(datetime, @ReqCreated_Before)
    --
    DECLARE @iExperiment varchar(50)
    SET @iExperiment = '%' + @Experiment + '%'
    --
    DECLARE @iDataset varchar(128)
    SET @iDataset = '%' + @Dataset + '%'
    --
    DECLARE @iDS_created_after datetime
    DECLARE @iDS_created_before datetime
    SET @iDS_created_after = CONVERT(datetime, @DScreated_After)
    SET @iDS_created_before = CONVERT(datetime, @DScreated_Before)
    --
    DECLARE @iWork_Package varchar(50)
    SET @iWork_Package = '%' + @WorkPackage + '%'
    --
    DECLARE @iCampaign varchar(50)
    SET @iCampaign = '%' + @Campaign + '%'
    --
    DECLARE @iRequestor varchar(50)
    SET @iRequestor = '%' + @Requestor + '%'
    --
    DECLARE @iInstrument varchar(128)
    SET @iInstrument = '%' + @Instrument + '%'
    --
    DECLARE @iRun_Type varchar(50)
    SET @iRun_Type = '%' + @RunType + '%'
    --
    DECLARE @iComment varchar(244)
    SET @iComment = '%' + @Comment + '%'
    --
    DECLARE @iBatch int
    SET @iBatch = CONVERT(int, @Batch)
    --
    DECLARE @iBlocking_Factor varchar(50)
    SET @iBlocking_Factor = '%' + @BlockingFactor + '%'
    --

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    Set @S = ' SELECT * FROM V_find_scheduled_run_history'

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
    If Len(@Requestor) > 0
        Set @W = @W + ' AND ([Requestor] LIKE ''' + @iRequestor + ''' )'
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

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[Find_Scheduled_Run_History] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Find_Scheduled_Run_History] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Find_Scheduled_Run_History] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Find_Scheduled_Run_History] TO [Limited_Table_Write] AS [dbo]
GO

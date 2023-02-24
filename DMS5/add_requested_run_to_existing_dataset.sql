/****** Object:  StoredProcedure [dbo].[add_requested_run_to_existing_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_requested_run_to_existing_dataset]
/****************************************************
**
**  Desc:   Creates a requested run and associates it with
**          the given dataset if there is not currently one
**
**          The requested run will be named one of the following:
**          'AutoReq_DatasetName'
**          'AutoReq2_DatasetName'
**          'AutoReq3_DatasetName'
**
**
**          Note that this procedure is similar to add_missing_requested_run,
**          though that procedure is intended to be run via automation
**          to add requested runs to existing datasets that don't yet have one
**
**          In contrast, this procedure has parameter @templateRequestID which defines
**          an existing requested run ID from which to lookup EUS information
**
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/23/2011 grk - initial release
**          11/29/2011 mem - Now auto-determining @operatorUsername if @callingUser is empty
**          12/14/2011 mem - Now passing @callingUser to add_update_requested_run and consume_scheduled_run
**          05/08/2013 mem - Now setting @wellplateName and @wellNumber to Null when calling add_update_requested_run
**          01/29/2016 mem - Now calling get_wp_for_eus_proposal to get the best work package for the given EUS Proposal
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/22/2017 mem - If necessary, change the prefix from AutoReq_ to AutoReq2_ or AutoReq3 to avoid conflicts
**          06/13/2017 mem - Rename @operatorUsername to @requestorUsername when calling add_update_requested_run
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          01/24/2020 mem - Add mode 'preview'
**          01/31/2020 mem - Display all of the values sent to add_update_requested_run when mode is 'preview'
**          02/04/2020 mem - Add mode 'add-debug', which will associate the requested run with the dataset, but will also print out debug statements
**          05/23/2022 mem - Rename @requestorUsername to @requesterUsername when calling add_update_requested_run
**          11/25/2022 mem - Update call to add_update_requested_run to use new parameter name
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetID INT = 0,                 -- Can supply ID for dataset or name for dataset (but not both)
    @datasetName varchar(128),           --
    @templateRequestID INT,             -- existing request to use for looking up some parameters for new one
    @mode varchar(12) = 'add',          -- compatibility with web entry page and possible future use; supports 'add', 'add-debug', and 'preview'
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0
    Declare @showDebugStatements Tinyint = 0

    Set @message = ''

    If @mode Like 'add%debug'
    Begin
        Set @showDebugStatements = 1
        Set @mode = 'add'
    End

    Begin TRY

    ---------------------------------------------------
    -- Validate dataset identification
    -- (either name or ID, but not both)
    ---------------------------------------------------

    Declare @dID INT = 0
    Declare @dName varchar(128) = ''

    SET @datasetID = ISNULL(@datasetID, 0)
    SET @datasetName = ISNULL(@datasetName, '')
    Set @mode = Ltrim(Rtrim(@mode))

    If @datasetID <> 0 AND @datasetName <> ''
        RAISERROR ('Cannot specify both datasetID "%d" and datasetName "%s"', 11, 3, @datasetID, @datasetName)

    ---------------------------------------------------
    -- Does dataset exist?
    ---------------------------------------------------

    SELECT @dID = Dataset_ID,
           @dName = Dataset_Num
    FROM dbo.T_Dataset
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 And @datasetName <> ''
    Begin
        SELECT @dID = Dataset_ID,
               @dName = Dataset_Num
        FROM dbo.T_Dataset
        WHERE Dataset_Num = @datasetName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    If @dID = 0
        RAISERROR ('Could not find datasetID "%d" or dataset "%s"', 11, 4, @datasetID, @datasetName)

    ---------------------------------------------------
    -- Does the dataset have an associated request?
    ---------------------------------------------------

    Declare @rID INT = 0

    SELECT @rID = RR.ID
    FROM   T_Requested_Run AS RR
    WHERE  RR.DatasetID = @dID

    If @rID <> 0
        RAISERROR ('Dataset "%d" has existing requested run "%d"', 11, 5, @dID, @rID)

    ---------------------------------------------------
    -- Parameters for creating requested run
    ---------------------------------------------------

    Declare @reqName varchar(128) = 'AutoReq_' + @dName
    Declare @checkForDuplicates tinyint = 1
    Declare @iteration int = 1

    While @checkForDuplicates > 0
    Begin
        If @showDebugStatements > 0
            Print 'Looking for existing requested run named ' + @reqName

        If Exists (SELECT * FROM T_Requested_Run WHERE RDS_Name = @reqName)
        Begin
            -- Requested run already exists; bump up @iteration and try again
            Set @iteration = @iteration + 1
            Set @reqName = 'AutoReq' + Cast(@iteration as varchar(5)) + '_' + @dName
        End
        Else
        Begin
            Set @checkForDuplicates = 0
        End
    End

    Declare @experimentName varchar(64)
    Declare @instrumentName varchar(64)
    Declare @msType varchar(20)
    Declare @comment varchar(1024) = 'Automatically created by Dataset entry'
    Declare @workPackage varchar(50)  = 'none'
    Declare @requesterUsername varchar(128) = ''
    Declare @eusProposalID varchar(10) = 'na'
    Declare @eusUsageType varchar(50)
    Declare @eusUsersList varchar(1024) = ''
    Declare @request int = 0
    Declare @secSep varchar(64) = 'LC-Formic_1hr'
    Declare @msg varchar(512) = ''

    ---------------------------------------------------
    -- Fill in some requested run parameters from dataset
    ---------------------------------------------------

    If @showDebugStatements > 0
        Print 'Querying T_Dataset, T_Instrument_Name, etc. for Dataset_ID ' + Cast(@dID As Varchar(12))

    SELECT @experimentName = E.Experiment_Num,
           @instrumentName = InstName.IN_name,
           @msType = DTN.DST_name,
           @secSep = SS.SS_name
    FROM T_Dataset AS TD
         INNER JOIN T_Instrument_Name AS InstName
           ON TD.DS_instrument_name_ID = InstName.Instrument_ID
         INNER JOIN T_DatasetTypeName AS DTN
           ON TD.DS_type_ID = DTN.DST_Type_ID
         INNER JOIN T_Experiments AS E
           ON TD.Exp_ID = E.Exp_ID
         INNER JOIN T_Secondary_Sep AS SS
           ON TD.DS_sec_sep = SS.SS_name
    WHERE TD.Dataset_ID = @dID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Fill in some parameters from existing requested run
    -- (if an ID was provided in @templateRequestID)
    ---------------------------------------------------

    If ISNULL(@templateRequestID, 0) <> 0
    Begin
        If @showDebugStatements > 0
            Print 'Querying T_Requested_Run AND T_EUS_UsageType for request ID  ' + Cast(@templateRequestID As Varchar(12))

        SELECT @workPackage = RDS_WorkPackage,
               @requesterUsername = RDS_Requestor_PRN,
               @eusProposalID = RDS_EUS_Proposal_ID,
               @eusUsageType = EUT.Name,
               @eusUsersList = dbo.get_requested_run_eus_users_list(RR.ID, 'I')
        FROM T_Requested_Run AS RR
             INNER JOIN dbo.T_EUS_UsageType AS EUT
               ON RR.RDS_EUS_UsageType = EUT.ID
        WHERE RR.ID = @templateRequestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount <> 1
        Begin
            Set @message = 'Template request ID ' + Convert(varchar(12), @templateRequestID) + ' not found'
            If @showDebugStatements > 0
                Print @message

            RAISERROR (@message, 11, 10)
        End

        Set @comment = @comment + ' using request ' + Convert(varchar(12), @templateRequestID)

        If @showDebugStatements > 0
            Print @comment

        If IsNull(@workPackage, 'none') = 'none'
        Begin
            If @showDebugStatements > 0
                Print 'Calling get_wp_for_eus_proposal with proposal ' + @eusProposalID

            EXEC get_wp_for_eus_proposal @eusProposalID, @workPackage Output

            If @showDebugStatements > 0
                Print 'get_wp_for_eus_proposal returned work package' + @workPackage
        End

    End

    ---------------------------------------------------
    -- Set up EUS parameters
    ---------------------------------------------------

    IF ISNULL(@templateRequestID, 0) = 0
        RAISERROR ('For now, a template request is mandatory', 11, 10)

    if IsNull(@callingUser, '') <> ''
        Set @requesterUsername = @callingUser

    ---------------------------------------------------
    -- Create requested run and attach it to dataset
    ---------------------------------------------------

    Declare @addUpdateMode varchar(12)

    If @mode = 'preview'
    Begin
        Set @addUpdateMode = 'check-add'

        Print 'Request_Name: ' + @reqName
        Print 'Experiment: ' + @experimentName
        Print 'RequesterUsername: ' + @requesterUsername
        Print 'InstrumentName: ' + @instrumentName
        Print 'WorkPackage: ' + @workPackage
        Print 'MsType: ' + @msType
        Print 'InstrumentSettings: ' + 'na'
        Print 'WellplateName: Null'
        Print 'WellNumber: Null'
        Print 'InternalStandard: ' + 'na'
        Print 'Comment: ' + @comment
        Print 'EusProposalID: ' + @eusProposalID
        Print 'EusUsageType: ' + @eusUsageType
        Print 'EusUsersList: ' + @eusUsersList
        Print 'Mode: ' + @addUpdateMode
        Print 'SecSep: ' + @secSep
        Print 'MRMAttachment: ' + ''
        Print 'Status: ' + 'Completed'
        Print 'SkipTransactionRollback: 1'
        Print 'AutoPopulateUserListIfBlank: 1'
        Print 'CallingUser: ' + @callingUser
    End
    Else
    Begin
        Set @addUpdateMode = 'add-auto'
    End

    If @showDebugStatements > 0
        Print 'Calling add_update_requested_run with mode ' + @addUpdateMode

    EXEC @myError = dbo.add_update_requested_run
                            @reqName = @reqName,
                            @experimentName = @experimentName,
                            @requesterUsername = @requesterUsername,
                            @instrumentName = @instrumentName,
                            @workPackage = @workPackage,
                            @msType = @msType,
                            @instrumentSettings = 'na',
                            @wellplateName = NULL,
                            @wellNumber = NULL,
                            @internalStandard = 'na',
                            @comment = @comment,
                            @eusProposalID = @eusProposalID,
                            @eusUsageType = @eusUsageType,
                            @eusUsersList = @eusUsersList,
                            @mode = @addUpdateMode,
                            @request = @request output,
                            @message = @msg output,
                            @secSep = @secSep,
                            @MRMAttachment = '',
                            @status = 'Completed',
                            @SkipTransactionRollback = 1,
                            @AutoPopulateUserListIfBlank = 1,        -- Auto populate @eusUsersList if blank since this is an Auto-Request
                            @callingUser = @callingUser

    if @myError <> 0
        RAISERROR (@msg, 11, 6)

    IF @request = 0
        RAISERROR('Created request with ID = 0', 11, 7)

    If @showDebugStatements > 0
        Print 'add_update_requested_run reported that it created Request ID ' + Cast(@request As Varchar(12))

    If @addUpdateMode = 'add-auto'
    Begin
        ---------------------------------------------------
        -- Consume the requested run
        ---------------------------------------------------

        If @showDebugStatements > 0
            Print 'Calling consume_scheduled_run with DatasetID ' + Cast(@dID As Varchar(12)) + ' and RequestID ' + Cast(@request As Varchar(12))

        exec @myError = consume_scheduled_run @dID, @request, @msg output, @callingUser
        if @myError <> 0
            RAISERROR (@msg, 11, 8)

        If @showDebugStatements > 0
            Print 'consume_scheduled_run returned message "' + @msg + '"'

    End

    ---------------------------------------------------
    -- Errors end up here
    ---------------------------------------------------

    End TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Print @message

        If @mode <> 'preview'
        Begin
            Exec post_log_entry 'Error', @message, 'add_requested_run_to_existing_dataset'
        End
    End CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_requested_run_to_existing_dataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_requested_run_to_existing_dataset] TO [DMS2_SP_User] AS [dbo]
GO

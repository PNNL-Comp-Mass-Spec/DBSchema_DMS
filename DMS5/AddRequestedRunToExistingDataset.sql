/****** Object:  StoredProcedure [dbo].[AddRequestedRunToExistingDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddRequestedRunToExistingDataset]
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
**          Note that this procedure is similar to AddMissingRequestedRun, 
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
**          11/29/2011 mem - Now auto-determining OperPRN if @callingUser is empty
**          12/14/2011 mem - Now passing @callingUser to AddUpdateRequestedRun and ConsumeScheduledRun
**          05/08/2013 mem - Now setting @wellplateNum and @wellNum to Null when calling AddUpdateRequestedRun
**          01/29/2016 mem - Now calling GetWPforEUSProposal to get the best work package for the given EUS Proposal
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/22/2017 mem - If necessary, change the prefix from AutoReq_ to AutoReq2_ or AutoReq3 to avoid conflicts
**          06/13/2017 mem - Rename @operPRN to @requestorPRN when calling AddUpdateRequestedRun
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          01/24/2020 mem - Add mode 'preview'
**          01/31/2020 mem - Display all of the values sent to AddUpdateRequestedRun when mode is 'preview'
**          02/04/2020 mem - Add mode 'add-debug', which will associate the requested run with the dataset, but will also print out debug statements
**          05/23/2022 mem - Rename @requestorPRN to @requesterPRN when calling AddUpdateRequestedRun
**    
*****************************************************/
(
    @datasetID INT = 0,                 -- Can supply ID for dataset or name for dataset (but not both)
    @datasetNum varchar(128),           -- 
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
    SET @datasetNum = ISNULL(@datasetNum, '')
    Set @mode = Ltrim(Rtrim(@mode))

    If @datasetID <> 0 AND @datasetNum <> ''
        RAISERROR ('Cannot specify both datasetID "%d" and datasetNum "%s"', 11, 3, @datasetID, @datasetNum)
    
    ---------------------------------------------------
    -- Does dataset exist?
    ---------------------------------------------------
    
    SELECT @dID = Dataset_ID,
           @dName = Dataset_Num
    FROM dbo.T_Dataset
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 And @datasetNum <> ''
    Begin
        SELECT @dID = Dataset_ID,
               @dName = Dataset_Num
        FROM dbo.T_Dataset
        WHERE Dataset_Num = @datasetNum
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    If @dID = 0
        RAISERROR ('Could not find datasetID "%d" or dataset "%s"', 11, 4, @datasetID, @datasetNum)

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
    
    Declare @experimentNum varchar(64)
    Declare @instrumentName varchar(64)
    Declare @msType varchar(20)
    Declare @comment varchar(1024) = 'Automatically created by Dataset entry'
    Declare @workPackage varchar(50)  = 'none'
    Declare @requesterPRN varchar(128) = ''
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

    SELECT @experimentNum = E.Experiment_Num,
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
               @requesterPRN = RDS_Requestor_PRN,
               @eusProposalID = RDS_EUS_Proposal_ID,
               @eusUsageType = EUT.Name,
               @eusUsersList = dbo.GetRequestedRunEUSUsersList(RR.ID, 'I')
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
                Print 'Calling GetWPforEUSProposal with proposal ' + @eusProposalID

            EXEC GetWPforEUSProposal @eusProposalID, @workPackage Output

            If @showDebugStatements > 0
                Print 'GetWPforEUSProposal returned work package' + @workPackage
        End

    End 

    ---------------------------------------------------
    -- Set up EUS parameters
    ---------------------------------------------------
    
    IF ISNULL(@templateRequestID, 0) = 0
        RAISERROR ('For now, a template request is mandatory', 11, 10)

    if IsNull(@callingUser, '') <> ''
        Set @requesterPRN = @callingUser
        
    ---------------------------------------------------
    -- Create requested run and attach it to dataset
    ---------------------------------------------------    
    
    Declare @addUpdateMode varchar(12)

    If @mode = 'preview'
    Begin
        Set @addUpdateMode = 'check-add'

        Print 'Request_Name: ' + @reqName
        Print 'Experiment: ' + @experimentNum
        Print 'RequesterPRN: ' + @requesterPRN
        Print 'InstrumentName: ' + @instrumentName
        Print 'WorkPackage: ' + @workPackage
        Print 'MsType: ' + @msType
        Print 'InstrumentSettings: ' + 'na'
        Print 'WellplateNum: Null'
        Print 'WellNum: Null'
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
        Print 'Calling AddUpdateRequestedRun with mode ' + @addUpdateMode

    EXEC @myError = dbo.AddUpdateRequestedRun 
                            @reqName = @reqName,
                            @experimentNum = @experimentNum,
                            @requesterPRN = @requesterPRN,
                            @instrumentName = @instrumentName,
                            @workPackage = @workPackage,
                            @msType = @msType,
                            @instrumentSettings = 'na',
                            @wellplateNum = NULL,
                            @wellNum = NULL,
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
        Print 'AddUpdateRequestedRun reported that it created Request ID ' + Cast(@request As Varchar(12))

    If @addUpdateMode = 'add-auto'
    Begin
        ---------------------------------------------------
        -- Consume the requested run 
        ---------------------------------------------------

        If @showDebugStatements > 0
            Print 'Calling ConsumeScheduledRun with DatasetID ' + Cast(@dID As Varchar(12)) + ' and RequestID ' + Cast(@request As Varchar(12))
            
        exec @myError = ConsumeScheduledRun @dID, @request, @msg output, @callingUser
        if @myError <> 0
            RAISERROR (@msg, 11, 8)

        If @showDebugStatements > 0
            Print 'ConsumeScheduledRun returned message "' + @msg + '"'

    End

    ---------------------------------------------------
    -- Errors end up here
    ---------------------------------------------------

    End TRY
    Begin CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
       
        Print @message

        If @mode <> 'preview'
        Begin
            Exec PostLogEntry 'Error', @message, 'AddRequestedRunToExistingDataset'
        End
    End CATCH
    
    return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[AddRequestedRunToExistingDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRequestedRunToExistingDataset] TO [DMS2_SP_User] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[add_missing_requested_run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_missing_requested_run]
/****************************************************
**
**  Desc:   Creates a requested run for the given dataset,
**          provided it doesn't already have a requested run
**
**          The requested run will be named 'AutoReq_DatasetName'
**
**
**          Note that this procedure is similar to add_requested_run_to_existing_dataset,
**          though that procedure has parameter @templateRequestID which defines
**          an existing requested run ID from which to lookup EUS information
**
**          In contrast, this procedure is intended to be run via automation
**          to add requested runs to existing datasets that don't yet have one
**
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/20/1010 mem - Initial version
**          05/08/2013 mem - Now setting @wellplateName and @wellNumber to Null when calling add_update_requested_run
**          01/29/2016 mem - Now calling get_wp_for_eus_proposal to get the best work package for the given EUS Proposal
**          06/13/2017 mem - Rename @operatorUsername to @requestorUsername when calling add_update_requested_run
**          05/23/2022 mem - Rename @requestorUsername to @requesterUsername when calling add_update_requested_run
**          11/25/2022 mem - Update call to add_update_requested_run to use new parameter name
**          01/05/2023 mem - Use new column name in V_Dataset_Detail_Report_Ex
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2023 mem - Use new argument name, @requestName
**
*****************************************************/
(
    @dataset varchar(256),
    @eusProposalID varchar(64) = '',
    @eusUsageType varchar(64) = 'CAP_DEV',
    @eusUsersList varchar(64) = '',
    @infoOnly tinyint = 1,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @experimentName varchar(256),
            @operatorUsername varchar(64),
            @instrumentName varchar(128),
            @secSep varchar(128),
            @msType varchar(64),
            @DatasetID int,
            @RequestID int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @Dataset = IsNull(@Dataset, '')
    Set @InfoOnly = IsNull(@InfoOnly, 1)
    Set @message = ''

    ---------------------------------------------------
    -- Lookup the dataset details
    ---------------------------------------------------

    SELECT @experimentName = V.Experiment,
           @operatorUsername = D.DS_Oper_PRN,
           @instrumentName = v.Instrument,
           @msType = v.Type,
           @secSep = v.Separation_Type,
           @DatasetID = D.Dataset_ID
    FROM V_Dataset_Detail_Report_Ex V
         INNER JOIN T_Dataset D
           ON V.Dataset = D.Dataset_Num
    WHERE V.Dataset = @Dataset
    --
    SELECT @myError = @@Error, @myRowCount = @@RowCount

    If @myRowCount = 0
    Begin
        Set @message = 'Error, Dataset not found: ' + @Dataset
        Set @myError = 50000
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure the dataset doesn't already have a requested run
    ---------------------------------------------------

    Set @RequestID = 0
    SELECT @RequestID = T_Requested_Run.ID
    FROM T_Requested_Run
         INNER JOIN T_Dataset
           ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
    WHERE (T_Dataset.Dataset_Num = @Dataset)
    --
    SELECT @myError = @@Error, @myRowCount = @@RowCount

    If @myRowCount > 0
    Begin
        Set @message = 'Error, Dataset is already associated with Request ' + Convert(varchar(12), @RequestID)
        Set @myError = 50001
        Goto Done
    End


    If @infoOnly <> 0
    Begin
        SELECT @DatasetID AS DatasetID,
               @Dataset AS Dataset,
               @experimentName AS Experiment,
               @operatorUsername AS Operator,
               @instrumentName AS Instrument,
               @msType AS DS_Type,
               @message AS Message
    End
    Else
    Begin
        -- Create the request

        Declare @requestName varchar(128)
        Set @requestName = 'AutoReq_' + @Dataset

        Declare @workPackage varchar(50) = 'none'
        EXEC get_wp_for_eus_proposal @eusProposalID, @workPackage OUTPUT

        Declare @result int

        EXEC @result = dbo.add_update_requested_run
                                @requestName = @requestName,
                                @experimentName = @experimentName,
                                @requesterUsername = @operatorUsername,
                                @instrumentName = @instrumentName,
                                @workPackage = @workPackage,
                                @msType = @msType,
                                @instrumentSettings = 'na',
                                @wellplateName = NULL,
                                @wellNumber = NULL,
                                @internalStandard = 'na',
                                @comment = 'Automatically created by Dataset entry',
                                @eusProposalID = @eusProposalID,
                                @eusUsageType = @eusUsageType,
                                @eusUsersList = @eusUsersList,
                                @mode = 'add-auto',
                                @request = @RequestID output,
                                @message = @message output,
                                @secSep = @secSep,
                                @MRMAttachment = '',
                                @status = 'Completed',
                                @SkipTransactionRollback = 1,
                                @AutoPopulateUserListIfBlank = 1        -- Auto populate @eusUsersList if blank since this is an Auto-Request

        If IsNull(@result, 0) > 0 Or IsNull(@RequestID, 0) = 0
        Begin
            If IsNull(@message, '') = ''
                Set @message = 'Error creating requested run'

            Set @myError = @result
            If @myError = 0
                Set @myError = 50003

            Goto Done
        End
        Else
        Begin
            UPDATE T_Requested_Run
            SET DatasetID = @DatasetID
            WHERE (ID = @RequestID)
            --
            SELECT @myError = @@Error, @myRowCount = @@RowCount

            If IsNull(@message, '') = ''
                Set @message = 'Success'

            SELECT @Dataset AS Dataset,
                   @RequestID AS RequestID,
                   @result AS Result,
                   @message AS Message

        End
    End


Done:
    If @myError <> 0
        print @message

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_missing_requested_run] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_missing_requested_run] TO [Limited_Table_Write] AS [dbo]
GO

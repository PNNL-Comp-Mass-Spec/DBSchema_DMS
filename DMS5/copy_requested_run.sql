/****** Object:  StoredProcedure [dbo].[CopyRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CopyRequestedRun]
/****************************************************
**
**  Desc:   Make copy of given requested run and associate
**          it with given dataset
**
**  Auth:   grk
**  Date:   02/26/2010
**          03/03/2010 grk - added status field
**          08/04/2010 mem - Now using the Created date from the original request as the Created date for the new request
**          08/30/2010 mem - Now clearing @message after a successful call to UpdateRequestedRunCopyFactors
**          12/13/2011 mem - Added parameter @callingUser, which is sent to UpdateRequestedRunCopyFactors
**          04/25/2012 mem - Fixed @callingUser bug when updating @callingUserUnconsume
**          02/21/2013 mem - Now verifying that a new row was added to T_Requested_Run
**          05/08/2013 mem - Now copying Vialing_Conc and Vialing_Vol
**          11/16/2016 mem - Call UpdateCachedRequestedRunEUSUsers to update T_Active_Requested_Run_Cached_EUS_Users
**          02/23/2017 mem - Add column RDS_Cart_Config_ID
**          03/07/2017 mem - Add parameter @requestNameAppendText
**                         - Assure that the newly created request has a unique name
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          01/19/2021 mem - Add parameters @requestNameOverride and @infoOnly
**          02/10/2023 mem - Call UpdateCachedRequestedRunBatchStats
**
*****************************************************/
(
    @requestID int,
    @datasetID int,
    @status varchar(24),                        -- Active, Completed, or Inactive
    @notation varchar(256),                     -- Requested run comment
    @requestNameAppendText varchar(128)='',     -- Text appended to the name of the newly created request; append nothing if null or ''
    @requestNameOverride varchar(128)='',       -- New request name to use; if blank, will be based on the existing request name, but will append @requestNameAppendText
    @message varchar(255)='' output,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @stateID int = 0
    Declare @newReqID int

    Declare @oldReqName varchar(128)
    Declare @newReqName varchar(128)

    Declare @batchID int

    Set @message = ''

    Set @requestNameAppendText = LTrim(RTrim(IsNull(@requestNameAppendText, '')))
    Set @requestNameOverride = LTrim(RTrim(IsNull(@requestNameOverride, '')))

    Set @callingUser = IsNull(@callingUser, '')
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- We are done if there is no associated request
    ---------------------------------------------------
    --
    Set @requestID = IsNull(@requestID, 0)
    if @requestID = 0
    begin
        set @message = 'Source request ID is 0; nothing to do'
        goto Done
    end

    ---------------------------------------------------
    -- Make sure the source request exists
    ---------------------------------------------------
    --
    SELECT @oldReqName = RDS_Name
    FROM T_Requested_Run
    WHERE ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myRowCount = 0
    begin
        set @message = 'Source request not found in T_Requested_Run: ' + Cast(@requestID as varchar(9))
        exec PostLogEntry 'Error', @message, 'CopyRequestedRun'
        goto Done
    end

    ---------------------------------------------------
    -- Validate @status
    ---------------------------------------------------
    --
    If Not Exists (Select * from T_Requested_Run_State_Name Where State_Name = @status)
    begin
        DECLARE @stateNameList varchar(128) = NULL

        SELECT @stateNameList = COALESCE(@stateNameList + ', ' + State_name, State_Name)
        FROM T_Requested_Run_State_Name
        ORDER BY State_ID

        set @message = 'Invalid status: ' + @status + '; valid states are ' + @stateNameList
        exec PostLogEntry 'Error', @message, 'CopyRequestedRun'
        goto Done
    end

    SELECT @stateID = State_ID
    FROM T_Requested_Run_State_Name
    WHERE State_Name = @status
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Determine the name for the new request
    -- Note that @requestNameAppendText may be blank
    ---------------------------------------------------
    --
    Declare @continue tinyint = 1
    Declare @iteration int = 1

    If @requestNameOverride = ''
    Begin
        Set @newReqName = @oldReqName + @requestNameAppendText
    End
    Else
    Begin
        Set @newReqName = @requestNameOverride
    End

    While @continue = 1
    Begin
        If Not Exists (Select * From T_Requested_Run Where RDS_Name = @newReqName)
        Begin
            Set @continue = 0
        End
        Else
        Begin
            Set @iteration = @iteration + 1
            Set @newReqName = @oldReqName + @requestNameAppendText + Cast(@iteration as varchar(9))
        End

    End

    If @infoOnly <> 0
    Begin
        SELECT
            ID As Source_Request_ID,
            RDS_Name As Source_Request_Name,
            @newReqName as New_Request_Name,
            @notation as Comment,
            RDS_Requestor_PRN,
            RDS_created,                -- Pass along the original request's "created" date into the new entry
            RDS_instrument_group,
            RDS_type_ID,
            RDS_instrument_setting,
            RDS_special_instructions,
            RDS_Well_Plate_Num,
            RDS_Well_Num,
            Vialing_Conc,
            Vialing_Vol,
            RDS_priority,
            RDS_note,
            Exp_ID,
            RDS_Run_Start,
            RDS_Run_Finish,
            RDS_internal_standard,
            RDS_WorkPackage,
            RDS_BatchID,
            RDS_Blocking_Factor,
            RDS_Block,
            RDS_Run_Order,
            RDS_EUS_Proposal_ID,
            RDS_EUS_UsageType,
            RDS_Cart_ID,
            RDS_Cart_Config_ID,
            RDS_Cart_Col,
            RDS_Sec_Sep,
            RDS_MRM_Attachment,
            @status,
            'auto',
            CASE WHEN ISNULL(@datasetID, 0) = 0 THEN NULL ELSE @datasetID END
        FROM T_Requested_Run
        WHERE ID = @requestID

        Goto Done
    End

    ---------------------------------------------------
    -- Make copy
    ---------------------------------------------------
    --
    -- make new request
    --
    INSERT INTO T_Requested_Run
    (
        RDS_comment,
        RDS_Name,
        RDS_Requestor_PRN,
        RDS_created,
        RDS_instrument_group,
        RDS_type_ID,
        RDS_instrument_setting,
        RDS_special_instructions,
        RDS_Well_Plate_Num,
        RDS_Well_Num,
        Vialing_Conc,
        Vialing_Vol,
        RDS_priority,
        RDS_note,
        Exp_ID,
        RDS_Run_Start,
        RDS_Run_Finish,
        RDS_internal_standard,
        RDS_WorkPackage,
        RDS_BatchID,
        RDS_Blocking_Factor,
        RDS_Block,
        RDS_Run_Order,
        RDS_EUS_Proposal_ID,
        RDS_EUS_UsageType,
        RDS_Cart_ID,
        RDS_Cart_Config_ID,
        RDS_Cart_Col,
        RDS_Sec_Sep,
        RDS_MRM_Attachment,
        RDS_Status,
        RDS_Origin,
        DatasetID
    )
    SELECT
        @notation,
        @newReqName,
        RDS_Requestor_PRN,
        RDS_created,                -- Pass along the original request's "created" date into the new entry
        RDS_instrument_group,
        RDS_type_ID,
        RDS_instrument_setting,
        RDS_special_instructions,
        RDS_Well_Plate_Num,
        RDS_Well_Num,
        Vialing_Conc,
        Vialing_Vol,
        RDS_priority,
        RDS_note,
        Exp_ID,
        RDS_Run_Start,
        RDS_Run_Finish,
        RDS_internal_standard,
        RDS_WorkPackage,
        RDS_BatchID,
        RDS_Blocking_Factor,
        RDS_Block,
        RDS_Run_Order,
        RDS_EUS_Proposal_ID,
        RDS_EUS_UsageType,
        RDS_Cart_ID,
        RDS_Cart_Config_ID,
        RDS_Cart_Col,
        RDS_Sec_Sep,
        RDS_MRM_Attachment,
        @status,
        'auto',
        CASE WHEN ISNULL(@datasetID, 0) = 0 THEN NULL ELSE @datasetID END
    FROM T_Requested_Run
    WHERE ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    Set @newReqID = SCOPE_IDENTITY()
    --
    if @myError <> 0
    begin
        set @message = 'Problem trying to renumber request in history; @myError = ' + Convert(varchar(12), @myError)
        exec PostLogEntry 'Error', @message, 'CopyRequestedRun'
        goto Done
    end
    --
    if @myRowCount = 0
    begin
        If Not Exists (Select * from T_Requested_Run Where ID = @requestID)
            set @message = 'Problem trying to renumber request in history; RequestID not found: ' + Convert(varchar(12), @requestID)
        else
            Set @message = 'Problem trying to renumber request in history; No rows added for RequestID ' + Convert(varchar(12), @requestID)

        exec PostLogEntry 'Error', @message, 'CopyRequestedRun'
        goto Done
    end

    If Len(@callingUser) > 0
    Begin
        Exec AlterEventLogEntryUser 11, @newReqID, @stateID, @callingUser
    End

    ------------------------------------------------------------
    -- Copy factors from the request being unconsumed to the
    -- renumbered copy being retained in the history
    ------------------------------------------------------------
    --
    -- First define the calling user text
    --
    declare @callingUserUnconsume varchar(128)

    If IsNull(@callingUser, '') <> ''
        set @callingUserUnconsume = '(unconsume for ' + @callingUser + ')'
    else
        set @callingUserUnconsume = '(unconsume)'

    -- Now copy the factors
    --
    EXEC @myError = UpdateRequestedRunCopyFactors
                        @requestID,
                        @newReqID,
                        @message OUTPUT,
                        @callingUserUnconsume
    --
    if @myError <> 0
    begin
        set @message = 'Problem copying factors to new request; @myError = ' + Convert(varchar(12), @myError)
        exec PostLogEntry 'Error', @message, 'CopyRequestedRun'
        goto Done
    end
    else
    begin
        -- @message may contain the text 'Nothing to copy'
        -- We don't need that text appearing on the web page, so we'll clear @message
        set @message = ''
    end

    ---------------------------------------------------
    -- Copy proposal users for new auto request
    -- from original request
    ---------------------------------------------------
    --
    INSERT INTO T_Requested_Run_EUS_Users
        (EUS_Person_ID, Request_ID)
    SELECT
        EUS_Person_ID, @newReqID
    FROM
        T_Requested_Run_EUS_Users
    WHERE
        Request_ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Problem trying to copy EUS users; @myError = ' + Convert(varchar(12), @myError)
        exec PostLogEntry 'Error', @message, 'CopyRequestedRun'
        goto Done
    end


    ---------------------------------------------------
    -- Make sure that T_Active_Requested_Run_Cached_EUS_Users is up-to-date
    ---------------------------------------------------

    exec UpdateCachedRequestedRunEUSUsers @newReqID


    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    SELECT @batchID = RDS_BatchID
    FROM T_Requested_Run
    WHERE ID = @requestID

    If @batchID > 0
    Begin
        Exec UpdateCachedRequestedRunBatchStats @batchID
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CopyRequestedRun] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO

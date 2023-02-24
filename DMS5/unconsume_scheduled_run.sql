/****** Object:  StoredProcedure [dbo].[unconsume_scheduled_run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[unconsume_scheduled_run]
/****************************************************
**
**  Desc:
**      The intent is to recycle user-entered requests
**      (where appropriate) and make sure there is
**      a requested run for each dataset (unless
**      dataset is being deleted).
**
**      Disassociates the currently-associated requested run
**      from the given dataset if the requested run was
**      user-entered (as opposted to automatically created
**      when dataset was created with requestID = 0).
**
**      If original requested run was user-entered and @retainHistory
**      flag is set, copy the original requested run to a
**      new one and associate that one with the given dataset.
**
**      If the given dataset is to be deleted, the @retainHistory flag
**      must be clear, otherwise a foreign key constraint will fail
**      when the attempt to delete the dataset is made and the associated
**      request is still hanging around.
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   3/1/2004 grk - Initial release
**          01/13/2006 grk - Handling for new blocking columns in request and history tables.
**          01/17/2006 grk - Handling for new EUS tracking columns in request and history tables.
**          03/10/2006 grk - Fixed logic to handle absence of associated request
**          03/10/2006 grk - Fixed logic to handle null batchID on old requests
**          05/01/2007 grk - Modified logic to optionally retain original history (Ticket #446)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          04/08/2008 grk - Added handling for separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          02/24/2010 grk - Added handling for requested run factors
**          02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**          03/02/2010 grk - added status field to requested run
**          08/04/2010 mem - No longer updating the "date created" date for the recycled request
**          12/13/2011 mem - Added parameter @callingUser, which is sent to copy_requested_run, alter_event_log_entry_user, and delete_requested_run
**          02/20/2013 mem - Added ability to lookup the original request from an auto-created recycled request
**          02/21/2013 mem - Now validating that the RequestID extracted from "Automatically created by recycling request 12345" actually exists
**          05/08/2013 mem - Removed parameters @wellplateNum and @wellNum since no longer used
**          07/08/2014 mem - Now checking for empty requested run comment
**          03/22/2016 mem - Now passing @skipDatasetCheck to delete_requested_run
**          11/16/2016 mem - Call update_cached_requested_run_eus_users to update T_Active_Requested_Run_Cached_EUS_Users
**          03/07/2017 mem - Append _Recycled to new requests created when @recycleRequest is yes
**                         - Remove leading space in message ' (recycled from dataset ...'
**          06/12/2018 mem - Send @maxLength to append_to_text
**          06/14/2019 mem - Change cart to Unknown when making the request active again
**          10/23/2021 mem - If recycling a request with queue state 3 (Analyzed), change the queue state to 2 (Assigned)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(128),
    @retainHistory tinyint = 0,
    @message varchar(1024) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    set @message = IsNull(@message, '')

    ---------------------------------------------------
    -- get datasetID
    ---------------------------------------------------
    Declare @datasetID int = 0
    --
    SELECT @datasetID = Dataset_ID
    FROM T_Dataset
    WHERE (Dataset_Num = @datasetName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Could not get Id or state for dataset "' + @datasetName + '"'
        return 51140
    end
    --
    if @datasetID = 0
    begin
        set @message = 'Dataset does not exist"' + @datasetName + '"'
        return 51141
    end

    ---------------------------------------------------
    -- Look for associated request for dataset
    ---------------------------------------------------
    Declare @requestComment varchar(1024) = ''
    Declare @requestID Int = 0
    Declare @requestOrigin char(4)
    Declare @currentQueueState Tinyint     -- 1=Unassigned, 2=Assigned, 3=Analyzed

    Declare @requestIDOriginal int = 0
    Declare @copy_requested_run tinyint = 0
    Declare @recycleOriginalRequest tinyint = 0

    SELECT @requestID = ID,
           @requestComment = RDS_comment,
           @requestOrigin = RDS_Origin,
           @currentQueueState = Queue_State
    FROM T_Requested_Run
    WHERE DatasetID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Problem trying to find associated requested run for dataset'
        return 51006
    end

    ---------------------------------------------------
    -- We are done if there is no associated request
    ---------------------------------------------------
    if @requestID = 0
    begin
        return 0
    end

    ---------------------------------------------------
    -- Was request automatically created by dataset entry?
    ---------------------------------------------------
    --
    Declare @autoCreatedRequest int = 0

    If @requestOrigin = 'auto'
    Begin
        set @autoCreatedRequest = 1
    End

    ---------------------------------------------------
    -- Determine the ID of the "unknown" cart
    ---------------------------------------------------

    Declare @newCartID Int = null
    Declare @warningMessage Varchar(128)

    SELECT @newCartID = ID
    FROM   T_LC_Cart
    WHERE Cart_Name = 'unknown'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount < 1
    Begin
        Set @warningMessage = 'Could not find the cart named "unknown" in T_LC_Cart; the Cart ID of the recycled requested run will be left unchanged'
        Exec post_log_entry 'Error', @warningMessage, 'unconsume_scheduled_run'
    End

    ---------------------------------------------------
    -- start transaction
    ---------------------------------------------------
    Declare @notation varchar(256)
    Declare @addnlText varchar(1024)

    Declare @transName varchar(32)
    set @transName = 'unconsume_scheduled_run'
    begin transaction @transName

    ---------------------------------------------------
    -- Reset request
    -- if it was not automatically created
    ---------------------------------------------------

    if @autoCreatedRequest = 0
    BEGIN -- <a1>
        ---------------------------------------------------
        -- original request was user-entered,
        -- We will copy it (if commanded to) and set status to 'Completed'
        ---------------------------------------------------
        --
        Set @requestIDOriginal = @requestID
        Set @recycleOriginalRequest = 1

        If @retainHistory = 1
        Begin
            Set @copy_requested_run = 1
        End

    END -- </a1>
    ELSE
    BEGIN -- <a2>
        ---------------------------------------------------
        -- original request was auto created
        -- delete it (if commanded to)
        ---------------------------------------------------
        --
        if @retainHistory = 0
        BEGIN -- <b2>
            EXEC @myError = delete_requested_run
                                 @requestID,
                                 @skipDatasetCheck=1,
                                 @message=@message OUTPUT,
                                 @callingUser=@callingUser

            --
            if @myError <> 0
            begin
                rollback transaction @transName
                return 51052
            end
        END -- </b2>
        Else
        Begin -- <b3>

            ---------------------------------------------------
            -- original request was auto-created
            -- Examine the request comment to determine if it was a recycled request
            ---------------------------------------------------
            --
            If @requestComment Like '%Automatically created by recycling request [0-9]%[0-9] from dataset [0-9]%'
            Begin -- <c>

                -- Determine the original request ID
                --
                Declare @charIndex int
                Declare @extracted varchar(1024)
                Declare @originalRequestStatus varchar(32) = ''
                Declare @originalRequesetDatasetID int = 0

                Set @charIndex = CHARINDEX('by recycling request', @requestComment)

                If @charIndex > 0
                Begin -- <d>
                    Set @extracted = LTRIM(SUBSTRING(@requestComment, @charIndex + LEN('by recycling request'), 20))

                    -- Comment is now of the form: "286793 from dataset"
                    -- Find the space after the number
                    --
                    Set @charIndex = CHARINDEX(' ', @extracted)

                    If @charIndex > 0
                    Begin -- <e>
                        Set @extracted = LTRIM(RTRIM(SUBSTRING(@extracted, 1, @charindex)))

                        -- Original requested ID has been determined; copy the original request
                        --
                        Set @requestIDOriginal = Convert(int, @extracted)
                        Set @recycleOriginalRequest = 1

                        -- Make sure the original request actually exists
                        IF Not Exists (SELECT * FROM T_Requested_Run WHERE ID = @requestIDOriginal)
                        Begin
                            -- Original request doesn't exist; recycle this recycled one
                            Set @requestIDOriginal = @requestID
                        End

                        -- Make sure that the original request is not active
                        -- In addition, lookup the dataset ID of the original request

                        SELECT @originalRequestStatus = RDS_Status,
                               @originalRequesetDatasetID = DatasetID
                        FROM T_Requested_Run
                        WHERE ID = @requestIDOriginal

                        If @originalRequestStatus = 'Active'
                        Begin
                            -- The original request is active, don't recycle anything

                            If @requestIDOriginal = @requestID
                            Begin
                                Set @addnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' for dataset ' + @datasetName + ' since it is already active'
                                Exec post_log_entry 'Warning', @addnlText, 'unconsume_scheduled_run'

                                Set @addnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' since it is already active'
                                Set @message = dbo.append_to_text(@message, @addnlText, 0, '; ', 1024)
                            End
                            Else
                            Begin
                                Set @addnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' for dataset ' + @datasetName + ' since dataset already has an active request (' + @extracted + ')'
                                Exec post_log_entry 'Warning', @addnlText, 'unconsume_scheduled_run'

                                Set @addnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' since dataset already has an active request (' + @extracted + ')'
                                Set @message = dbo.append_to_text(@message, @addnlText, 0, '; ', 1024)
                            End

                            Set @requestIDOriginal = 0
                        End
                        Else
                        Begin
                            Set @copy_requested_run = 1
                            Set @datasetID = @originalRequesetDatasetID
                        End

                    End -- </e>
                End -- </d>
            End -- </c>
            Else
            Begin
                Set @addnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' for dataset ' + @datasetName + ' since AutoRequest'
                Set @message = dbo.append_to_text(@message, @addnlText, 0, '; ', 1024)
            End

        End -- </b3>

    END -- <a2>

    If @requestIDOriginal > 0 And @copy_requested_run = 1
    BEGIN -- <a3>

        ---------------------------------------------------
        -- Copy the request and associate the dataset with the newly created request
        ---------------------------------------------------
        --
        -- Warning: The text "Automatically created by recycling request" is used earlier in this stored procedure; thus, do not update it here
        --
        Set @notation = 'Automatically created by recycling request ' + cast(@requestIDOriginal as varchar(12)) + ' from dataset ' + cast(@datasetID as varchar(12)) + ' on ' + CONVERT (varchar(12), getdate(), 101)

        Declare @requestNameAppendText varchar(128) = '_Recycled'

        EXEC @myError = copy_requested_run
                            @requestIDOriginal,
                            @datasetID,
                            'Completed',
                            @notation,
                            @requestNameAppendText = @requestNameAppendText,
                            @message = @message output,
                            @callingUser = @callingUser
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            return @myError
        end
    END -- </a3>

    If @requestIDOriginal > 0 And @recycleOriginalRequest = 1
    Begin -- <a4>

        ---------------------------------------------------
        -- Recycle the original request
        ---------------------------------------------------
        --
        -- Create annotation to be appended to comment
        --
        set @notation = '(recycled from dataset ' + cast(@datasetID as varchar(12)) + ' on ' + CONVERT (varchar(12), getdate(), 101) + ')'
        if len(@requestComment) + len(@notation) > 1024
        begin
            -- Dataset comment could become too long; do not append the additional note
            set @notation = ''
        end

        -- Reset the requested run to 'Active'
        -- Do not update RDS_Created; we want to keep it as the original date for planning purposes
        --
        Declare @newStatus varchar(24) = 'Active'
        Declare @newQueueState tinyint

        If @currentQueueState In (2,3)
            Set @newQueueState = 2      -- Assigned
        Else
            Set @newQueueState = 1      -- Unassigned

        Update T_Requested_Run
        SET
            RDS_Status = @newStatus,
            RDS_Run_Start = NULL,
            RDS_Run_Finish = NULL,
            DatasetID = NULL,
            RDS_comment = CASE WHEN IsNull(RDS_Comment, '') = '' THEN @notation ELSE RDS_comment + ' ' + @notation End,
            RDS_Cart_ID = IsNull(@newCartID, RDS_Cart_ID),
            Queue_State = @newQueueState
        WHERE
            ID = @requestIDOriginal
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Problem trying reset request'
            rollback transaction @transName
            return 51007
        end

        If Len(@callingUser) > 0
        Begin
            Declare @stateID int = 0

            SELECT @stateID = State_ID
            FROM T_Requested_Run_State_Name
            WHERE (State_Name = @newStatus)

            Exec alter_event_log_entry_user 11, @requestIDOriginal, @stateID, @callingUser
        End

        ---------------------------------------------------
        -- Make sure that T_Active_Requested_Run_Cached_EUS_Users is up-to-date
        ---------------------------------------------------
        --
        exec update_cached_requested_run_eus_users @requestIDOriginal

    End -- </a4>

    ---------------------------------------------------
    -- Commit the changes
    ---------------------------------------------------

    commit transaction @transName
    return 0

GO
GRANT EXECUTE ON [dbo].[unconsume_scheduled_run] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[unconsume_scheduled_run] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[unconsume_scheduled_run] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[unconsume_scheduled_run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[unconsume_scheduled_run] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[update_requested_run_assignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_assignments]
/****************************************************
**
**  Desc:
**      Update the specified requested runs to change priority, instrument group, separation group, dataset type, or assigned instrument
**
**      This procedure is called via two mechanisms:
**
**      1) Via POST calls to requested_run/operation/ , originating from https://dms2.pnl.gov/requested_run_admin/report
**         - See file requested_run_admin_cmds.php at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/master/application/views/cmd/requested_run_admin_cmds.php
**           and file lcmd.js at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/d2eab881133cfe4c71f17b06b09f52fc4e61c8fb/javascript/lcmd.js#L225
**
**      2) When the user clicks "Delete this request" or "Convert Request Into Fractions" at the bottom of a Requested Run Detail report
**         - See the detail_report_commands and sproc_args sections at https://dms2.pnl.gov/config_db/show_db/requested_run.db
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/26/2003
**          12/11/2003 grk - Removed LCMS cart modes
**          07/27/2007 mem - When @mode = 'instrument, then checking dataset type (@datasetTypeName) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #503)
**                         - Added output parameter @message to report the number of items updated
**          09/16/2009 mem - Now checking dataset type (@datasetTypeName) using Instrument_Allowed_Dataset_Type table (Ticket #748)
**          08/28/2010 mem - Now auto-switching @newValue to be instrument group instead of instrument name (when @mode = 'instrument')
**                         - Now validating dataset type for instrument using T_Instrument_Group_Allowed_DS_Type
**                         - Added try-catch for error handling
**          09/02/2011 mem - Now calling post_usage_log_entry
**          12/12/2011 mem - Added parameter @callingUser, which is passed to delete_requested_run
**          06/26/2013 mem - Added mode 'instrumentIgnoreType' (doesn't validate dataset type when changing the instrument group)
**                         - Added mode 'datasetType'
**          07/24/2013 mem - Added mode 'separationGroup'
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/22/2016 mem - Now passing @skipDatasetCheck to delete_requested_run
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/31/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Do not log an error when a requested run cannot be deleted because it is associated with a dataset
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/01/2019 mem - Change argument @reqRunIDList from varchar(2048) to varchar(max)
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          10/20/2020 mem - Rename mode 'instrument' to 'instrumentGroup'
**                         - Rename mode 'instrumentIgnoreType' to 'instrumentGroupIgnoreType'
**                         - Add mode 'assignedInstrument'
**          02/04/2021 mem - Provide a delimiter when calling get_instrument_group_dataset_type_list
**          01/13/2023 mem - Refactor instrument group validation code into validate_instrument_group_for_requested_runs
**                         - Validate the instrument group for modes 'instrumentGroup' and 'assignedInstrument'
**          01/15/2023 mem - Fix variable usage typo
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**          01/23/2024 mem - When updating the instrument group, block the update if it would result in a mix of instrument groups for any of the batches associated with the requested runs
**
*****************************************************/
(
    @mode varchar(32),                  -- 'priority', 'instrumentGroup', 'instrumentGroupIgnoreType', 'assignedInstrument', 'datasetType', 'delete', 'separationGroup'
    @newValue varchar(512),
    @reqRunIDList varchar(max),         -- Comma separated list of requested run IDs
    @message varchar(512)='' output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(1024)
    Declare @continue int
    Declare @requestID int

    Declare @newInstrumentGroup varchar(64) = ''
    Declare @newSeparationGroup varchar(64) = ''

    Declare @newAssignedInstrumentID int = 0;
    Declare @newQueueState int = 0

    Declare @newDatasetType varchar(64) = ''
    Declare @newDatasetTypeID int = 0

    Declare @batch int
    Declare @instrumentGroupCount int

    Declare @instrumentGroups varchar(512)
    Declare @requestIDs varchar(512)
    Declare @requestedRunDesc varchar(24)

    Declare @requestCount int = 0
    Declare @returnCode varchar(64) = ''

    Declare @logErrors tinyint = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_requested_run_assignments', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        -- Uncomment to log the values of the procedure arguments in T_Log_Entries
        --
        -- Set @msg = 'Procedure called with @mode=' + Coalesce(@mode, '??') + ', @newValue=' + Coalesce(@newValue, '??') + ', @reqRunIDList=' + Coalesce(@reqRunIDList, '??')
        -- exec post_log_entry 'Debug', @msg, 'update_requested_run_assignments'

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        Set @mode =         Ltrim(RTrim(Lower(IsNull(@mode, ''))));
        Set @newValue =     Ltrim(Rtrim(IsNull(@newValue, '')))
        Set @reqRunIDList = Ltrim(Rtrim(IsNull(@reqRunIDList, '')))

        ---------------------------------------------------
        -- Populate a temporary table with the values in @reqRunIDList
        ---------------------------------------------------

        CREATE TABLE #Tmp_RequestIDs (
            RequestID int
        )

        INSERT INTO #Tmp_RequestIDs (RequestID)
        SELECT Convert(int, Item)
        FROM make_table_from_list(@reqRunIDList)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @returnCode = 'U5101'
            RAISERROR ('Error parsing Request ID List', 11, 1)
        End

        If @myRowCount = 0
        Begin
            -- @reqRunIDList was empty; nothing to do
            Set @returnCode = 'U5102'
            RAISERROR ('Request ID list was empty; nothing to do', 11, 2)
        End

        Set @requestCount = @myRowCount

        -- Initial validation checks are complete; now enable @logErrors
        Set @logErrors = 1

        If @mode IN ('instrumentGroup', 'instrumentGroupIgnoreType')
        Begin -- <InstGroup>

            ---------------------------------------------------
            -- Validate the instrument group
            -- Note that as of 6/26/2013 mode 'instrument' does not appear to be used by the DMS website
            -- This unused mode was renamed to 'instrumentGroup' in October 2020
            -- Mode 'instrumentGroupIgnoreType' is used by http://dms2.pnl.gov/requested_run_admin/report
            ---------------------------------------------------
            --
            -- Set the instrument group to @newValue for now
            Set @newInstrumentGroup = @newValue

            IF NOT EXISTS (SELECT IN_Group FROM T_Instrument_Group WHERE IN_Group = @newInstrumentGroup)
            Begin
                -- Try to update instrument group using T_Instrument_Name
                SELECT @newInstrumentGroup = IN_Group
                FROM T_Instrument_Name
                WHERE IN_Name = @newValue
            End

            ---------------------------------------------------
            -- Make sure a valid instrument group was chosen (or auto-selected via an instrument name)
            -- This also assures the text is properly capitalized
            ---------------------------------------------------

            SELECT @newInstrumentGroup = IN_Group
            FROM T_Instrument_Group
            WHERE IN_Group = @newInstrumentGroup
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @logErrors = 0
                Set @returnCode = 'U5103'
                RAISERROR ('Could not find entry in database for instrument group (or instrument) "%s"', 11, 3, @newValue)
            End

            If @mode = 'instrumentGroup'
            Begin
                ---------------------------------------------------
                -- Make sure the dataset type defined for each of the requested runs
                -- is appropriate for instrument group @newInstrumentGroup
                ---------------------------------------------------

                Exec validate_instrument_group_for_requested_runs @reqRunIDList, @newInstrumentGroup, @message = @message output, @returnCode = @returnCode output

                If @returnCode <> ''
                Begin
                    Set @logErrors = 0
                    RAISERROR (@message, 11, 4)
                End

            End

            ---------------------------------------------------
            -- Make sure that the instrument group change will not result in a mix of instrument groups for active requested runs that are associated with a batch
            ---------------------------------------------------

            CREATE TABLE #Tmp_BatchIDs (
                Batch_ID int
            )

            INSERT INTO #Tmp_BatchIDs (Batch_ID)
            SELECT DISTINCT RR.RDS_BatchID
            FROM T_Requested_Run RR
                 INNER JOIN #Tmp_RequestIDs
                   ON #Tmp_RequestIDs.RequestID = RR.ID
            WHERE RR.RDS_BatchID > 0
            ORDER BY RR.RDS_BatchID

            Set @batch = 0
            Set @continue = 1

            While @continue = 1
            Begin -- <a>
                SELECT TOP 1 @batch = Batch_ID
                FROM #Tmp_BatchIDs
                WHERE Batch_ID > @batch
                ORDER BY Batch_ID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @continue = 0
                Else
                Begin

                    SELECT @instrumentGroupCount = COUNT(DISTINCT InstGroup)
                    FROM (SELECT DISTINCT RR.RDS_Instrument_Group AS InstGroup
                          FROM T_Requested_Run RR
                               LEFT OUTER JOIN #Tmp_RequestIDs
                                 ON #Tmp_RequestIDs.RequestID = RR.ID
                          WHERE RR.RDS_BatchID = @batch AND
                                RR.RDS_Status = 'Active' AND
                                #Tmp_RequestIDs.RequestID Is Null
                          UNION
                          SELECT @newInstrumentGroup As InstGroup
                         ) UnionQ

                    If @instrumentGroupCount > 1
                    Begin
                        Set @instrumentGroups = Null

                        SELECT @instrumentGroups = Coalesce(@instrumentGroups + ', ', '') + InstGroup
                        FROM ( SELECT DISTINCT RR.RDS_Instrument_Group AS InstGroup
                               FROM T_Requested_Run RR
                                    LEFT OUTER JOIN #Tmp_RequestIDs
                                      ON #Tmp_RequestIDs.RequestID = RR.ID
                               WHERE RR.RDS_BatchID = @batch AND
                                     RR.RDS_Status = 'Active' AND
                                     #Tmp_RequestIDs.RequestID Is Null
                             ) DistinctQ

                        Set @requestIDs = Null

                        SELECT @requestIDs = Coalesce(@requestIDs + ', ', '') + Cast(RR.ID As varchar(12))
                        FROM T_Requested_Run RR
                             INNER JOIN #Tmp_RequestIDs
                               ON #Tmp_RequestIDs.RequestID = RR.ID
                        WHERE RR.RDS_BatchID = @batch AND
                              RR.RDS_Status = 'Active'

                        If Len(@requestIDs) > 100
                        Begin
                            Set @requestIDs = RTrim(Left(@requestIDs, 100))

                            If @requestIDs Like '%,'
                                Set @requestIDs = RTrim(Left(@requestIDs, Len(@requestIDs) - 1))

                            Set @requestIDs = @requestIDs + ' ...'
                        End

                        Set @requestedRunDesc = 'requested run' + CASE WHEN @requestIDs LIKE '%,%' THEN 's' ELSE '' END

                        Set @message = 'Cannot set the instrument group to ' + @newInstrumentGroup + ' for ' + @requestedRunDesc +
                                       ' ' + @requestIDs + ' since that would result in a mix of instrument groups for batch ' + Cast(@batch AS varchar(12)) +
                                       ' (which corresponds to ' + @instrumentGroups + ');' +
                                       ' either update the instrument group for all active requests in the batch or create a new batch for the ' + @requestedRunDesc

                        Set @logErrors = 0
                        Set @returnCode = 'U5105'
                        RAISERROR (@message, 11, 5)
                    End
                End
            End -- </a>
        End -- </InstGroup>

        If @mode IN ('assignedInstrument')
        Begin
            If @newValue = ''
            Begin
                -- Unassign the instrument
                Set @newQueueState = 1
            End
            Else
            Begin
                ---------------------------------------------------
                -- Determine the Instrument ID and group of the selected instrument
                ---------------------------------------------------
                --
                SELECT @newAssignedInstrumentID = Instrument_ID,
                       @newInstrumentGroup = IN_Group
                FROM T_Instrument_Name
                WHERE IN_Name = @newValue
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    Set @logErrors = 0
                    Set @returnCode = 'U5106'
                    RAISERROR ('Could not find entry in database for instrument "%s"', 11, 6, @newValue)
                End

                Set @newQueueState = 2

                ---------------------------------------------------
                -- Make sure the dataset type defined for each of the requested runs
                -- is appropriate for instrument group @newInstrumentGroup
                ---------------------------------------------------

                Exec validate_instrument_group_for_requested_runs @reqRunIDList, @newInstrumentGroup, @message = @message output, @returnCode = @returnCode output

                If @returnCode <> ''
                Begin
                    Set @logErrors = 0
                    RAISERROR (@message, 11, 7)
                End

            End
        End

        If @mode IN ('separationGroup')
        Begin

            ---------------------------------------------------
            -- Validate the separation group
            -- Mode 'separationGroup' is used by http://dms2.pnl.gov/requested_run_admin/report
            ---------------------------------------------------
            --
            -- Set the separation group to @newValue for now
            Set @newSeparationGroup = @newValue

            IF NOT EXISTS (SELECT * FROM T_Separation_Group WHERE Sep_Group = @newSeparationGroup)
            Begin
                -- Try to update Separation group using T_Secondary_Sep
                SELECT @newSeparationGroup = Sep_Group
                FROM T_Secondary_Sep
                WHERE SS_name = @newValue
            End

            ---------------------------------------------------
            -- Make sure a valid separation group was chosen (or auto-selected via a separation name)
            -- This also assures the text is properly capitalized
            ---------------------------------------------------

            SELECT @newSeparationGroup = Sep_Group
            FROM T_Separation_Group
            WHERE Sep_Group = @newSeparationGroup
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @logErrors = 0
                Set @returnCode = 'U5108'
                RAISERROR ('Could not find entry in database for separation group "%s"', 11, 8, @newValue)
            End

        End


        If @mode IN ('datasetType')
        Begin

            ---------------------------------------------------
            -- Validate the dataset type
            -- Mode 'datasetType' is used by http://dms2.pnl.gov/requested_run_admin/report
            ---------------------------------------------------
            --
            -- Set the dataset type to @newValue for now
            Set @newDatasetType = @newValue

            ---------------------------------------------------
            -- Make sure a valid dataset type was chosen
            ---------------------------------------------------

            SELECT @newDatasetType = DST_name,
                   @newDatasetTypeID = DST_Type_ID
            FROM T_Dataset_Type_Name
            WHERE (DST_name = @newDatasetType)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @logErrors = 0
                Set @returnCode = 'U5109'
                RAISERROR ('Could not find entry in database for dataset type "%s"', 11, 9, @newValue)
            End

        End

        -------------------------------------------------
        -- Apply the changes, as defined by @mode
        -------------------------------------------------

        If @mode = 'priority'
        Begin
            -- Get priority numerical value
            --
            Declare @pri int
            Set @pri = cast(@newValue as int)

            -- If priority is being set to non-zero, clear note field also
            --
            UPDATE T_Requested_Run
            SET RDS_priority = @pri,
                RDS_note = CASE WHEN @pri > 0 THEN '' ELSE RDS_note END
            FROM T_Requested_Run RR
                 INNER JOIN #Tmp_RequestIDs
                   ON RR.ID = #Tmp_RequestIDs.RequestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @message = 'Set the priority to ' + Convert(varchar(12), @pri) + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
            If @myRowcount > 1
                Set @message = @message + 's'
        End

        -------------------------------------------------
        If @mode IN ('instrumentGroup', 'instrumentGroupIgnoreType')
        Begin

            UPDATE T_Requested_Run
            SET RDS_instrument_group = @newInstrumentGroup
            FROM T_Requested_Run RR
                 INNER JOIN #Tmp_RequestIDs
                   ON RR.ID = #Tmp_RequestIDs.RequestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @message = 'Changed the instrument group to ' + @newInstrumentGroup + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
            If @myRowcount > 1
                Set @message = @message + 's'
        End

        ------------------------------------------------
        If @mode IN ('assignedInstrument')
        Begin
            UPDATE T_Requested_Run
            SET Queue_Instrument_ID = CASE WHEN @newQueueState > 1 THEN @newAssignedInstrumentID ELSE Queue_Instrument_ID END,
                Queue_State = @newQueueState,
                Queue_Date = CASE WHEN @newQueueState > 1 THEN GetDate() ELSE Queue_Date End,
                RDS_instrument_group =  CASE WHEN @newQueueState > 1 THEN @newInstrumentGroup ELSE RDS_instrument_group END
            FROM T_Requested_Run RR
                 INNER JOIN #Tmp_RequestIDs
                   ON RR.ID = #Tmp_RequestIDs.RequestID
            WHERE RR.RDS_Status = 'Active'
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @message = 'Can only update the assigned instrument for Active requested runs; all of the selected items are Completed or Inactive'
            End
            Else
            Begin
                Set @message = 'Changed the assigned instrument to ' + @newValue + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
                If @myRowcount > 1
                    Set @message = @message + 's'

                SELECT @myRowCount = COUNT(*)
                FROM T_Requested_Run RR INNER JOIN
                     #Tmp_RequestIDs ON RR.ID = #Tmp_RequestIDs.RequestID
                WHERE RR.RDS_Status <> 'Active'

                If @myRowCount > 0
                Begin
                    Set @message = @message + '; skipped ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.check_plural(@myRowCount, 'request', 'requests') + ' since not Active'
                End
            End
        End

        -------------------------------------------------
        If @mode IN ('separationGroup')
        Begin

            UPDATE T_Requested_Run
            SET RDS_Sec_Sep = @newSeparationGroup
            FROM T_Requested_Run RR
                 INNER JOIN #Tmp_RequestIDs
                   ON RR.ID = #Tmp_RequestIDs.RequestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @message = 'Changed the separation group to ' + @newSeparationGroup + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
            If @myRowcount > 1
                Set @message = @message + 's'
        End

        -------------------------------------------------
        If @mode = 'datasetType'
        Begin

            UPDATE T_Requested_Run
            SET RDS_type_ID = @newDatasetTypeID
            FROM T_Requested_Run RR
                 INNER JOIN #Tmp_RequestIDs
                   ON RR.ID = #Tmp_RequestIDs.RequestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @message = 'Changed the dataset type to ' + @newDatasetType + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
            If @myRowcount > 1
                Set @message = @message + 's'
        End

        -------------------------------------------------
        If @mode = 'delete'
        Begin -- <Delete>

            -- Step through the entries in #Tmp_RequestIDs and delete each
            SELECT @requestID = Min(RequestID)-1
            FROM #Tmp_RequestIDs

            Declare @countDeleted int = 0

            Set @continue = 1

            While @continue = 1
            Begin -- <b>
                SELECT TOP 1 @requestID = RequestID
                FROM #Tmp_RequestIDs
                WHERE RequestID > @requestID
                ORDER BY RequestID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @continue = 0
                Else
                Begin -- <c>
                    exec @myError = delete_requested_run
                                        @requestID,
                                        @skipDatasetCheck=0,
                                        @message=@message OUTPUT,
                                        @callingUser=@callingUser

                    If @myError <> 0
                    Begin -- <d>
                        If @message Like '%associated with dataset%'
                        Begin
                            -- Message is of the form
                            -- Error deleting Request ID 123456: Cannot delete requested run 123456 because it is associated with dataset xyz
                            Set @logErrors = 0
                        End

                        Set @msg = 'Error deleting Request ID ' + Convert(varchar(12), @requestID) + ': ' + @message
                        Set @returnCode = 'U5110'

                        RAISERROR (@msg, 11, 10)

                    End -- </d>

                    Set @countDeleted = @countDeleted + 1
                End -- </c>
            End -- </b>

            Set @message = 'Deleted ' + Convert(varchar(12), @countDeleted) + ' requested run'

            If @countDeleted > 1
                Set @message = @message + 's'

        End -- </Delete>

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Set @msg = @message + '; Requests '

            If Len(@reqRunIDList) < 128
                Set @msg = @msg + @reqRunIDList
            Else
                Set @msg = @msg + Substring(@reqRunIDList, 1, 128) + ' ...'

            exec post_log_entry 'Error', @msg, 'update_requested_run_assignments'
        End

    END CATCH

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512)
    Set @usageMessage = 'Updated ' + Convert(varchar(12), @requestCount) + ' requested run'

    If @requestCount <> 1
        Set @usageMessage = @usageMessage + 's'

    Exec post_usage_log_entry 'update_requested_run_assignments', @usageMessage

    If @returnCode <> ''
    Begin
        -- Call RAISERROR so that the web page will show the error message
        RAISERROR (@message, 11, 11)
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_assignments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_assignments] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_assignments] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_assignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_assignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_assignments] TO [Limited_Table_Write] AS [dbo]
GO

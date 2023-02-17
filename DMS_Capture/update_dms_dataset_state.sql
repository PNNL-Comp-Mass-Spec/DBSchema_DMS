/****** Object:  StoredProcedure [dbo].[update_dms_dataset_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dms_dataset_state]
/****************************************************
**
**  Desc:   Update dataset state
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/05/2010 grk - Initial Version
**          01/14/2010 grk - removed path ID fields
**          05/05/2010 grk - added handling for dataset info XML
**          09/01/2010 mem - Now calling update_dms_file_info_xml
**          03/16/2011 grk - Now recognizes IMSDatasetCapture
**          04/04/2012 mem - Now passing @failureMessage to s_set_capture_task_complete when the job is failed in the broker
**          06/13/2018 mem - Check for error code 53600 returned by update_dms_file_info_xml to indicate a duplicate dataset
**          08/09/2018 mem - Set the job state to 14 when the error code is 53600
**          08/17/2021 mem - Remove extra information from Completion messages with warning "Over 10% of the MS/MS spectra have a minimum m/z value larger than the required minimum; reporter ion peaks likely could not be detected"
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @datasetName varchar(128),
    @datasetID int,
    @script varchar(64),
    @storageServerName varchar(128),
    @newJobStateInBroker int,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @startPos int

    ---------------------------------------------------
    -- Dataset Capture
    ---------------------------------------------------
    --
    If @script = 'DatasetCapture' OR @script = 'IMSDatasetCapture'
    Begin
        If @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
        Begin
            EXEC @myError = s_set_capture_task_busy @datasetName, '(broker)', @message output
        End

        If @newJobStateInBroker = 3
        Begin
            ---------------------------------------------------
            -- Job Succeeded
            ---------------------------------------------------

            EXEC @myError = update_dms_file_info_xml @DatasetID, @DeleteFromTableOnSuccess=1, @message=@message Output

            If @myError = 53600
            Begin
                -- Use special completion code of 101
                EXEC @myError = s_set_capture_task_complete @datasetName, 101, @message OUTPUT, @failureMessage = @message

                -- Fail out the job with state 14 (Failed, Ignore Job Step States)
                Update T_Jobs
                Set State = 14
                Where Job = @job
            End
            Else
            Begin
                -- Use special completion code of 100
                EXEC @myError = s_set_capture_task_complete @datasetName, 100, @message OUTPUT
            End
        End

        If @newJobStateInBroker = 5
        Begin
            ---------------------------------------------------
            -- Job Failed
            ---------------------------------------------------

            Declare @failureMessage varchar(512)

            -- Look for any failure messages in T_Job_Steps for this job
            -- First check the Evaluation_Message column
            SELECT @failureMessage = JS.Evaluation_Message
            FROM T_Job_Steps JS INNER JOIN
                T_Jobs J ON JS.Job = J.Job
            WHERE (JS.Job = @job) AND IsNull(JS.Evaluation_Message, '') <> ''

            If IsNull(@failureMessage, '') = ''
            Begin
                -- Next check the Completion_Message column
                SELECT @failureMessage = JS.Completion_Message
                FROM T_Job_Steps JS INNER JOIN
                    T_Jobs J ON JS.Job = J.Job
                WHERE (JS.Job = @job) AND IsNull(JS.Completion_Message, '') <> ''

                -- Auto remove "; To ignore this error, use Exec add_update_job_parameter" from the completion message
                Set @startPos = CharIndex('; To ignore this error, use Exec add_update_job_parameter', @failureMessage)

                If @startPos > 1
                Begin
                    Set @failureMessage = Substring(@failureMessage, 1, @startPos - 1)
                End
            End

            EXEC @myError = s_set_capture_task_complete @datasetName, 1, @message output, @failureMessage=@failureMessage
        End
    End

    ---------------------------------------------------
    -- Dataset Archive
    ---------------------------------------------------
    --
    If @script = 'DatasetArchive'
    Begin
        If @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
        Begin
            EXEC @myError = s_set_archive_task_busy @datasetName, @storageServerName, @message  output
        End

        If @newJobStateInBroker = 3
        Begin
            EXEC @myError = s_set_archive_task_complete @datasetName, 100, @message OUTPUT -- using special completion code of 100
        End

        If @newJobStateInBroker = 5
        Begin
            EXEC @myError = s_set_archive_task_complete @datasetName, 1, @message output
        End
    End

    ---------------------------------------------------
    -- Archive Update
    ---------------------------------------------------
    --
    If @script = 'ArchiveUpdate'
    Begin
        If @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
        Begin
            EXEC @myError = s_set_archive_update_task_busy @datasetName, @storageServerName, @message output
        End

        If @newJobStateInBroker = 3
        Begin
            EXEC @myError = s_set_archive_update_task_complete @datasetName, 0, @message output
        End

        If @newJobStateInBroker = 5
        Begin
            EXEC @myError = s_set_archive_update_task_complete @datasetName, 1, @message output
        End
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_dms_dataset_state] TO [DDL_Viewer] AS [dbo]
GO

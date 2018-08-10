/****** Object:  StoredProcedure [dbo].[UpdateDMSDatasetState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateDMSDatasetState]
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
**          09/01/2010 mem - Now calling UpdateDMSFileInfoXML
**          03/16/2011 grk - Now recognizes IMSDatasetCapture
**          04/04/2012 mem - Now passing @FailureMessage to S_SetCaptureTaskComplete when the job is failed in the broker
**          06/13/2018 mem - Check for error code 53600 returned by UpdateDMSFileInfoXML to indicate a duplicate dataset
**          08/09/2018 mem - Set the job state to 14 when the error code is 53600
**    
*****************************************************/
(
    @job int,
    @datasetNum varchar(128),
    @datasetID int,
    @Script varchar(64),
    @storageServerName varchar(128),
    @newJobStateInBroker int,
    @message varchar(512) output
)
As
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    ---------------------------------------------------
    -- Dataset Capture
    ---------------------------------------------------
    --
    If @Script = 'DatasetCapture' OR @Script = 'IMSDatasetCapture'
    Begin
        If @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
        Begin 
            EXEC @myError = S_SetCaptureTaskBusy @datasetNum, '(broker)', @message output
        End

        If @newJobStateInBroker = 3
        Begin 
            ---------------------------------------------------
            -- Job Succeeded
            ---------------------------------------------------
            
            EXEC @myError = UpdateDMSFileInfoXML @DatasetID, @DeleteFromTableOnSuccess=1, @message=@message Output

            If @myError = 53600
            Begin
                -- Use special completion code of 101
                EXEC @myError = S_SetCaptureTaskComplete @datasetNum, 101, @message OUTPUT, @failureMessage = @message
                
                -- Fail out the job with state 14 (Failed, Ignore Job Step States)
                Update T_Jobs
                Set State = 14
                Where Job = @job
            End
            Else
            Begin
                -- Use special completion code of 100
                EXEC @myError = S_SetCaptureTaskComplete @datasetNum, 100, @message OUTPUT
            End
        End

        If @newJobStateInBroker = 5
        Begin 
            ---------------------------------------------------
            -- Job Failed
            ---------------------------------------------------
            
            Declare @FailureMessage varchar(256)
            
            -- Look for any failure messages in T_Job_Steps for this job
            -- First check the Evaluation_Message column
            SELECT @FailureMessage = JS.Evaluation_Message
            FROM T_Job_Steps JS INNER JOIN
                T_Jobs J ON JS.Job = J.Job
            WHERE (JS.Job = @job) AND IsNull(JS.Evaluation_Message, '') <> ''

            If IsNull(@FailureMessage, '') = ''
            Begin
                -- Next check the Completion_Message column
                SELECT @FailureMessage = JS.Completion_Message
                FROM T_Job_Steps JS INNER JOIN
                    T_Jobs J ON JS.Job = J.Job
                WHERE (JS.Job = @job) AND IsNull(JS.Completion_Message, '') <> ''
            End
            
            EXEC @myError = S_SetCaptureTaskComplete @datasetNum, 1, @message output, @FailureMessage=@FailureMessage
        End
    End

    ---------------------------------------------------
    -- Dataset Archive
    ---------------------------------------------------
    --
    If @Script = 'DatasetArchive'
    Begin
        If @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
        Begin 
            EXEC @myError = S_SetArchiveTaskBusy @datasetNum, @storageServerName, @message  output
        End

        If @newJobStateInBroker = 3
        Begin 
            EXEC @myError = S_SetArchiveTaskComplete @datasetNum, 100, @message OUTPUT -- using special completion code of 100
        End

        If @newJobStateInBroker = 5
        Begin 
            EXEC @myError = S_SetArchiveTaskComplete @datasetNum, 1, @message output
        End
    End

    ---------------------------------------------------
    -- Archive Update
    ---------------------------------------------------
    --
    If @Script = 'ArchiveUpdate'
    Begin
        If @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
        Begin 
            EXEC @myError = S_SetArchiveUpdateTaskBusy @datasetNum, @storageServerName, @message output
        End

        If @newJobStateInBroker = 3
        Begin 
            EXEC @myError = S_SetArchiveUpdateTaskComplete @datasetNum, 0, @message output
        End

        If @newJobStateInBroker = 5
        Begin 
            EXEC @myError = S_SetArchiveUpdateTaskComplete @datasetNum, 1, @message output
        End
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDMSDatasetState] TO [DDL_Viewer] AS [dbo]
GO

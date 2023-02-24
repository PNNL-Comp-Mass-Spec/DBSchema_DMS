/****** Object:  StoredProcedure [dbo].[update_analysis_job_processing_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_analysis_job_processing_stats]
/****************************************************
**
**  Desc:   Updates job state, start, and finish in T_Analysis_Job
**
**          Sets archive status of dataset to update required
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/02/2009 mem - Initial version
**          09/02/2011 mem - Now setting AJ_Purged to 0 when job is complete, no-export, or failed
**          09/02/2011 mem - Now calling post_usage_log_entry
**          04/18/2012 mem - Now preventing addition of @JobCommentAddnl to the comment field if it already contains @JobCommentAddnl
**          06/15/2015 mem - Use function append_to_text to concatenate @JobCommentAddnl to AJ_Comment
**          06/12/2018 mem - Send @maxLength to append_to_text
**          08/03/2020 mem - Update T_Cached_Dataset_Links.MASIC_Directory_Name when a MASIC job finishes successfully
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @newDMSJobState int,
    @newBrokerJobState int,
    @jobStart datetime,
    @jobFinish datetime,
    @resultsFolderName varchar(128),
    @assignedProcessor varchar(64),
    @jobCommentAddnl varchar(512),        -- Additional text to append to the comment (direct append; no separator character is used when appending @JobCommentAddnl)
    @organismDBName varchar(128),
    @processingTimeMinutes real,
    @updateCode int,                    -- Safety feature to prevent unauthorized job updates
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @datasetID int = 0
    Declare @datasetName varchar(128) = ''
    Declare @toolName varchar(64) = ''

    Declare @updateCodeExpected int

    Set @JobCommentAddnl = LTrim(RTrim(IsNull(@JobCommentAddnl, '')))

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    If @Job Is Null
    Begin
        Set @message = 'Invalid job'
        Set @myError = 50000
        Goto Done
    End

    If @NewDMSJobState Is Null Or @NewBrokerJobState Is Null
    Begin
        Set @message = 'Job and Broker state cannot be null'
        Set @myError = 50001
        Goto Done
    End

    -- Confirm that @UpdateCode is valid for this job
    If @Job % 2 = 0
        Set @updateCodeExpected = (@Job % 220) + 14
    Else
        Set @updateCodeExpected = (@Job % 125) + 11

    If IsNull(@UpdateCode, 0) <> @updateCodeExpected
    Begin
        Set @message = 'Invalid Update Code'
        Set @myError = 50002
        Goto Done
    End

    -- Uncomment to debug
    -- Declare @DebugMsg varchar(512) = 'Updating job state for ' + convert(varchar(12), @Job) +
    --          ', NewDMSJobState = ' + convert(varchar(12), @NewDMSJobState) +
    --          ', NewBrokerJobState = ' + convert(varchar(12), @NewBrokerJobState) +
    --          ', JobCommentAddnl = ' + IsNull(@JobCommentAddnl, '')
    --
    -- exec post_log_entry 'Debug', @DebugMsg, update_analysis_job_processing_stats

    ---------------------------------------------------
    -- Perform (or preview) the update
    -- Note: Comment is not updated if @NewBrokerJobState = 2
    ---------------------------------------------------
    --
    If @infoOnly <> 0
    Begin
        -- Display the old and new values
        SELECT AJ_StateID,
               @NewDMSJobState AS AJ_StateID_New,
               AJ_start,
               CASE
                   WHEN @NewBrokerJobState >= 2 THEN IsNull(@JobStart, GetDate())
                   ELSE AJ_start
               END AS AJ_start_New,
               AJ_finish,
               CASE
                   WHEN @NewBrokerJobState IN (4, 5) THEN @JobFinish
                   ELSE AJ_finish
               END AS AJ_finish_New,
               AJ_resultsFolderName,
               @resultsFolderName AS AJ_resultsFolderName_New,
               AJ_AssignedProcessorName,
               @AssignedProcessor AS AJ_AssignedProcessorName_New,
               CASE
                   WHEN @NewBrokerJobState = 2
                   THEN AJ_Comment
                   ELSE dbo.append_to_text(AJ_comment, @JobCommentAddnl, 0, '; ', 512)
               END AS Comment_New,
               AJ_organismDBName,
               IsNull(@OrganismDBName, AJ_organismDBName) AS AJ_organismDBName_New,
               AJ_ProcessingTimeMinutes,
               CASE
                   WHEN @NewBrokerJobState <> 2 THEN @ProcessingTimeMinutes
               ELSE AJ_ProcessingTimeMinutes
               END AS AJ_ProcessingTimeMinutes_New
        FROM T_Analysis_Job
        WHERE AJ_jobID = @job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        -- Update the values
        UPDATE T_Analysis_Job
        SET AJ_StateID = @NewDMSJobState,
            AJ_start = CASE WHEN @NewBrokerJobState >= 2
                            THEN IsNull(@JobStart, GetDate())
                            ELSE AJ_start
                       END,
            AJ_finish = CASE WHEN @NewBrokerJobState IN (4, 5)
                             THEN @JobFinish
                             ELSE AJ_finish
                        END,
            AJ_resultsFolderName = @resultsFolderName,
            AJ_AssignedProcessorName = 'Job_Broker',
            AJ_comment = CASE WHEN @NewBrokerJobState = 2
                              THEN AJ_Comment
                              ELSE dbo.append_to_text(AJ_comment, @JobCommentAddnl, 0, '; ', 512)
                         END,
            AJ_organismDBName = IsNull(@OrganismDBName, AJ_organismDBName),
            AJ_ProcessingTimeMinutes = CASE WHEN @NewBrokerJobState <> 2
                                            THEN @ProcessingTimeMinutes
                                            ELSE AJ_ProcessingTimeMinutes
                                       END,
            -- Note: setting AJ_Purged to 0 even if job failed since admin might later manually set job to complete and we want AJ_Purged to be 0 in that case
            AJ_Purged = CASE WHEN @NewBrokerJobState IN (4, 5, 14)
                             THEN 0
                             ELSE AJ_Purged
                        END
        WHERE AJ_jobID = @job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    -------------------------------------------------------------------
    -- If Job is Complete or No Export, do some additional tasks
    -------------------------------------------------------------------
    --
    If @NewDMSJobState in (4, 14) AND @infoOnly = 0
    Begin
        -- Get the dataset ID, dataset name, and tool name
        --
        SELECT @datasetID   = DS.Dataset_ID,
               @datasetName = DS.Dataset_Num,
               @toolName    = T.AJT_toolName
        FROM dbo.T_Analysis_Job J
             INNER JOIN dbo.T_Dataset DS
               ON J.AJ_datasetID = DS.Dataset_ID
             INNER JOIN T_Analysis_Tool T
               ON J.AJ_analysisToolID = T.AJT_toolID
        WHERE J.AJ_jobID = @job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            -- Schedule an archive update
            Exec set_archive_update_required @DatasetName, @Message output

            If @toolName LIKE 'Masic%'
            Begin
                -- Update the cached MASIC Directory Name
                UPDATE T_Cached_Dataset_Links
                Set MASIC_Directory_Name= @ResultsFolderName
                WHERE Dataset_ID = @datasetID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
        End
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    return @myError

GO
GRANT ALTER ON [dbo].[update_analysis_job_processing_stats] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_analysis_job_processing_stats] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_analysis_job_processing_stats] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_analysis_job_processing_stats] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_analysis_job_processing_stats] TO [Limited_Table_Write] AS [dbo]
GO

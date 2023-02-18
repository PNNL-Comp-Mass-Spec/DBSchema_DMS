/****** Object:  StoredProcedure [dbo].[SetStepTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SetStepTaskComplete]
/****************************************************
**
**  Desc:
**      Temporary wrapper for compatibility after procedure name changes
**
*****************************************************/
(
    @job int,
    @step int,
    @completionCode int,
    @completionMessage varchar(512) = '',
    @evaluationCode int = 0,
    @evaluationMessage varchar(512) = '',
    @organismDBName varchar(128) = '',
    @remoteInfo varchar(900) = '',          -- Remote server info for jobs with @completionCode = 25
    @remoteTimestamp varchar(24) = null,    -- Timestamp for the .info file for remotely running jobs (e.g. "20170515_1532" in file Job1449504_Step03_20170515_1532.info)
    @remoteProgress real = null,
    @remoteStart datetime = null,           -- Time the remote processor actually started processing the job
    @remoteFinish datetime = null,          -- Time the remote processor actually finished processing the job
    @processorName varchar(128) = '',        -- Name of the processor setting the job as complete
    @message varchar(512) = '' output,
    @returnCode varchar(64) = '' output
)
AS
    Declare @myError int = 0
    EXEC @myError = set_step_task_complete @job, @step, @completionCode, @completionMessage, @evaluationCode,
                        @evaluationMessage, @organismDBName, @remoteInfo, @remoteTimestamp, @remoteProgress,
                        @remoteStart, @remoteFinish, @processorName, @message output, @returnCode output
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [svc-dms] AS [dbo]
GO

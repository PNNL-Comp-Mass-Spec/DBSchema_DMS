/****** Object:  StoredProcedure [dbo].[UpdateManagerAndTaskStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateManagerAndTaskStatus]
/****************************************************
**
**  Desc:
**      Logs the current status of the given analysis manager
**
**      Manager status is typically stored in the database using UpdateManagerAndTaskStatusXML,
**      which is called by the StatusMessageDBUpdater
**      (running at \\proto-5\DMS_Programs\StatusMessageDBUpdater)
**
**      The StatusMessageDBUpdater caches the status messages from the managers, then
**      periodically calls UpdateManagerAndTaskStatusXML to update T_Processor_Status
**
**      However, if the message broker stops working, running analysis managers
**      will set LogStatusToBrokerDB to true, meaning calls to WriteStatusFile
**      will cascade into method LogStatus, which will call this stored procedure
**
**  Auth:   mem
**          03/24/2009 mem - Initial version
**          03/26/2009 mem - Added parameter @mostRecentJobInfo
**          03/31/2009 mem - Added parameter @dSScanCount
**          04/09/2009 grk - @message needs to be initialized to '' inside body of sproc
**          06/26/2009 mem - Expanded to support the new status fields
**          08/29/2009 mem - Commented out the update code to disable the functionality of this procedure (superseded by UpdateManagerAndTaskStatusXML, which is called by StatusMessageDBUpdater)
**          05/04/2015 mem - Added Process_ID
**          11/20/2015 mem - Added ProgRunner_ProcessID and ProgRunner_CoreUsage
**          08/25/2022 mem - Re-enabled the functionality of this procedure
**                         - Replaced int parameters @mgrStatusCode, @taskStatusCode, and @taskDetailStatusCode
**                           with string parameters @mgrStatus, @taskStatus, and @taskDetailStatus
**
*****************************************************/
(
    @mgrName varchar(128),
    @mgrStatus Varchar(50),
    @lastUpdate datetime,
    @lastStartTime datetime,
    @cPUUtilization real,
    @freeMemoryMB real,

    @processID int = null,
    @progRunnerProcessID int = null,
    @progRunnerCoreUsage real = null,

    @mostRecentErrorMessage varchar(1024) = '',

    -- Task    items
    @stepTool varchar(128),
    @taskStatus Varchar(50),
    @durationHours real,
    @progress real,
    @currentOperation varchar(256),

    -- Task detail items
    @taskDetailStatus Varchar(50),
    @job int,
    @jobStep int,
    @dataset varchar(256),
    @mostRecentLogMessage varchar(1024) = '',
    @mostRecentJobInfo varchar(256) = '',
    @spectrumCount int=0,                    -- The total number of spectra that need to be processed (or have been generated).  For Sequest, this is the DTA count
    @message varchar(512)='' output
)
As
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    set @message = ''

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @mgrName = IsNull(@mgrName, '')
    Set @mgrStatus = IsNull(@mgrStatus, 'Stopped')
    Set @lastUpdate = IsNull(@lastUpdate, GetDate())
    Set @mostRecentErrorMessage = IsNull(@mostRecentErrorMessage, '')

    Set @stepTool = IsNull(@stepTool, '')
    Set @taskStatus = IsNull(@taskStatus, 'No Task')
    Set @currentOperation = IsNull(@currentOperation, '')

    Set @taskDetailStatus = IsNull(@taskDetailStatus, 'No Task')
    Set @dataset = IsNull(@dataset, '')
    Set @mostRecentLogMessage = IsNull(@mostRecentLogMessage, '')
    Set @mostRecentJobInfo = IsNull(@mostRecentJobInfo, '')
    Set @spectrumCount = IsNull(@spectrumCount, 0)

    Set @message = ''

    If Len(@mgrName) = 0
    Begin
        Set @message = 'Processor name is empty; unable to continue'
        Goto Done
    End

    -- Check whether this processor is missing from T_Processor_Status
    If Not Exists (SELECT * FROM T_Processor_Status WHERE Processor_Name = @mgrName)
    Begin
        -- Processor is missing; add it
        INSERT INTO T_Processor_Status (Processor_Name, Mgr_Status, Task_Status, Task_Detail_Status)
        VALUES (@mgrName, @mgrStatus, @taskStatus, @taskDetailStatus)
    End

    UPDATE T_Processor_Status
    SET
        Remote_Manager = '',
        Mgr_Status = @mgrStatus,
        Status_Date = @lastUpdate,
        Last_Start_Time = @lastStartTime,
        CPU_Utilization = @cPUUtilization,
        Free_Memory_MB = @freeMemoryMB,
        Process_ID = @processID,
        ProgRunner_ProcessID = @progRunnerProcessID,
        ProgRunner_CoreUsage = @progRunnerCoreUsage,

        Most_Recent_Error_Message = CASE WHEN @mostRecentErrorMessage <> '' THEN @mostRecentErrorMessage ELSE Most_Recent_Error_Message END,

        Step_Tool = @stepTool,
        Task_Status = @taskStatus,
        Duration_Hours = @durationHours,
        Progress = @progress,
        Current_Operation = @currentOperation,

        Task_Detail_Status = @taskDetailStatus,
        Job = @job,
        Job_Step = @jobStep,
        Dataset = @dataset,
        Most_Recent_Log_Message =   CASE WHEN @mostRecentLogMessage <> ''   THEN @mostRecentLogMessage   ELSE Most_Recent_Log_Message END,
        Most_Recent_Job_Info =      CASE WHEN @mostRecentJobInfo <> ''      THEN @mostRecentJobInfo      ELSE Most_Recent_Job_Info END,
        Spectrum_Count = @spectrumCount
    WHERE Processor_Name = @mgrName

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error Updating T_Processor_Status'
        goto Done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    --
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatus] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatus] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatus] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatus] TO [svc-dms] AS [dbo]
GO

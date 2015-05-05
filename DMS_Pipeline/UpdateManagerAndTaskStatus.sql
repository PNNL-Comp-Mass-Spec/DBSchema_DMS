/****** Object:  StoredProcedure [dbo].[UpdateManagerAndTaskStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateManagerAndTaskStatus
/****************************************************
**
**	####################################################
**  This stored procedure has been superseded by UpdateManagerAndTaskStatusXML,
**  which is called by the StatusMessageDBUpdater
**  (running at \\proto-3\DMS_Programs\StatusMessageDBUpdater)
**
**  The StatusMessageDBUpdater caches the status messages from the managers, then
**  periodically calls UpdateManagerAndTaskStatusXML to update T_Processor_Status
**  with processor status information
**	####################################################
**
**  Desc:	Logs the current status of the given analysis manager
**
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**			03/24/2009 mem - Initial version
**			03/26/2009 mem - Added parameter @MostRecentJobInfo
**			03/31/2009 mem - Added parameter @DSScanCount
**			04/09/2009 grk - @message needs to be initialized to '' inside body of sproc
**			06/26/2009 mem - Expanded to support the new status fields
**			08/29/2009 mem - Commented out the update code to disable the functionality of this procedure (superseded by UpdateManagerAndTaskStatusXML, which is called by StatusMessageDBUpdater)
**			05/04/2015 mem - Added Process_ID
**
*****************************************************/
(
	@MgrName varchar(128),
	@MgrStatusCode int,						-- See T_Processor_Status_Codes; 0=Idle, 1=Running, 2=Stopped, 3=Starting, 4=Closing, 5=Retrieving Dataset, 6=Disabled, 7=FlagFileExists
    @LastUpdate datetime,
    @LastStartTime datetime,
	@CPUUtilization real,
	@FreeMemoryMB real,
	@ProcessID int = null,
	@MostRecentErrorMessage varchar(1024) = '',
	
	-- Task	items
	@StepTool varchar(128),
	@TaskStatusCode int,					-- See T_Processor_Task_Status_Codes;
	@DurationHours real,
	@Progress real,
	@CurrentOperation varchar(256),
	
	-- Task detail items
	@TaskDetailStatusCode int,				-- See T_Processor_Task_Detail_Status_Codes;
	@Job int,
	@JobStep int,
	@Dataset varchar(256),
	@MostRecentLogMessage varchar(1024) = '',
	@MostRecentJobInfo varchar(256) = '',
	@SpectrumCount int=0,					-- The total number of spectra that need to be processed (or have been generated).  For Sequest, this is the DTA count
	@message varchar(512)='' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	set @message = ''


/*
**	Code commented out 8/29/2009 by MEM to disable the functionality of this procedure
**

	---------------------------------------------------
	-- Validate the inputs; clear the outputs
	---------------------------------------------------

	Set @MgrName = IsNull(@MgrName, '')
	Set @MgrStatusCode = IsNull(@MgrStatusCode, 0)
	Set @LastUpdate = IsNull(@LastUpdate, GetDate())
	Set @LastStartTime = IsNull(@LastStartTime, Null)
	Set @CPUUtilization = IsNull(@CPUUtilization, Null)
	Set @FreeMemoryMB = IsNull(@FreeMemoryMB, Null)
	Set @ProcessID = IsNull(@ProcessID, null)
	Set @MostRecentErrorMessage = IsNull(@MostRecentErrorMessage, '')

	Set @StepTool = IsNull(@StepTool, '')
	Set @TaskStatusCode = IsNull(@TaskStatusCode, 0)
	Set @DurationHours = IsNull(@DurationHours, Null)
	Set @Progress = IsNull(@Progress, Null)
	Set @CurrentOperation = IsNull(@CurrentOperation, '')
	
	Set @TaskDetailStatusCode = IsNull(@TaskDetailStatusCode, 0)
	Set @Job = IsNull(@Job, Null)
	Set @JobStep = IsNull(@JobStep, Null)
	Set @Dataset = IsNull(@Dataset, '')
	Set @MostRecentLogMessage = IsNull(@MostRecentLogMessage, '')
	Set @MostRecentJobInfo = IsNull(@MostRecentJobInfo, '')
	Set @SpectrumCount = IsNull(@SpectrumCount, 0)

	Set @message = ''

	If Len(@MgrName) = 0
	Begin
		Set @message = 'Processor name is empty; unable to continue'
		Goto Done
	End


	-- Check whether this processor is missing from T_Processor_Status
	If Not Exists (SELECT * FROM T_Processor_Status WHERE Processor_Name = @MgrName)
	Begin
		-- Processor is missing; add it
		INSERT INTO T_Processor_Status (Processor_Name, Mgr_Status_Code, Task_Status_Code, Task_Detail_Status_Code)
		VALUES (@MgrName, @MgrStatusCode, @TaskStatusCode, @TaskDetailStatusCode)
	End



	UPDATE T_Processor_Status
	SET 
		Mgr_Status_Code = @MgrStatusCode,
		Status_Date = @LastUpdate,
		Last_Start_Time = @LastStartTime,
		CPU_Utilization = @CPUUtilization,
		Free_Memory_MB = @FreeMemoryMB,
		Process_ID = @ProcessID,
		Most_Recent_Error_Message = CASE WHEN @MostRecentErrorMessage <> '' THEN @MostRecentErrorMessage ELSE Most_Recent_Error_Message END,

		Step_Tool = @StepTool,
		Task_Status_Code = @TaskStatusCode,
		Duration_Hours = @DurationHours,
		Progress = @Progress,
		Current_Operation = @CurrentOperation,

		Task_Detail_Status_Code = @TaskDetailStatusCode,
		Job = @Job,
		Job_Step = @JobStep,
		Dataset = @Dataset,
		Most_Recent_Log_Message =   CASE WHEN @MostRecentLogMessage <> ''   THEN @MostRecentLogMessage   ELSE Most_Recent_Log_Message END,
		Most_Recent_Job_Info =      CASE WHEN @MostRecentJobInfo <> ''      THEN @MostRecentJobInfo      ELSE Most_Recent_Job_Info END,
		Spectrum_Count = @SpectrumCount
	WHERE Processor_Name = @MgrName

	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error Updating T_Processor_Status'
		goto Done
	end

*/

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	--
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatus] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatus] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatus] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatus] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatus] TO [svc-dms] AS [dbo]
GO

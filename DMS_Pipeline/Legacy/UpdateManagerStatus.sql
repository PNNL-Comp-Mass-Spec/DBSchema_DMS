/****** Object:  StoredProcedure [dbo].[UpdateManagerStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateManagerStatus
/****************************************************
**
**	####################################################
**	Note: This procedure is obsolete
**  It has been superseded by UpdateManagerAndTaskStatus
**	####################################################
**
**  Desc:	Logs the current status of the given analysis manager
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
**			06/26/2009 mem - Updated to support new field names in T_Processor_Status
**
*****************************************************/
(
	@ProcessorName varchar(128),
	@StatusCode int,	-- See T_Processor_Status_Codes; 0=Idle, 1=Running, 2=Stopped, 3=Starting, 4=Closing, 5=Retrieving Dataset, 6=Disabled, 7=FlagFileExists
	@Job int,
	@JobStep int,
	@StepTool varchar(128),
	@Dataset varchar(256),
	@DurationHours real,
	@Progress real,
	@DSScanCount int=0,						-- The total number of spectra that need to be processed (or have been generated).  For Sequest, this is the DTA count
	@MostRecentJobInfo varchar(256) = '',
	@MostRecentLogMessage varchar(1024) = '',
	@MostRecentErrorMessage varchar(1024) = '',
	@message varchar(512)='' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	set @message = ''

	declare @MgrStatusCode int
	declare @TaskStatusCode int
	declare @TaskDetailStatusCode int
	
	---------------------------------------------------
	-- Validate the inputs; clear the outputs
	---------------------------------------------------

	Set @processorName = IsNull(@processorName, '')
	Set @StatusCode = IsNull(@StatusCode, 0)
	Set @Job = IsNull(@Job, Null)
	Set @JobStep = IsNull(@JobStep, Null)
	Set @StepTool = IsNull(@StepTool, '')
	Set @Dataset = IsNull(@Dataset, '')
	Set @DurationHours = IsNull(@DurationHours, Null)
	Set @Progress = IsNull(@Progress, Null)
	Set @DSScanCount = IsNull(@DSScanCount, 0)
	Set @MostRecentJobInfo = IsNull(@MostRecentJobInfo, '')
	Set @MostRecentLogMessage = IsNull(@MostRecentLogMessage, '')
	Set @MostRecentErrorMessage = IsNull(@MostRecentErrorMessage, '')

	Set @message = ''

	If Len(@processorName) = 0
	Begin
		Set @message = 'Processor name is empty; unable to continue'
		Goto Done
	End

	Set @TaskStatusCode = @StatusCode
	Set @TaskDetailStatusCode = 5	-- No task
	
	If @TaskStatusCode = 0
		Set @MgrStatusCode = 0
	
	If @TaskStatusCode IN (1,2,3)
	Begin
		Set @MgrStatusCode = 2				-- Running
		Set @TaskDetailStatusCode = 1		-- Running
	End

	If @TaskStatusCode = 4
		Set @MgrStatusCode = 1
	
	If @TaskStatusCode = 5
		Set @MgrStatusCode = 0
	

	-- Check whether this processor is missing from T_Processor_Status
	If Not Exists (SELECT * FROM T_Processor_Status WHERE Processor_Name = @processorName)
	Begin
		-- Processor is missing; add it
		INSERT INTO T_Processor_Status (Processor_Name, Mgr_Status_Code, Task_Status_Code, Task_Detail_Status_Code)
		VALUES (@processorName, @MgrStatusCode, @TaskStatusCode, @TaskDetailStatusCode)
	End


	UPDATE T_Processor_Status
	SET 
		Mgr_Status_Code = @MgrStatusCode,
		Status_Date = GetDate(),
		Last_Start_Time = Null,
		CPU_Utilization = Null,
		Free_Memory_MB = Null,
		Most_Recent_Error_Message = CASE WHEN @MostRecentErrorMessage <> '' THEN @MostRecentErrorMessage ELSE Most_Recent_Error_Message END,

		Step_Tool = @StepTool,
		Task_Status_Code = @TaskStatusCode,
		Duration_Hours = @DurationHours,
		Progress = @Progress,
		Current_Operation = '',

		Task_Detail_Status_Code = @TaskDetailStatusCode,
		Job = @Job,
		Job_Step = @JobStep,
		Dataset = @Dataset,
		Most_Recent_Log_Message =   CASE WHEN @MostRecentLogMessage <> ''   THEN @MostRecentLogMessage   ELSE Most_Recent_Log_Message END,
		Most_Recent_Job_Info =      CASE WHEN @MostRecentJobInfo <> ''      THEN @MostRecentJobInfo      ELSE Most_Recent_Job_Info END,
		Spectrum_Count = @DSScanCount
	WHERE Processor_Name = @processorName
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
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerStatus] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerStatus] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerStatus] TO [PNL\D3M580] AS [dbo]
GO

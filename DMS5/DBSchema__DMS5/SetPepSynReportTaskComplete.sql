/****** Object:  StoredProcedure [dbo].[SetPepSynReportTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure SetPepSynReportTaskComplete

/****************************************************
**
**	Desc:
**
**	Return values: 0: success, otherwise, error code
**
**
**		Auth: grk
**		Date: 07/09/2004
**	Modified
**		KAL 07/12/2004 - changed reportID to int, removed default completionCode value
**				- Added code so that only tasks in the Busy state get updated
**		KAL 09/01/2004 - Changed State to use (T_Peptide_Synopsis_Report_States) instead of 'Ready', 'Busy', 'Failed'
**		KAL /9/07/2004 - Added storagePath for use with T_Peptide_Synopsis_Report_Runs
*****************************************************/
	@reportID int,
	@processorName varchar(64),
	@completionCode int,
	@storagePath varchar(512),
	@message varchar(512)='' output
As
	set nocount on
	set @message = ''

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	declare @state varchar(24)
	--------------------------------------------------
	-- KAL 7/12/2004
	-- get current state, if it is not busy, then exit
	--------------------------------------------------
	SELECT @state = State
	FROM T_Peptide_Synopsis_Reports
	WHERE Report_ID = @reportID

	if @state <> 5 --Busy
	begin
		set @message = 'State of task ' + LTRIM(RTRIM(STR(@reportID))) + ' is not Busy.  No update performed'
		set @myError = 53006
		goto done
	end
	
	---------------------------------------------------
	-- Adjust state
	---------------------------------------------------
	--
	if @completionCode = 0
		begin
			set @state = 1
		end
	else
		begin
			set @state = 10
		end

	---------------------------------------------------
	-- Adjust repeat count
	---------------------------------------------------
	declare @repeatCount int
	set @repeatCount = 0
	--
	SELECT @repeatCount = Repeat_Count
	FROM T_Peptide_Synopsis_Reports
	WHERE Report_ID = @reportID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Error getting task details'
		set @myError = 53001
		goto done
	end
	--
	if @repeatCount between 1 and 99
	begin
		set @repeatCount = @repeatCount - 1
	end
			
	---------------------------------------------------
	-- Update state
	-- KAL 09/07/2004 Removed Last_Run_Date since this is now in T_Peptide_Synopsis_Report_Runs
	---------------------------------------------------
	
	--
	UPDATE T_Peptide_Synopsis_Reports
	SET
		Repeat_Count = @repeatCount, 
		State = @state
	WHERE Report_ID = @reportID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update operation failed'
		set @myError = 53005
		goto done
	end

	--------------------------------------------------
	-- KAL 9/7/2004 Put entry in T_Peptide_Synopsis_Reports_Run
	--------------------------------------------------
	INSERT INTO T_Peptide_Synopsis_Report_Runs
		(Synopsis_Report, Run_Date, Failure, Storage_Path, Processor_Name)
	VALUES (@reportID, getDate(), @completionCode, @storagePath, @processorName)

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[SetPepSynReportTaskComplete] TO [DMS_Ops_Admin]
GO
GRANT EXECUTE ON [dbo].[SetPepSynReportTaskComplete] TO [DMS_SP_User]
GO

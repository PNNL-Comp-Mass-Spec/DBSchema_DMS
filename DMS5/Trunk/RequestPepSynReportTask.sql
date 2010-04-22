/****** Object:  StoredProcedure [dbo].[RequestPepSynReportTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   Procedure RequestPepSynReportTask
/****************************************************
**
**	Desc: Looks for available peptide synopsis report task
**
**	Return values: 0: success, otherwise, error code
**
**
**		Auth: grk
**		Date: 07/09/2004
**	Modified
**		KAL 07/12/2004 - Added reportSorting field
**				- Changed datasetMatchList and instrumentMatchList to output params
**				- Added defaults for all output parameters
**				- Added taskAvailable param
**				- Added recipients field
**				- Changed runInterval to measure in minutes instead of days
**		KAL 07/20/2004 - Renamed recipeints param to outputForm (plus corresponding change in base table)
**		KAL 07/26/2004 - Added scrolling windows for dataset and job dates  (plus corresponding change in base table).
**		KAL 08/10/2004 - Added master job match for venn diagrams (plus table change)
**		KAL 08/20/2004 - Added required peptide per protein requirements
**		KAL 09/01/2004 - Changed State to use integer values (T_Peptide_Synopsis_Report_States) instead of 'Ready', 'Busy', 'Failed'
**		KAL 09/07/2004 - Changed File_To_Use column to Use_Synopsis_Files column
**		KAL 09/07/2004 - Changed to use V_Peptide_Synopsis_Reports (indirectly using T_Peptide_Synopsis_Report_Runs)
**		JDS 02/28/2004 - Added parameter fields @experiment_MatchList and @taskType, @databaseName, @serverName
*****************************************************/
	@processorName varchar(64),
	@taskAvailable tinyint = 0 output, 
	@reportID int = -1 output,
	@name varchar(32) = '' output,
	@description varchar(255) = '' output,
	@datasetMatchList varchar(2048) = '' output,
	@instrumentMatchList varchar(512) = '' output,
	@paramFileMatchList varchar(256) = '' output,
	@fastaFileMatchList varchar(256) = '' output,
	@experimentMatchList varchar(256) = '' output,
	@comparisonJobNumber int = NULL output,
	@datasetStartDate datetime = '1/1/2000' output,
	@datasetEndDate datetime = '1/1/2000' output,
	@jobStartDate datetime = '1/1/2000' output,
	@jobEndDate datetime = '1/1/2000' output,
	@useSynopsisFiles tinyint = ''output,
	@reportSorting varchar(255) output,
	@primaryFilterID int = -1 output,
	@secondaryFilterID int=-1 output,
	@requiredPrimaryPeptidesPerProtein int=-1 output,
	@requiredPrimaryPlusSecondaryPeptidesPerProtein int=-1 output,
	@requiredOverlapPeptidesPerOverlapProtein int=-1 output,
	@lastRunDate datetime = '1/1/2000' output,
	@runInterval int = -1 output,
	@outputForm varchar(1024) = '' output,
	@taskType varchar(20) = '' output,
	@databaseName varchar(50) = '' output,
	@serverName varchar(50) = '' output,
	@message varchar(512) = '' output
As
	set nocount on
	-- set taskAvailable to none
	set @taskAvailable = 0

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	declare @scrollingDatasetDates tinyint
	declare @scrollingJobDates tinyint
	declare @scrollingDatasetTimeFrame int
	declare @scrollingJobTimeFrame int
	
	set @message = ''

	set @reportID = 0
	
	---------------------------------------------------
	-- temporary table to hold candidate tasks
	---------------------------------------------------

	CREATE TABLE #PD (
		ID  int
	) 

	---------------------------------------------------
	-- Populate temporary table with a small pool of 
	-- suitable tasks.
	-- If last successful run date is null, then replace with a value that should cause the run to be executed.
	---------------------------------------------------

	INSERT INTO #PD
	(ID)
	SELECT     TOP 5 Report_ID
	FROM         V_Peptide_Synopsis_Reports
	WHERE     
		(DATEADD(minute, Run_Interval, ISNULL(Last_Successful_Run_Date, '1/1/2000')) < GETDATE()) AND 
		(State = 1) AND 
		(Repeat_Count > 0)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end

	if @myRowCount = 0	--no tasks have reached reporting time, so return
	begin
		set @message = ''
		set @taskAvailable = 0
		goto done
	end

	---------------------------------------------------
	--  Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'RequestPepSynReportTask'
	begin transaction @transName
	
	set @reportID = 0

	---------------------------------------------------
	-- Select and lock a specific job by joining
	-- from the local pool to the actual analysis job table.

	-- Prefer jobs with preassigned processor
	---------------------------------------------------

	SELECT top 1 
		@reportID = Report_ID
	FROM T_Peptide_Synopsis_Reports with (HoldLock) 
	inner join #PD on ID = Report_ID 
	WHERE (State = 1)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0

	begin
		rollback transaction @transName
		set @message = 'Error looking for available task'
		goto done
	end
	
	if @myRowCount <> 1
	begin
		rollback transaction @transName
		set @myError = 53000
		goto done
	end

	---------------------------------------------------
	-- set state and assigned processor
	---------------------------------------------------

	UPDATE T_Peptide_Synopsis_Reports 
	SET 
		State = 5,
		Processor_Name  = @processorName		
	WHERE (Report_ID = @reportID)

	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--

	if @myRowCount <> 1
	begin
		rollback transaction @transName
		RAISERROR ('Update operation failed',
			10, 1)
		return 53001
	end

	commit transaction @transName

	---------------------------------------------------
	-- get the detailed information for the chosen task
	---------------------------------------------------
	-- 
	declare @storageServerPath varchar(64)
	--
	set @taskAvailable = 1
	SELECT  
		@reportID = Report_ID,
		@name = [Name],
		@description = Description,
		@datasetMatchList = Dataset_Match_List,
		@instrumentMatchList = Instrument_Match_List,
		@paramFileMatchList = Param_File_Match_List,
		@fastaFileMatchList = Fasta_File_Match_List,
		@experimentMatchList = Experiment_Match_List,
		@comparisonJobNumber	 = Comparison_Job_Number,
		@scrollingDatasetDates = Scrolling_Dataset_Dates,
		@scrollingDatasetTimeFrame = Scrolling_Dataset_Time_Frame,
		@datasetStartDate = ISNULL(Dataset_Start_Date, '1/1/2000'),
		@datasetEndDate = ISNULL(Dataset_End_Date, getdate()),
		@scrollingJobDates = Scrolling_Job_Dates,
		@scrollingJobTimeFrame = Scrolling_Job_Time_Frame,
		@jobStartDate = ISNULL(Job_Start_Date, '1/1/2000'),
		@jobEndDate = ISNULL(Job_End_Date, getdate()),
		@useSynopsisFiles = Use_Synopsis_Files,
		@reportSorting = Report_Sort_Value,
		@primaryFilterID = Primary_Filter_ID,
		@secondaryFilterID = Secondary_Filter_ID,
		@requiredPrimaryPeptidesPerProtein = Required_Primary_Peptides_per_Protein,
		@requiredPrimaryPlusSecondaryPeptidesPerProtein = Required_PrimaryPlusSecondary_Peptides_per_Protein,
		@requiredOverlapPeptidesPerOverlapProtein = Required_Overlap_Peptides_per_Overlap_Protein,
		@lastRunDate = ISNULL(Last_Successful_Run_Date, '1/1/2000'),
		@taskType = Task_Type,
		@databaseName = Database_Name,
		@serverName = Server_Name,
		@outputForm = Output_Form,
		@runInterval = Run_Interval
	FROM V_Peptide_Synopsis_Reports
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

	---------------------------------------------------
	-- deal with scrolling dataset and job dates
	----------------------------------------------------
	if @scrollingDatasetDates = 1
	begin
		set @datasetEndDate = getdate()
		set @datasetStartDate = DATEADD(day,-@scrollingDatasetTimeFrame, getdate())
	end

	if @scrollingJobDates = 1
	begin
		set @jobEndDate = getdate()
		set @jobStartDate = DATEADD(day, -@scrollingJobTimeFrame, getdate())
	end
 /******/
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[RequestPepSynReportTask] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPepSynReportTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPepSynReportTask] TO [PNL\D3M580] AS [dbo]
GO

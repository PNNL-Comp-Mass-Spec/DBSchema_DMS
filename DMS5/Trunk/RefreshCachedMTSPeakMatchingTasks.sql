/****** Object:  StoredProcedure [dbo].[RefreshCachedMTSPeakMatchingTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE RefreshCachedMTSPeakMatchingTasks
/****************************************************
**
**	Desc:	Updates the data in T_MTS_Peak_Matching_Tasks_Cached using MTS
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	02/05/2010 mem - Initial Version
**			04/21/2010 mem - Updated to use the most recent entry for a given peak matching task (to avoid duplicates if a task is rerun)
**
*****************************************************/
(
	@JobMinimum int = 0,		-- Set to a positive value to limit the jobs examined; when non-zero, then jobs outside this range are ignored
	@JobMaximum int = 0,
	@message varchar(255) = '' output
)
AS

	Set NoCount On

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''

	Declare @MaxInt int
	Set @MaxInt = 2147483647

	
	Declare @MergeUpdateCount int
	Declare @MergeInsertCount int
	Declare @MergeDeleteCount int
	
	Set @MergeUpdateCount = 0
	Set @MergeInsertCount = 0
	Set @MergeDeleteCount = 0

	---------------------------------------------------
	-- Create the temporary table that will be used to
	-- track the number of inserts, updates, and deletes 
	-- performed by the MERGE statement
	---------------------------------------------------
	
	CREATE TABLE #Tmp_UpdateSummary (
		UpdateAction varchar(32)
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_UpdateSummary ON #Tmp_UpdateSummary (UpdateAction)
	
		
	Declare @FullRefreshPerformed tinyint
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try
		Set @CurrentLocation = 'Validate the inputs'

		-- Validate the inputs
		Set @JobMinimum = IsNull(@JobMinimum, 0)
		Set @JobMaximum = IsNull(@JobMaximum, 0)
		
		If @JobMinimum = 0 AND @JobMaximum = 0
		Begin
			Set @FullRefreshPerformed = 1
			Set @JobMinimum = -@MaxInt
			Set @JobMaximum = @MaxInt
		End
		Else
		Begin
			Set @FullRefreshPerformed = 0
			If @JobMinimum > @JobMaximum
				Set @JobMaximum = @MaxInt
		End

		Set @CurrentLocation = 'Update T_MTS_Cached_Data_Status'
		-- 
		Exec UpdateMTSCachedDataStatus 'T_MTS_Peak_Matching_Tasks_Cached', @IncrementRefreshCount = 0, @FullRefreshPerformed = @FullRefreshPerformed, @LastRefreshMinimumID = @JobMinimum



		
		-- Use a MERGE Statement (introduced in Sql Server 2008) to synchronize T_MTS_Peak_Matching_Tasks_Cached with S_MTS_Peak_Matching_Tasks

		MERGE T_MTS_Peak_Matching_Tasks_Cached AS target
		USING 
			( SELECT	Tool_Name, MTS_Job_ID, Job_Start, Job_Finish, Comment, 
						State_ID, Task_Server, Task_Database, Task_ID, 
						Assigned_Processor_Name, Tool_Version, DMS_Job_Count, 
						DMS_Job, Output_Folder_Path, Results_URL
			  FROM ( SELECT	Tool_Name, MTS_Job_ID, Job_Start, Job_Finish, Comment, 
							State_ID, Task_Server, Task_Database, Task_ID, 
							Assigned_Processor_Name, Tool_Version, DMS_Job_Count, 
							DMS_Job, Output_Folder_Path, Results_URL,
							RANK() OVER ( PARTITION BY tool_name, task_server, task_database, task_id 
										  ORDER BY MTS_Job_ID DESC ) AS TaskStartRank
					FROM S_MTS_Peak_Matching_Tasks AS PMT
					WHERE MTS_Job_ID >= @JobMinimum AND
						  MTS_Job_ID <= @JobMaximum ) SourceQ
			  WHERE TaskStartRank = 1
			) AS Source (Tool_Name, MTS_Job_ID, Job_Start, Job_Finish, Comment,
						 State_ID, Task_Server, Task_Database, Task_ID,
						 Assigned_Processor_Name, Tool_Version, DMS_Job_Count,
						 DMS_Job, Output_Folder_Path, Results_URL)
		ON (target.MTS_Job_ID = source.MTS_Job_ID AND target.DMS_Job = source.DMS_Job)
		WHEN Matched AND 
					(	IsNull(target.Job_Start,'') <> IsNull(source.Job_Start,'') OR
						IsNull(target.Job_Finish,'') <> IsNull(source.Job_Finish,'') OR
						target.State_ID <> source.State_ID OR
						target.Task_Server <> source.Task_Server OR
						target.Task_Database <> source.Task_Database OR
						target.Task_ID <> source.Task_ID OR
						IsNull(target.DMS_Job_Count,0) <> IsNull(source.DMS_Job_Count,0) OR
						IsNull(target.Output_Folder_Path,'') <> IsNull(source.Output_Folder_Path,'') OR
						IsNull(target.Results_URL,'') <> IsNull(source.Results_URL,'')
					)
			THEN UPDATE 
				Set Tool_Name = source.Tool_Name,
					Job_Start = source.Job_Start,
					Job_Finish = source.Job_Finish,
					Comment = source.Comment,
					State_ID = source.State_ID,
					Task_Server = source.Task_Server,
					Task_Database = source.Task_Database,
					Task_ID = source.Task_ID,
					Assigned_Processor_Name = source.Assigned_Processor_Name,
					Tool_Version = source.Tool_Version,
					DMS_Job_Count = source.DMS_Job_Count,
					Output_Folder_Path = source.Output_Folder_Path,
					Results_URL = source.Results_URL
		WHEN Not Matched THEN
			INSERT (	Tool_Name, 
						MTS_Job_ID, 
						Job_Start, 
						Job_Finish, 
						Comment, 
						State_ID, 
						Task_Server, 
						Task_Database, 
						Task_ID, 
						Assigned_Processor_Name, 
						Tool_Version, 
						DMS_Job_Count, 
						DMS_Job, 
						Output_Folder_Path, 
						Results_URL
					)
			VALUES (source.Tool_Name, source.MTS_Job_ID, source.Job_Start, source.Job_Finish, source.Comment, 
					source.State_ID, source.Task_Server, source.Task_Database, source.Task_ID, 
					source.Assigned_Processor_Name, source.Tool_Version, source.DMS_Job_Count, 
					source.DMS_Job, source.Output_Folder_Path, source.Results_URL)
		WHEN NOT MATCHED BY SOURCE And @FullRefreshPerformed <> 0 THEN
			DELETE 
		OUTPUT $action INTO #Tmp_UpdateSummary
		;
	
		if @myError <> 0
		begin
			set @message = 'Error merging S_MTS_Peak_Matching_Tasks with T_MTS_Peak_Matching_Tasks_Cached (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'SyncJobInfo'
			goto Done
		end


		set @MergeUpdateCount = 0
		set @MergeInsertCount = 0
		set @MergeDeleteCount = 0

		SELECT @MergeInsertCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'INSERT'

		SELECT @MergeUpdateCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'UPDATE'

		SELECT @MergeDeleteCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'DELETE'


		Set @CurrentLocation = 'Update stats in T_MTS_Cached_Data_Status'
		--
		-- 
		Exec UpdateMTSCachedDataStatus 'T_MTS_Peak_Matching_Tasks_Cached', 
											@IncrementRefreshCount = 1, 
											@InsertCountNew = @MergeInsertCount, 
											@UpdateCountNew = @MergeUpdateCount, 
											@DeleteCountNew = @MergeDeleteCount,
											@FullRefreshPerformed = @FullRefreshPerformed, 
											@LastRefreshMinimumID = @JobMinimum

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'RefreshCachedMTSAnalysisJobInfo')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError

GO

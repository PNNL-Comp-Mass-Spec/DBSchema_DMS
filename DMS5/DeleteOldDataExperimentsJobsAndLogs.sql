/****** Object:  StoredProcedure [dbo].[DeleteOldDataExperimentsJobsAndLogs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DeleteOldDataExperimentsJobsAndLogs
/****************************************************
**
**	Desc: 
**		Deletes old data, experiments, jobs, and log entries
**		Intended to be used with the DMS5_Beta or DMS5_T3 databases to reduce file size
**
**		To avoid deleting production data, this procedure prevents itself from running against DMS5\
**
**		After deleting the data, you can reclaim database space using:
**
**			Use DMS5_Beta
**			GO
**			Alter Database DMS5_Beta Set Recovery Simple
**			GO
**			Alter Database DMS5_Beta Set Recovery Full
**			GO
**		
**			-- Next, call SHRINKDATABASE
**			DBCC SHRINKDATABASE (DMS5_Beta)
**		
**			-- Next, for good measure, call SHRINKFILE
**			-- Use "SELECT * FROM sys.database_files" to determine file names
**			Use DMS5_Beta
**			DBCC SHRINKFILE (DMS4_log, 1)
**		
**
**	Return values: 0 if no error; otherwise error code
**
**	Auth:	mem
**	Date:	02/24/2012 mem - Initial version
**			02/28/2012 mem - Added @MaxItemsToProcess
**			05/28/2015 mem - Removed T_Analysis_Job_Processor_Group_Associations, since deprecated
**			10/28/2015 mem - Added T_Prep_LC_Run_Dataset and removed T_Analysis_Job_Annotations and T_Dataset_Annotations
**			02/23/2016 mem - Add set XACT_ABORT on
**			03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@infoOnly tinyint = 1,						-- Change to 0 to actually perform the deletion
	@YearsToRetain int = 4,						-- Number of years of data to retain; setting to 4 will delete data more than 4 years old; minimum value is 1
	@RecentJobOverrideYears float = 2,			-- Keeps datasets and experiments that have had an analysis job run within this mean years
	@LogEntryMonthsToRetain int = 3,			-- Number of months of logs to retain
	@DatasetSkipList varchar(max) = '',			-- List of datasets to skip
	@ExperimentSkipList varchar(max) = '',		-- List of experiments to skip
	@DeleteJobs tinyint = 1,
	@DeleteDatasets tinyint = 1,
	@DeleteExperiments tinyint = 1,
	@MaxItemsToProcess int = 75000,
	@message varchar(255) = '' OUTPUT
)
AS
	Set XACT_ABORT, nocount on

	declare @myRowCount int	
	declare @myError int
	set @myRowCount = 0
	set @myError = 0

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'DeleteOldDataExperimentsJobsAndLogs', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	---------------------------------------------------
	-- Make sure we're not running in DMS5
	---------------------------------------------------
	
	If DB_Name() = 'DMS5'
	Begin
		Set @message = 'Error: This procedure cannot be used with DMS5'
		SELECT @message as Message
		
		Goto Done
	End
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 1)
	Set @YearsToRetain = IsNull(@YearsToRetain, 4)
	If @YearsToRetain < 1
		Set @YearsToRetain = 1
		
	Set @RecentJobOverrideYears = IsNull(@RecentJobOverrideYears, 2)
	If @RecentJobOverrideYears < 0.5
		Set @RecentJobOverrideYears = 0.5
	
	Set @LogEntryMonthsToRetain = IsNull(@LogEntryMonthsToRetain, 3)
	If @LogEntryMonthsToRetain < 1
		Set @LogEntryMonthsToRetain = 1
		
	Set @DatasetSkipList = IsNull(@DatasetSkipList, '')
	Set @ExperimentSkipList = IsNull(@ExperimentSkipList, '')
	
	Set @DeleteJobs = IsNull(@DeleteJobs, 1)
	Set @DeleteDatasets = IsNull(@DeleteDatasets, 1)
	Set @DeleteExperiments = IsNull(@DeleteExperiments, 1)
	
	Set @MaxItemsToProcess = IsNUll(@MaxItemsToProcess, 75000)
	If @MaxItemsToProcess <= 0
		Set @MaxItemsToProcess = 1000000
		
	Set @message = ''
	
	
	Declare @DeleteThreshold datetime
	Set @DeleteThreshold = DateAdd(year, -@YearsToRetain, GetDate())

	Declare @JobKeepThreshold datetime
	Set @JobKeepThreshold = DateAdd(day, -@RecentJobOverrideYears*365, GetDate())
	
	Declare @LogDeleteThreshold datetime
	Set @LogDeleteThreshold = DateAdd(month, -@LogEntryMonthsToRetain, GetDate())
	
	---------------------------------------------------
	-- Create temporary tables to hold jobs, datasets, and experiments to delete
	---------------------------------------------------
	
	CREATE TABLE #Tmp_DatasetsToDelete (
		Dataset_ID int not null,
		Dataset varchar(128) not null,
		DS_Created datetime null
	)

	CREATE CLUSTERED INDEX #IX_Tmp_DatasetsToDelete ON #Tmp_DatasetsToDelete (Dataset_ID)
	
	CREATE TABLE #Tmp_ExperimentsToDelete (
		Exp_ID int not null,
		Experiment varchar(128) not null,
		EX_created datetime null
	)						    
	
	CREATE CLUSTERED INDEX #IX_Tmp_ExperimentsToDelete ON #Tmp_ExperimentsToDelete (Exp_ID)

	CREATE TABLE #Tmp_JobsToDelete (
		Job int not null,
		AJ_Created datetime null
	)

	CREATE CLUSTERED INDEX #IX_Tmp_JobsToDelete ON #Tmp_JobsToDelete (Job)
	
	
	---------------------------------------------------
	-- Find all datasets more than @DeleteThreshold years old
	-- Exclude datasets with a job that was created within the last @JobKeepThreshold years
	---------------------------------------------------
	
	IF @DeleteDatasets > 0
	Begin
		INSERT INTO #Tmp_DatasetsToDelete (Dataset_ID, Dataset, DS_Created)
		SELECT TOP (@MaxItemsToProcess) Dataset_ID,
			Dataset_Num,
			DS_created
		FROM T_Dataset
		WHERE (DS_created < @DeleteThreshold) AND
		    NOT Dataset_Num Like 'DataPackage_[0-9]%' AND
			NOT Dataset_Num IN ( SELECT Value
								FROM dbo.udfParseDelimitedList ( @DatasetSkipList, ',', 'DeleteOldDataExperimentsJobsAndLogs') 
								) AND
			NOT Dataset_Num IN ( SELECT DISTINCT DS.Dataset_Num
								FROM T_Dataset DS INNER JOIN
										T_Analysis_Job AJ ON DS.Dataset_ID = AJ.AJ_datasetID
								WHERE AJ_Created >= @JobKeepThreshold
								)
		ORDER BY DS_created         
		--
		Select @myRowCount = @@RowCount, @myError = @@Error
	End

	---------------------------------------------------
	-- Find Experiments to delete
	---------------------------------------------------
	If @DeleteExperiments > 0
	Begin
		INSERT INTO #Tmp_ExperimentsToDelete (Exp_ID, Experiment, EX_created)
		SELECT TOP (@MaxItemsToProcess)  
				E.Exp_ID,
				E.Experiment_Num,
				E.EX_created
		FROM T_Experiments E
		WHERE E.Experiment_Num NOT IN ('Placeholder', 'DMS_Pipeline_Data') AND
			E.EX_created < @DeleteThreshold AND
			NOT Experiment_Num IN ( SELECT Value
									FROM dbo.udfParseDelimitedList ( @ExperimentSkipList, ',', 'DeleteOldDataExperimentsJobsAndLogs') 
									) AND
			NOT Experiment_Num IN ( SELECT E.Experiment_Num
									FROM T_Dataset DS
										INNER JOIN T_Experiments E
											ON DS.Exp_ID = E.Exp_ID
										LEFT OUTER JOIN #Tmp_DatasetsToDelete DSDelete
											ON DS.Dataset_ID = DSDelete.Dataset_ID
									WHERE DSDelete.Dataset_ID Is Null
									)
		GROUP BY E.Exp_ID,
				E.Experiment_Num,
				E.EX_created
		ORDER BY E.EX_created
		--
		Select @myRowCount = @@RowCount, @myError = @@Error
	End
	
	---------------------------------------------------
	-- Find Jobs that correspond to datasets in #Tmp_DatasetsToDelete
	---------------------------------------------------
	If @DeleteJobs > 0
	Begin
	
		INSERT INTO #Tmp_JobsToDelete (Job, AJ_Created)
		SELECT TOP (@MaxItemsToProcess) J.AJ_JobID,
			J.AJ_Created
		FROM #Tmp_DatasetsToDelete DS
			INNER JOIN T_Analysis_Job J
			ON DS.Dataset_ID = J.AJ_DatasetID
		ORDER BY J.AJ_JobID
		--
		Select @myRowCount = @@RowCount, @myError = @@Error
		
		---------------------------------------------------
		-- Append jobs that finished prior to @DeleteThreshold
		---------------------------------------------------
		
		Declare @MaxItemsToAppend int
		If @MaxItemsToProcess > 0
		Begin
			SELECT @myRowCount = COUNT(*)
			FROM #Tmp_JobsToDelete
			
			Set @MaxItemsToAppend = @MaxItemsToProcess - @myRowCount
		End
		Else
			Set @MaxItemsToAppend = 1000000
		--
		If @MaxItemsToAppend > 0
		Begin
			INSERT INTO #Tmp_JobsToDelete (Job, AJ_Created)
			SELECT TOP (@MaxItemsToAppend) AJ_JobID,
				AJ_Created
			FROM T_Analysis_Job
			WHERE Coalesce(AJ_Finish, AJ_Start, AJ_created) < @DeleteThreshold AND
				NOT AJ_JobID IN (SELECT Job FROM #Tmp_JobsToDelete)
			ORDER BY AJ_JobID
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
		End
		
	End



	If @infoOnly <> 0
	Begin
		-- Preview all of the datasets and experiments that would be deleted
		SELECT Dataset_ID, Dataset as [Dataset To Delete], DS_Created AS Created
		FROM #Tmp_DatasetsToDelete
		ORDER BY Dataset_ID Desc
		
		SELECT E.Exp_ID,
		       E.Experiment AS [Experiment To Delete],
		       E.EX_Created AS Created,
		       CASE
		           WHEN EG.Group_ID IS NULL THEN ''
		           ELSE 'Note: parent of experiment group ' + Convert(varchar(12), EG.Group_ID) + '; experiment may not get deleted'
		       END AS Note
		FROM #Tmp_ExperimentsToDelete E
		     LEFT OUTER JOIN T_Experiment_Groups EG
		  ON E.Exp_ID = EG.Parent_Exp_ID
		ORDER BY Exp_ID DESC

		SELECT Job AS [Job To Delete],
		       #Tmp_JobsToDelete.AJ_Created AS Created,
		       T.AJT_ToolName AS Analysis_Tool
		FROM #Tmp_JobsToDelete
		     INNER JOIN T_Analysis_Job J
		       ON #Tmp_JobsToDelete.Job = J.AJ_JobID
		     INNER JOIN T_Analysis_Tool T
		       ON J.AJ_analysisToolID = T.AJT_toolID
		ORDER BY #Tmp_JobsToDelete.Job DESC


		---------------------------------------------------
		-- Count old log messages
		---------------------------------------------------

		SELECT 'T_Log_Entries' AS Log_Table_Name, COUNT(*) AS [Rows To Delete]
		FROM T_Log_Entries
		WHERE posting_Time < @LogDeleteThreshold
		UNION
		SELECT 'T_Event_Log' AS Log_Table_Name, COUNT(*) AS [Rows To Delete]
		FROM T_Event_Log
		WHERE Entered < @LogDeleteThreshold
		UNION
		SELECT 'T_Usage_Log' AS Log_Table_Name, COUNT(*) AS [Rows To Delete]
		FROM T_Usage_Log
		WHERE Posting_Time < @LogDeleteThreshold
		UNION
		SELECT 'T_Predefined_Analysis_Scheduling_Queue' AS Log_Table_Name, COUNT(*) AS [Rows To Delete]
		FROM T_Predefined_Analysis_Scheduling_Queue
		WHERE Entered < @LogDeleteThreshold
		UNION
		SELECT 'T_Analysis_Job_Status_History' AS Log_Table_Name, COUNT(*) AS [Rows To Delete]
		FROM T_Analysis_Job_Status_History
		WHERE Posting_Time < @LogDeleteThreshold
			
		Goto Done		
	End



	---------------------------------------------------
	-- Delete jobs and related data
	---------------------------------------------------
	
	Select @myRowCount = COUNT(*)
	FROM #Tmp_JobsToDelete
	
	If @myRowCount > 0 And @DeleteJobs > 0
	Begin -- <a>
		Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' jobs from: '

		BEGIN TRY 		
			
			/*
			---------------------------------------------------
			-- Deprecated in Summer 2015: 
			Set @CurrentLocation = 'DELETE T_Analysis_Job_Annotations'	
			DELETE T_Analysis_Job_Annotations
			FROM #Tmp_JobsToDelete
				INNER JOIN T_Analysis_Job_Annotations
				ON #Tmp_JobsToDelete.Job = T_Analysis_Job_Annotations.Job_ID
			--
			Set @message = @message + 'T_Analysis_Job_Annotations, '
			*/
			
			/*
			---------------------------------------------------
			-- Deprecated in May 2015: 
			Set @CurrentLocation = 'DELETE T_Analysis_Job_Processor_Group_Associations'	
			DELETE T_Analysis_Job_Processor_Group_Associations
			FROM #Tmp_JobsToDelete
				INNER JOIN T_Analysis_Job_Processor_Group_Associations
				ON #Tmp_JobsToDelete.Job = T_Analysis_Job_Processor_Group_Associations.Job_ID
			--
			Set @message = @message + 'T_Analysis_Job_Processor_Group_Associations, '
			*/
			
			Set @CurrentLocation = 'DELETE T_Analysis_Job_PSM_Stats'	
			DELETE T_Analysis_Job_PSM_Stats
			FROM #Tmp_JobsToDelete
				INNER JOIN T_Analysis_Job_PSM_Stats
				ON #Tmp_JobsToDelete.Job = T_Analysis_Job_PSM_Stats.Job
			--
			Set @message = @message + 'T_Analysis_Job_PSM_Stats'
			

			-- Disable the trigger that prevents all rows from being deleted
			ALTER TABLE T_Analysis_Job DISABLE TRIGGER trig_ud_T_Analysis_Job
			
			Set @CurrentLocation = 'DELETE T_Analysis_Job'	
			DELETE T_Analysis_Job
			FROM #Tmp_JobsToDelete
				INNER JOIN T_Analysis_Job
				ON #Tmp_JobsToDelete.Job = T_Analysis_Job.AJ_JobID
			--
			Set @message = @message + ' and T_Analysis_Job'
		
			Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'

			ALTER TABLE T_Analysis_Job Enable TRIGGER trig_ud_T_Analysis_Job


			-- Delete orphaned entries in T_Analysis_Job_Batches that are older than @DeleteThreshold
			-- The following index helps to speed this delete
			--
			If Not Exists (SELECT * FROM sys.indexes WHERE NAME = 'IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job')
			Begin
				Set @CurrentLocation = 'CREATE Index IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job'	
				CREATE NONCLUSTERED INDEX IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job
				ON dbo.T_Analysis_Job ([AJ_batchID])
				INCLUDE ([AJ_jobID])
			End
			
			Set @CurrentLocation = 'DELETE T_Analysis_Job_Batches'	
			DELETE T_Analysis_Job_Batches
			FROM T_Analysis_Job_Batches AJB
			     LEFT OUTER JOIN T_Analysis_Job AJ
			       ON AJ.AJ_batchID = AJB.Batch_ID
			WHERE (AJ.AJ_jobID IS NULL) AND
			      (AJB.Batch_Created < @DeleteThreshold)
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
			
			If @myRowCount > 0
			Begin
				Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' entries from T_Analysis_Job_Batches since orphaned and older than ' + Convert(varchar(24), @DeleteThreshold)
				Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			End

			Set @CurrentLocation = 'DROP Index IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job'	
			DROP INDEX IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job ON T_Analysis_Job


			-- Delete orphaned entries in T_Analysis_Job_Request that are older than @DeleteThreshold
			--
			Set @CurrentLocation = 'DELETE T_Analysis_Job_Request'	
			DELETE T_Analysis_Job_Request
			FROM T_Analysis_Job_Request AJR
			     LEFT OUTER JOIN T_Analysis_Job AJ
			       ON AJR.AJR_requestID = AJ.AJ_requestID
			WHERE (AJ.AJ_jobID IS NULL) AND
			      (AJR.AJR_created < @DeleteThreshold)
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
			
			If @myRowCount > 0
			Begin
				Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' entries from T_Analysis_Job_Request since orphaned and older than ' + Convert(varchar(24), @DeleteThreshold)
				Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			End
			
			-- Delete orphaned entries in T_Analysis_Job_ID that are older than @LogDeleteThreshold
			--
			Set @CurrentLocation = 'DELETE T_Analysis_Job_ID'	
			DELETE T_Analysis_Job_ID
			FROM T_Analysis_Job_ID JobIDs
			     LEFT OUTER JOIN T_Analysis_Job J
			       ON JobIDs.ID = J.AJ_jobID
			WHERE (NOT (JobIDs.Note LIKE '%broker%')) AND
			      (J.AJ_jobID IS NULL) AND
			      (JobIDs.Created < @LogDeleteThreshold)
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
			
			If @myRowCount > 0
			Begin
				Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' entries from T_Analysis_Job_ID since orphaned and older than ' + Convert(varchar(24), @LogDeleteThreshold)
				Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			End
			
			
		END TRY
		BEGIN CATCH 
			-- Error caught
			Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'DeleteOldDataExperimentsJobsAndLogs')
					exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 0, 
											@ErrorNum = @myError output, @message = @message output
											
			Set @message = 'Exception deleting jobs: ' + @message
			print @message
			Goto Done
		END CATCH
	
	End -- </a>
		
	---------------------------------------------------
	-- Deleted datasets and related data
	---------------------------------------------------

	Select @myRowCount = COUNT(*)
	FROM #Tmp_DatasetsToDelete
	
	If @myRowCount > 0 And @DeleteDatasets > 0
	Begin -- <b>
		Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' datasets from: '

		BEGIN TRY 
			
			-- Make sure no jobs are defined for any of these datasets
			-- Abort if there are
			IF EXISTS (SELECT * FROM T_Analysis_Job J INNER JOIN #Tmp_DatasetsToDelete D ON J.AJ_DatasetID = D.Dataset_ID)
			Begin
				Set @message = 'Cannot delete dataset since job exists'
				SELECT @message AS ErrorMessage,
				       D.Dataset,
				       J.*
				FROM T_Analysis_Job J
				     INNER JOIN #Tmp_DatasetsToDelete D
				       ON J.AJ_DatasetID = D.Dataset_ID
				
				Goto Done
			End
			
			Set @CurrentLocation = 'DELETE T_Dataset_QC'	
			DELETE T_Dataset_QC
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Dataset_QC
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Dataset_QC.Dataset_ID
			--
			Set @message = @message + 'T_Dataset_QC, '
			
			/*
			---------------------------------------------------
			-- Deprecated in Summer 2015: 
			Set @CurrentLocation = 'DELETE T_Dataset_Annotations'
			DELETE T_Dataset_Annotations
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Dataset_Annotations
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Dataset_Annotations.Dataset_ID
			--
			Set @message = @message + 'T_Dataset_Annotations, '
			*/
			
			Set @CurrentLocation = 'DELETE T_Dataset_Archive'
			DELETE T_Dataset_Archive
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Dataset_Archive
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
			--
			Set @message = @message + 'T_Dataset_Archive, '
			 
			 
			Set @CurrentLocation = 'DELETE T_Dataset_Info'
			DELETE T_Dataset_Info
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Dataset_Info
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Dataset_Info.Dataset_ID
			--
			Set @message = @message + 'T_Dataset_Info, '
			 
			 
			Set @CurrentLocation = 'DELETE T_Dataset_Storage_Move_Log'
			DELETE T_Dataset_Storage_Move_Log
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Dataset_Storage_Move_Log
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Dataset_Storage_Move_Log.DatasetID
			--
			Set @message = @message + 'T_Dataset_Storage_Move_Log, '
			
			       
			Set @CurrentLocation = 'DELETE T_Requested_Run'
			DELETE T_Requested_Run
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Requested_Run
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Requested_Run.DatasetID
			--
			Set @message = @message + 'T_Requested_Run, '
		
			Set @CurrentLocation = 'DELETE T_Prep_LC_Run_Dataset'
			DELETE T_Prep_LC_Run_Dataset
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Prep_LC_Run_Dataset
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Prep_LC_Run_Dataset.Dataset_ID
			--
			Set @message = @message + 'T_Prep_LC_Run_Dataset, '
			
			
			-- Disable the trigger that prevents all rows from being deleted
			ALTER TABLE T_Dataset DISABLE TRIGGER trig_ud_T_Dataset
			
			Set @CurrentLocation = 'DELETE T_Dataset'
			DELETE T_Dataset
			FROM #Tmp_DatasetsToDelete
				INNER JOIN T_Dataset
				ON #Tmp_DatasetsToDelete.Dataset_ID = T_Dataset.Dataset_ID
			--
			Set @message = @message + ' and T_Dataset'
			
			Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			
			ALTER TABLE T_Dataset ENABLE TRIGGER trig_ud_T_Dataset
			
			-- Delete orphaned entries in T_Requested_Run that are older than @DeleteThreshold
			--
			DELETE T_Requested_Run
			FROM T_Requested_Run RR
			WHERE (RR.DatasetID IS NULL) AND
			      (RR.RDS_Created < @DeleteThreshold)
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
			
			If @myRowCount > 0
			Begin
				Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' entries from T_Requested_Run since orphaned and older than ' + Convert(varchar(24), @DeleteThreshold)
				Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			End
			
			
			-- Delete orphaned entries in T_Requested_Run_Batches that are older than @DeleteThreshold
			--
			DELETE T_Requested_Run_Batches
			FROM T_Requested_Run_Batches RRB
			     LEFT OUTER JOIN T_Requested_Run RR
			       ON RRB.ID = RR.RDS_BatchID
			WHERE (RR.RDS_BatchID IS NULL) AND
			      (RRB.Created < @DeleteThreshold)
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
			
			If @myRowCount > 0
			Begin
				Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' entries from T_Requested_Run_Batches since orphaned and older than ' + Convert(varchar(24), @DeleteThreshold)
				Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			End

			-- Delete orphaned entries in T_Dataset_ScanTypes
			--
			DELETE T_Dataset_ScanTypes
			FROM T_Dataset_ScanTypes ST
			   LEFT OUTER JOIN T_Dataset DS
			       ON ST.Dataset_ID = DS.Dataset_ID
			WHERE (DS.Dataset_ID IS NULL)
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
			
			If @myRowCount > 0
			Begin
				Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' entries from T_Dataset_ScanTypes since orphaned'
				Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			End
			

		END TRY
		BEGIN CATCH 
			-- Error caught
			Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'DeleteOldDataExperimentsJobsAndLogs')
					exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 0, 
											@ErrorNum = @myError output, @message = @message output
											
			Set @message = 'Exception deleting datasets: ' + @message
			print @message
			Goto Done
		END CATCH
	
	End -- </b>
	

	---------------------------------------------------
	-- Delete experiments and related data
	---------------------------------------------------
	
	Select @myRowCount = COUNT(*)
	FROM #Tmp_ExperimentsToDelete
	
	If @myRowCount > 0 And @DeleteDatasets > 0 And @DeleteExperiments > 0
	Begin -- <c>
		Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' experiments from: '

		BEGIN TRY 
		
			-- Delete experiments in #Tmp_ExperimentsToDelete that are still in T_Requested_Run
			DELETE #Tmp_ExperimentsToDelete
			FROM #Tmp_ExperimentsToDelete E
			     INNER JOIN T_Requested_Run RR
			       ON E.Exp_ID = RR.Exp_ID
		
			Set @CurrentLocation = 'DELETE T_Experiment_Cell_Cultures'	
			DELETE T_Experiment_Cell_Cultures
			FROM #Tmp_ExperimentsToDelete
				INNER JOIN T_Experiment_Cell_Cultures
				ON #Tmp_ExperimentsToDelete.Exp_ID = T_Experiment_Cell_Cultures.Exp_ID
			--
			Set @message = @message + 'T_Experiment_Cell_Cultures, '

			
			Set @CurrentLocation = 'DELETE T_Experiment_Group_Members'	
			DELETE T_Experiment_Group_Members
			FROM #Tmp_ExperimentsToDelete
				INNER JOIN T_Experiment_Group_Members
				ON #Tmp_ExperimentsToDelete.Exp_ID = T_Experiment_Group_Members.Exp_ID
			--
			Set @message = @message + 'T_Experiment_Group_Members, '

			Set @CurrentLocation = 'DELETE T_Experiment_Groups'
			DELETE T_Experiment_Groups
			FROM #Tmp_ExperimentsToDelete
			     INNER JOIN T_Experiment_Groups
			       ON #Tmp_ExperimentsToDelete.Exp_ID = T_Experiment_Groups.Parent_Exp_ID
			WHERE NOT T_Experiment_Groups.Group_ID IN ( SELECT DISTINCT Group_ID
			                                            FROM T_Experiment_Group_Members )
			--
			Set @message = @message + 'T_Experiment_Groups, '
			
			Set @CurrentLocation = 'DELETE T_Experiments'
			DELETE T_Experiments
			FROM #Tmp_ExperimentsToDelete
				INNER JOIN T_Experiments
				ON #Tmp_ExperimentsToDelete.Exp_ID = T_Experiments.Exp_ID
			WHERE Not T_Experiments.Exp_ID IN ( SELECT DISTINCT Parent_Exp_ID
			                                            FROM T_Experiment_Groups )
			--
			Set @message = @message + ' and T_Experiments'
		
			Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'

			
			-- Delete orphaned entries in T_Experiment_Groups
			--
			DELETE T_Experiment_Groups
			FROM T_Experiment_Groups EG LEFT OUTER JOIN
				T_Experiment_Group_Members EGM ON EG.Group_ID = EGM.Group_ID
			WHERE (EGM.Group_ID IS NULL) AND
			      (EG.EG_Created < @DeleteThreshold)
			--
			Select @myRowCount = @@RowCount, @myError = @@Error
			
			If @myRowCount > 0
			Begin
				Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' entries from T_Experiment_Groups since orphaned and older than ' + Convert(varchar(24), @DeleteThreshold)
				Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
			End
			
			
		END TRY
		BEGIN CATCH 
			-- Error caught
			Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'DeleteOldDataExperimentsJobsAndLogs')
					exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 0, 
											@ErrorNum = @myError output, @message = @message output
											
			Set @message = 'Exception deleting experiments: ' + @message
			print @message
			Goto Done
		END CATCH
	
	End -- </c>

	

	---------------------------------------------------
	-- Delete orphaned Aux_Info entries
	---------------------------------------------------

	-- Experiments (Target_Type_ID = 500)
	--	
	DELETE T_AuxInfo_Value
	FROM T_AuxInfo_Category AIC
	     INNER JOIN T_AuxInfo_Subcategory Subcat
	       ON AIC.ID = Subcat.Parent_ID
	     INNER JOIN T_AuxInfo_Description Descrip
	       ON Subcat.ID = Descrip.Parent_ID
	     INNER JOIN T_AuxInfo_Value AIVal
	       ON Descrip.ID = AIVal.AuxInfo_ID
	     LEFT OUTER JOIN T_Experiments E
	       ON AIVal.Target_ID = E.Exp_ID
	WHERE (AIC.Target_Type_ID = 500) AND
	      (E.Experiment_Num IS NULL) AND
	      (AIVal.Target_ID > 0)
	--
	Select @myRowCount = @@RowCount, @myError = @@Error
	
	If @myRowCount > 0
	Begin
		Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' experiment related entries from T_AuxInfo_Value since orphaned'
		Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
	End


	-- Cell Cultures (Target_Type_ID = 501)
	--	
	DELETE T_AuxInfo_Value
	FROM T_AuxInfo_Category AIC
	     INNER JOIN T_AuxInfo_Subcategory Subcat
	       ON AIC.ID = Subcat.Parent_ID
	  INNER JOIN T_AuxInfo_Description Descrip
	       ON Subcat.ID = Descrip.Parent_ID
	     INNER JOIN T_AuxInfo_Value AIVal
	       ON Descrip.ID = AIVal.AuxInfo_ID
	     LEFT OUTER JOIN T_Cell_Culture
	       ON AIVal.Target_ID = T_Cell_Culture.CC_ID
	WHERE (AIC.Target_Type_ID = 501) AND
	      (AIVal.Target_ID > 0) AND
	     (T_Cell_Culture.CC_ID IS NULL)
	--
	Select @myRowCount = @@RowCount, @myError = @@Error
	
	If @myRowCount > 0
	Begin
		Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' cell culture related entries from T_AuxInfo_Value since orphaned'
		Exec PostLogEntry 'Normal', @message, 'DeleteOldDataExperimentsJobsAndLogs'
	End

	-- Datasets (Target_Type_ID = 502)
	-- Note that although DMS supports Aux_Info for datasets, it has never been used
	-- Thus, we'll skip this query
	--	
	
	--DELETE T_AuxInfo_Value
	--FROM T_AuxInfo_Category AIC
	--     INNER JOIN T_AuxInfo_Subcategory Subcat
	--       ON AIC.ID = Subcat.Parent_ID
	--     INNER JOIN T_AuxInfo_Description Descrip
	--     ON Subcat.ID = Descrip.Parent_ID
	--     INNER JOIN T_AuxInfo_Value AIVal
	--       ON Descrip.ID = AIVal.AuxInfo_ID
	--     LEFT OUTER JOIN T_Dataset
	--       ON AIVal.Target_ID = T_Dataset.Dataset_ID
	--WHERE (AIC.Target_Type_ID = 502) AND
	--      (AIVal.Target_ID > 0) AND
	--      (T_Dataset.Dataset_ID IS NULL)
	
	
	
	---------------------------------------------------
	-- Delete old entries in various tables
	---------------------------------------------------

	DELETE
	FROM T_Predefined_Analysis_Scheduling_Queue
	WHERE (Entered < @LogDeleteThreshold)

	DELETE
	FROM T_Analysis_Job_Status_History
	WHERE (Posting_Time < @LogDeleteThreshold)

	---------------------------------------------------
	-- Delete old log messages
	---------------------------------------------------

	DELETE T_Log_Entries
	WHERE posting_Time < @LogDeleteThreshold

	DELETE T_Event_Log
	WHERE Entered < @LogDeleteThreshold

	DELETE T_Usage_Log
	WHERE Posting_Time < @LogDeleteThreshold
	
	
Done:

	Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[DeleteOldDataExperimentsJobsAndLogs] TO [DDL_Viewer] AS [dbo]
GO

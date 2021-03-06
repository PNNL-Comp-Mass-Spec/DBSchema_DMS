/****** Object:  StoredProcedure [dbo].[ValidateJobDatasetStates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.ValidateJobDatasetStates
/****************************************************
**
**	Desc:	Validates job and dataset states vs. DMS_Pipeline and DMS_Capture
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	11/11/2016 mem - Initial Version
**			01/30/2017 mem - Switch from DateDiff to DateAdd
**
*****************************************************/
(
	@infoOnly tinyint = 0
)
AS

	Set NoCount On

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @itemList varchar(1024)
	Declare @message varchar(1024)
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try

		Set @infoOnly = IsNull(@infoOnly, 0)
		
		CREATE TABLE #Tmp_Datasets (
			Dataset_ID int not null,
			State_Old int not null,
			State_New int not null
		)
		
		CREATE TABLE #Tmp_Jobs (
			Job int not null,
			State_Old int not null,
			State_New int not null
		)
		
		---------------------------------------------------
		-- Look for datasets with an incorrect state
		---------------------------------------------------
		--
		Set @CurrentLocation = 'Populate #Tmp_Datasets'
		
		-- Find datasets with a complete DatasetCapture task, yet a state of 1 or 2 in DMS5
		-- Exclude datasets that finished within the last 2 hours
		--
		INSERT INTO #Tmp_Datasets (Dataset_ID, State_Old, State_New)
		SELECT DS.Dataset_ID, DS.DS_state_ID, PipelineQ.NewState
		FROM T_Dataset DS
		     INNER JOIN ( SELECT Dataset_ID, State AS NewState
		                  FROM S_V_Capture_Jobs_ActiveOrComplete
		                  WHERE Script = 'DatasetCapture' AND
		                        State = 3 AND
		                        Finish < DateAdd(Hour, -1, GetDate()) 
		                ) PipelineQ
		       ON DS.Dataset_ID = PipelineQ.Dataset_ID
		WHERE DS.DS_state_ID IN (1, 2)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		---------------------------------------------------
		-- Look for analysis jobs with an incorrect state
		---------------------------------------------------
		--
		Set @CurrentLocation = 'Populate #Tmp_Jobs'

		-- Find jobs complete in DMS_Pipeline, yet a state of 1, 2, or 8 in DMS5
		-- Exclude jobs that finished within the last 2 hours
		--
		INSERT INTO #Tmp_Jobs (Job, State_Old, State_New)
		SELECT J.AJ_jobID, J.AJ_StateID, PipelineQ.NewState
		FROM T_Analysis_Job J
		     INNER JOIN ( SELECT Job, State AS NewState
		                  FROM S_V_Pipeline_Jobs_ActiveOrComplete
		                  WHERE State IN (4, 7, 14) AND
		                        Finish < DateAdd(Hour, -1, GetDate()) 
		                ) PipelineQ
		       ON J.AJ_jobID = PipelineQ.Job
		WHERE (J.AJ_StateID IN (1, 2, 8))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
				
		If @infoOnly <> 0
		Begin -- <Preview>
			Set @CurrentLocation = 'Preview the updates'
			
			SELECT Src.*,
			       DS.Dataset_Num AS Dataset
			FROM #Tmp_Datasets Src
			     INNER JOIN T_Dataset DS
			       ON Src.Dataset_ID = DS.Dataset_ID
			
			SELECT Src.*,
			       T.AJT_toolName AS Tool,
			       DS.Dataset_Num AS Dataset
			FROM #Tmp_Jobs Src
			     INNER JOIN T_Analysis_Job J
			       ON Src.Job = J.AJ_JobID
			     INNER JOIN T_Analysis_Tool T
			       ON J.AJ_analysisToolID = T.AJT_toolID
			     INNER JOIN T_Dataset DS
			       ON J.AJ_datasetID = DS.Dataset_ID
			
		End -- </Preview>
		Else
		Begin -- <ApplyChanges>
			-- Update items
			If Exists (Select * FROM #Tmp_Datasets)
			Begin -- <datasets>
				Set @CurrentLocation = 'Update datasets'

				UPDATE T_Dataset
				SET DS_state_ID = Src.State_New
				FROM T_Dataset Target
				     INNER JOIN #Tmp_Datasets Src
				       ON Src.Dataset_ID = Target.Dataset_ID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				-- Log the update
				--
				Set @itemList = ''
				SELECT @itemList = @itemList + Cast(Dataset_ID as varchar(9)) + ','
				FROM #Tmp_Datasets
				ORDER BY Dataset_ID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				-- Remove the trailing comma
				Set @itemList = Left(@itemList, Len(@itemList)-1)
								
				Set @message = 'Updated dataset state for dataset ' +  dbo.CheckPlural(@myRowCount, 'ID ', 'IDs ') + @itemList + ' due to mismatch with DMS_Capture'
				exec PostLogEntry 'Warning', @message, 'ValidateJobDatasetStates'
			End -- </datasets>
			
			If Exists (Select * FROM #Tmp_Jobs)
			Begin -- <jobs>
				Set @CurrentLocation = 'Update analysis jobs'

				UPDATE T_Analysis_Job
				SET AJ_StateID = Src.State_New
				FROM T_Analysis_Job Target
				     INNER JOIN #Tmp_Jobs Src
				       ON Src.Job = Target.AJ_JobID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount

				-- Log the update
				--
				Set @itemList = ''
				SELECT @itemList = @itemList + Cast(Job as varchar(9))  + ','
				FROM #Tmp_Jobs
				ORDER BY Job
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				-- Remove the trailing comma
				Set @itemList = Left(@itemList, Len(@itemList)-1)
				
				Set @message = 'Updated job state for ' +  dbo.CheckPlural(@myRowCount, 'job ', 'jobs ') + @itemList + ' due to mismatch with DMS_Pipeline'
				exec PostLogEntry 'Warning', @message, 'ValidateJobDatasetStates'					
			End -- </jobs>
			
		End -- </ApplyChanges>
		
	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'ValidateJobDatasetStates')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch


Done:
	Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[ValidateJobDatasetStates] TO [DDL_Viewer] AS [dbo]
GO

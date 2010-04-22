/****** Object:  StoredProcedure [dbo].[HoldJobsForPurgedDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.HoldJobsForPurgedDatasets
/****************************************************
**
**	Desc:	Updates the job state to 8=Holding for jobs
**			associated with purged dataset
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	05/15/2008 (Ticket #670)
**			05/22/2008 mem - Now updating comment for any jobs that are set to state 8 (Ticket #670)
**
*****************************************************/
(
	@InfoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	Declare @HoldMessage varchar(128)
	Set @HoldMessage = '; holding since dataset purged'
	
	CREATE TABLE #Tmp_JobsToUpdate (
		Job int NOT NULL
	)
	
	INSERT INTO #Tmp_JobsToUpdate (Job)
	SELECT AJ_JobID
	FROM dbo.T_Analysis_Job
	WHERE (AJ_StateID = 1) AND
	      (AJ_datasetID IN ( SELECT DISTINCT Target_ID
	                         FROM dbo.T_Event_Log
	                         WHERE (Target_Type = 6) AND
	                               (Target_State = 4) ))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	If @myRowCount = 0
	Begin
		If @InfoOnly <> 0
			SELECT 'No jobs having purged datasets were found with state 1=New' AS Message
	End
	Else
	Begin
		If @InfoOnly <> 0
		Begin
			SELECT AJ.AJ_jobID AS Job,
			       AJ.AJ_created AS Created,
			       AJ.AJ_analysisToolID AS AnalysisToolID,
			       IsNull(AJ.AJ_comment, '') + @HoldMessage AS Comment,
			       AJ.AJ_StateID AS StateID,
			       DS.Dataset_Num AS Dataset,
			       DS.DS_created AS Dataset_Created,
			       DFP.Dataset_Folder_Path,
			       DFP.Archive_Folder_Path
			FROM #Tmp_JobsToUpdate JTU
			     INNER JOIN dbo.T_Analysis_Job AJ
			       ON JTU.Job = AJ.AJ_JobID AND
			          AJ.AJ_StateID = 1
			     INNER JOIN dbo.T_Dataset DS
			       ON AJ.AJ_datasetID = DS.Dataset_ID
			     INNER JOIN dbo.V_Dataset_Folder_Paths DFP
			       ON DS.Dataset_ID = DFP.Dataset_ID
		End
   		Else
   		Begin
			UPDATE dbo.T_Analysis_Job
			SET AJ_StateID = 8,
				AJ_Comment = AJ_Comment + @HoldMessage
			FROM dbo.T_Analysis_Job AJ
			     INNER JOIN #Tmp_JobsToUpdate JTU
			       ON JTU.Job = AJ.AJ_JobID AND
			          AJ.AJ_StateID = 1
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount > 0 
				Set @message = 'Placed ' + Convert(varchar(12), @myRowCount) + ' jobs on hold since their associated dataset is purged'
		End
	End
	
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[HoldJobsForPurgedDatasets] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[HoldJobsForPurgedDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[HoldJobsForPurgedDatasets] TO [PNL\D3M580] AS [dbo]
GO

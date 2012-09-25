/****** Object:  StoredProcedure [dbo].[MarkPurgedJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.MarkPurgedJobs
/****************************************************
** 
**	Desc:	Updates AJ_Purged to be 1 for the jobs in @JobList
**			This procedure is called by the SpaceManager
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	06/13/2012
**    
*****************************************************/
(
	@JobList varchar(4000),
	@InfoOnly tinyint = 1
)
As
	Set nocount on
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	---------------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------------
	--

	Set @JobList = IsNull(@JobList, '')
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	
	---------------------------------------------------------
	-- Populate a temporary table with the jobs in @JobList
	---------------------------------------------------------
	--
	CREATE TABLE #Tmp_JobList (
		Job int
	)
	
	INSERT INTO #Tmp_JobList (Job)
	SELECT Value
	FROM dbo.udfParseDelimitedIntegerList(@JobList, ',')
	
	If @InfoOnly <> 0
	Begin
		-- Preview the jobs
		--
		SELECT J.AJ_JobID AS Job, J.AJ_Purged as Job_Purged
		FROM T_Analysis_Job J INNER JOIN 
			 #Tmp_JobList L ON J.AJ_JobID = L.Job
		ORDER BY AJ_JobID
	End
	Else
	Begin
		-- Update AJ_Purged
		--
		UPDATE T_Analysis_Job
		SET AJ_Purged = 1
		FROM T_Analysis_Job J INNER JOIN 
			 #Tmp_JobList L ON J.AJ_JobID = L.Job
		WHERE J.AJ_Purged = 0
		
	End
	
Done:
	Return @myError

GO
GRANT EXECUTE ON [dbo].[MarkPurgedJobs] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MarkPurgedJobs] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MarkPurgedJobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MarkPurgedJobs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MarkPurgedJobs] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MarkPurgedJobs] TO [svc-dms] AS [dbo]
GO

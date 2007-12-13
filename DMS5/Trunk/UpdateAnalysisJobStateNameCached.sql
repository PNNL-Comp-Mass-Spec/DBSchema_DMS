/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobStateNameCached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure dbo.UpdateAnalysisJobStateNameCached
/****************************************************
**
**	Desc: Updates column AJ_StateNameCached in T_Analysis_Job
**		  for 1 or more jobs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	12/12/2007 mem - Initial version (Ticket #585)
**
*****************************************************/
(
	@JobStart int = 0,
	@JobFinish int = 0,
   	@message varchar(512) = '' output,
   	@infoOnly tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	Set @JobStart = IsNull(@JobStart, 0)
	Set @JobFinish = IsNull(@JobFinish, 0)
	set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	If @JobFinish = 0
		Set @JobFinish = 2147483647


	---------------------------------------------------
	-- Update the specified jobs
	---------------------------------------------------
	If @infoOnly <> 0
	Begin
		SELECT	AJ.AJ_jobID AS Job,
				AJ.AJ_StateNameCached AS State_Name_Cached,
				AJDAS.Job_State AS New_State_Name_Cached
		FROM dbo.T_Analysis_Job AJ INNER JOIN 
		     dbo.V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job
		WHERE (AJ.AJ_jobID >= @JobStart) AND
			  (AJ.AJ_jobID <= @JobFinish) AND
			  ISNULL(AJ.AJ_StateNameCached, '') <> IsNull(AJDAS.Job_State, '')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
			Set @message = 'All jobs have up-to-date cached job state names'
		else
			Set @message = 'Found ' + Convert(varchar(12), @myRowCount) + ' jobs to update'
	End
	Else
	Begin
		UPDATE T_Analysis_Job
		SET AJ_StateNameCached = IsNull(AJDAS.Job_State, '')
		FROM dbo.T_Analysis_Job AJ INNER JOIN
			 dbo.V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job
		WHERE (AJ.AJ_jobID >= @JobStart) AND 
			  (AJ.AJ_jobID <= @JobFinish) AND
			  IsNull(AJ_StateNameCached, '') <> IsNull(AJDAS.Job_State, '')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
			Set @message = ''
		else
			Set @message = ' Updated the cached job state name for ' + Convert(varchar(12), @myRowCount) + ' jobs'
	End

	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:
	return @myError


GO

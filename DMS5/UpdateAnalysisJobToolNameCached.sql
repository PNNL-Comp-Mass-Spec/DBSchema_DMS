/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobToolNameCached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateAnalysisJobToolNameCached
/****************************************************
**
**	Desc: Updates column AJ_ToolNameCached in T_Analysis_Job
**		  for 1 or more jobs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	04/03/2014 mem - Initial version
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
	
	Declare @JobCount int = 0

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
				AJ.AJ_ToolNameCached AS Tool_Name_Cached,
				AnalysisTool.AJT_toolName AS New_Tool_Name_Cached
		FROM dbo.T_Analysis_Job AJ INNER JOIN 
		     dbo.T_Analysis_Tool AnalysisTool ON AJ.AJ_AnalysisToolID = AnalysisTool.AJT_ToolId
		WHERE (AJ.AJ_jobID >= @JobStart) AND
			  (AJ.AJ_jobID <= @JobFinish) AND
			  ISNULL(AJ.AJ_ToolNameCached, '') <> IsNull(AnalysisTool.AJT_toolName, '')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
			Set @message = 'All jobs have up-to-date cached analysis tool names'
		else
			Set @message = 'Found ' + Convert(varchar(12), @myRowCount) + ' jobs to update'
			
		SELECT @message as Message
	End
	Else
	Begin
		UPDATE T_Analysis_Job
		SET AJ_ToolNameCached = IsNull(AnalysisTool.AJT_toolName, '')
		FROM dbo.T_Analysis_Job AJ INNER JOIN 
		     dbo.T_Analysis_Tool AnalysisTool ON AJ.AJ_AnalysisToolID = AnalysisTool.AJT_ToolId
		WHERE (AJ.AJ_jobID >= @JobStart) AND 
			  (AJ.AJ_jobID <= @JobFinish) AND
			  IsNull(AJ_ToolNameCached, '') <> IsNull(AnalysisTool.AJT_toolName, '')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		Set @JobCount = @myRowCount

		If @JobCount = 0
			Set @message = ''
		else
			Set @message = ' Updated the cached analysis tool name for ' + Convert(varchar(12), @JobCount) + ' jobs'
	End

	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = Convert(varchar(12), @JobCount) + ' jobs updated'

	If @infoOnly = 0
		Exec PostUsageLogEntry 'UpdateAnalysisJobToolNameCached', @UsageMessage

	return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobToolNameCached] TO [DDL_Viewer] AS [dbo]
GO

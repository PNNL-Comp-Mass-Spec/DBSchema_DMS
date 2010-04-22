/****** Object:  StoredProcedure [dbo].[ResetAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.ResetAnalysisJob
/****************************************************
**
**	Desc: Resets analysis job to "new" state
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**	@jobNum					unique identifier for analysis job
**	@comment				edited comment field for record
**	
**
**		Auth: dac
**		Date: 5/18/2001
**		Mod: 07/10/2001 dac - added comment field update
**		Mod: 04/12/2005 dac - changed to set blank into assigned processor name
**		Mod: 02/27/2009 mem - Expanded @comment to varchar(512)
**    
**	NOTE: USE CAREFULLY. NO PROTECTION IN THIS PROCEDURE!!!!
*****************************************************/
(
    @jobNum varchar(32),
    @comment varchar(512)
)
As
	-- set nocount on

	declare @jobID int

	set @jobID = convert(int, @jobNum)
	-- future: this could get more complicated

	-- future: check job state for "results received"

	begin
		UPDATE T_Analysis_Job 
		SET AJ_start=NULL,
		AJ_finish = NULL,
		AJ_assignedProcessorName='',
		AJ_comment = @comment,
		AJ_resultsFolderName=NULL, 
		AJ_StateID = 1 -- "new" 
		WHERE (AJ_jobID = @jobID)
	end

	if @@rowcount <> 1
	begin
		RAISERROR ('Update operation failed',
			10, 1)
		return 53150
	end

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ResetAnalysisJob] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ResetAnalysisJob] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ResetAnalysisJob] TO [RBAC-Web_Analysis] AS [dbo]
GO

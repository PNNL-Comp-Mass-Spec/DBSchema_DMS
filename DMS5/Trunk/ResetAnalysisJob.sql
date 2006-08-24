/****** Object:  StoredProcedure [dbo].[ResetAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure ResetAnalysisJob
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
**		Mod: 7/10/2001 - added comment field update
**		Mod: 4/12/2005 - changed to set blank into assigned processor name

**    
**	NOTE: USE CAREFULLY. NO PROTECTION IN THIS PROCEDURE!!!!
*****************************************************/
(
    @jobNum varchar(32),
    @comment varchar(255)
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
GRANT EXECUTE ON [dbo].[ResetAnalysisJob] TO [RBAC-Web_Analysis]
GO

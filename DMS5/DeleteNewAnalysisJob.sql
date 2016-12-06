/****** Object:  StoredProcedure [dbo].[DeleteNewAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DeleteNewAnalysisJob
/****************************************************
**
**	Desc: Delete analysis job if it is in "new" or "failed" state
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	03/29/2001
**			02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			02/18/2008 grk - Modified to accept jobs in failed state (Ticket #723)
**			02/19/2008 grk - Modified not to call broker DB (Ticket #723)
**			09/28/2012 mem - Now allowing a job to be deleted if state 19 = "Special Proc. Waiting"
**    
*****************************************************/
(
	@jobNum varchar(32),
    @message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on
	
	declare @jobID int
	
	set @message = ''

	set @jobID = convert(int, @jobNum)
	-- future: this could get more complicated
	
	-- verify that job exists in job table
	--
	declare @state int
	set @state = 0
	--
	SELECT @state = AJ_StateID 
	FROM T_Analysis_Job 
	WHERE (AJ_jobID = @jobID)
	--
	if @state = 0
	begin
		set @message = 'Job entry "' + @jobNum + '" not in database'
		return 55322
	end

	-- verify that analysis job has state 'new', 'failed', or 'Special Proc. Waiting'
	if NOT @state IN (1,5,19)
	begin
		set @message = 'Job "' + @jobNum + '" must be in "new" or "failed" state to be deleted by user'
		return 55323
	end

	-- delete the analysis job
	--
	declare @result int
	execute @result = DeleteAnalysisJob @jobID, @callingUser
	if @result <> 0
	begin
		set @message = 'Job "' + @jobNum + '" could not be deleted'
		return 55320
	end

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteNewAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteNewAnalysisJob] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteNewAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO

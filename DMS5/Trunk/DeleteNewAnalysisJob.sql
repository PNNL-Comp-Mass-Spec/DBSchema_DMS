/****** Object:  StoredProcedure [dbo].[DeleteNewAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DeleteNewAnalysisJob
/****************************************************
**
**	Desc: Delete analysis job if it is in "new" state only
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	03/29/2001
**			02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
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

	-- verify that analysis job is still in 'new' state
	if @state <> 1
	begin
		set @message = 'Job "' + @jobNum + '" must be in "new" state to be deleted by user'
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
GRANT EXECUTE ON [dbo].[DeleteNewAnalysisJob] TO [DMS_SP_User]
GO

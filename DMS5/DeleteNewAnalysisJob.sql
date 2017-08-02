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
**			04/21/2017 mem - Added parameter @previewMode
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@jobNum varchar(32),
    @message varchar(512) output,
	@callingUser varchar(128) = '',
	@previewMode tinyint = 0
)
As
	Set nocount on
	
	Declare @jobID int

	Set @jobNum = IsNull(@jobNum, '')
	Set @message = ''
	Set @previewMode = IsNull(@previewMode, 0)	

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'DeleteNewAnalysisJob', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End
	

	Set @jobID = Try_Cast(@jobNum as int)
	
	If @jobID is null
	Begin
		Declare @msg varchar(128) = 'Job number is not numeric: ' + @jobNum
		RAISERROR (@msg, 10, 1)
		return 55321
	End

	---------------------------------------------------
	-- Verify that job exists in job table
	---------------------------------------------------
	--
	Declare @state int = 0
	--
	SELECT @state = AJ_StateID 
	FROM T_Analysis_Job 
	WHERE (AJ_jobID = @jobID)
	--
	If @state = 0
	Begin
		Set @message = 'Job entry "' + @jobNum + '" not in database'
		If @previewMode > 0
			SELECT @message
		Else
			return 55322
	End

	-- Verify that analysis job has state 'new', 'failed', or 'Special Proc. Waiting'
	If Not @state IN (0, 1, 5, 19)
	Begin
		Set @message = 'Job "' + @jobNum + '" must be in "new" or "failed" state to be deleted by user'
		return 55323
	End

	-- Delete the analysis job
	--
	Declare @result int
	execute @result = DeleteAnalysisJob @jobID, @callingUser, @previewMode
	
	If @result <> 0
	Begin
		Set @message = 'Job "' + @jobNum + '" could not be deleted'
		return 55320
	End

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteNewAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteNewAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO

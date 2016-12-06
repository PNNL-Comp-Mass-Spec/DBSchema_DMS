/****** Object:  StoredProcedure [dbo].[DeleteAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DeleteAnalysisJob
/****************************************************
**
**	Desc: Deletes given analysis job from the analysis job table
**        and all referencing tables 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	03/06/2001
**			06/09/2004 grk - added delete for analysis job request reference
**			04/07/2006 grk - eliminated job to request map table
**			02/20/2007 grk - added code to remove any job-to-group associations
**			03/16/2007 mem - Fixed bug that required 1 or more rows be deleted from T_Analysis_Job_Processor_Group_Associations (Ticket #393)
**			02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			12/31/2008 mem - Now calling DMS_Pipeline.dbo.DeleteJob
**			02/19/2008 grk - Modified not to call broker DB (Ticket #723)
**			05/28/2015 mem - No longer deleting processor group entries
**
*****************************************************/
(
    @jobNum varchar(32),
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @jobID int
	set @jobID = convert(int, @jobNum)

	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'DeleteAnalysisJob'
	begin transaction @transName

	/*
	---------------------------------------------------
	-- Deprecated in May 2015: 
	-- delete any job-to-group associations 
	-- that exist for this job
	--
	DELETE FROM T_Analysis_Job_Processor_Group_Associations
	WHERE     (Job_ID = @jobID)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete job associations operation failed', 10, 1)
		return 54452
	end
	*/
	
	-- delete analysis job
	--
	DELETE FROM T_Analysis_Job 
	WHERE (AJ_jobID = @jobID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount = 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete job operation failed', 10, 1)
		return 54451
	end

	-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
	If Len(@callingUser) > 0
	Begin
		Declare @stateID int
		Set @stateID = 0

		Exec AlterEventLogEntryUser 5, @jobID, @stateID, @callingUser
	End
	
	commit transaction @transName
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisJob] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO

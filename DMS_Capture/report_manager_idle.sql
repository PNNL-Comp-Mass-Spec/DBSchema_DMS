/****** Object:  StoredProcedure [dbo].[ReportManagerIdle] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ReportManagerIdle]
/****************************************************
**
**	Desc: 
**		Assure that no running job steps are associated with the given manager
**
**		Used by the capture task manager if a database error occurs while requesting a new job task
**		For example, a deadlock error, which can leave a job step in state 4 and
**		associated with a manager, even though the manager isn't actually running the job step
**	
**	Auth:	mem
**	Date:	08/01/2017 mem - Initial release
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**			02/02/2023 bcg - Changed from V_Job_Steps to V_Task_Steps
**
*****************************************************/
(
	@managerName varchar(128) = '',
	@infoOnly tinyint = 0,
	@message varchar(256) = '' output,
    @returnCode varchar(64) = '' output
)
As
	Set nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0

	Declare @jobNumber int = 0
	
    Set @returnCode = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'ReportManagerIdle', @raiseError = 1;
	If @authorized = 0
	Begin;
		THROW 51000, 'Access denied', 1;
	End;

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @managerName = IsNull(@managerName, '')
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''
	
	If @managerName = ''
	Begin
		Set @message = 'Manager name cannot be empty'
		RAISERROR (@message, 11, 3)
		Goto done
	End

	If Not Exists (SELECT * FROM T_Local_Processors WHERE Processor_Name = @managerName)
	Begin
		Set @message = 'Manager not found in T_Local_Processors: ' + @managerName
		RAISERROR (@message, 11, 3)
		Goto done
	End
		
	---------------------------------------------------
	-- Look for running step tasks associated with this manager
	---------------------------------------------------

	-- There should, under normal circumstances, only be one active job step (if any) for this manager
	-- If there are multiple job steps, @jobNumber will only track one of the jobs
	--
	SELECT TOP 1 @jobNumber = Job
	FROM T_Job_Steps
	WHERE Processor = @managerName AND State = 4
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	IF @myRowCount = 0
	Begin
		Set @message = 'No active job steps are associated with manager ' + @managerName
		Goto Done
	End
	
	If @infoOnly > 0
	Begin
		-- Preview the running tasks
		--
		SELECT *
		FROM V_Task_Steps
		WHERE processor = @managerName AND state = 4
		ORDER BY job, step
	End
	Else
	Begin
		-- Change task state back to 2=Enabled
		--			
		UPDATE T_Job_Steps
		SET State = 2
		WHERE Processor = @managerName AND State = 4
	 	--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		Set @message = 'Reset step task state back to 2 for job ' + cast(@jobNumber as varchar(9))
		Exec PostLogEntry 'Warning', @message, 'ReportManagerIdle'
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	If @message <> ''
		Print @message
		
    Set @returnCode = Cast(@myError As varchar(64))
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ReportManagerIdle] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportManagerIdle] TO [DMS_SP_User] AS [dbo]
GO

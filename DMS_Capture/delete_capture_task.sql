/****** Object:  StoredProcedure [dbo].[DeleteCaptureTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DeleteCaptureTask
/****************************************************
**
**	Desc:
**		Deletes the given job from T_Jobs and T_Job_Steps
**		This procedure is called by DeleteAnalysisJob in DMS5
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			09/12/2009 mem - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			09/11/2012 mem - Renamed from DeleteJob to DeleteCaptureTask
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @jobNum varchar(32),
	@callingUser varchar(128) = '',
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0
	
	declare @jobID int = convert(int, @jobNum)

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'DeleteCaptureTask', @raiseError = 1;
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	declare @transName varchar(32) = 'DeleteBrokerJob'
	
	begin transaction @transName
 
	---------------------------------------------------
	-- Delete the job dependencies
	---------------------------------------------------
	--
	DELETE FROM T_Job_Step_Dependencies
	WHERE Job = @jobID
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		--
	if @myError <> 0
	begin
		set @message = 'Error deleting T_Job_Step_Dependencies'
		goto Done
	end

   	---------------------------------------------------
	-- Delete the job parameters
	---------------------------------------------------
	--
	DELETE FROM T_Job_Parameters
	WHERE Job = @jobID
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		--
	if @myError <> 0
	begin
		set @message = 'Error deleting T_Job_Parameters'
		goto Done
	end

	---------------------------------------------------
	-- Delete the job steps
	---------------------------------------------------
	--
	DELETE FROM T_Job_Steps
	WHERE Job = @jobID
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error '
		goto Done
	end

   	---------------------------------------------------
	-- Delete the job
	---------------------------------------------------
	--
	DELETE FROM T_Jobs
	WHERE Job = @jobID
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error '
		goto Done
	end

 	commit transaction @transName

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteCaptureTask] TO [DDL_Viewer] AS [dbo]
GO

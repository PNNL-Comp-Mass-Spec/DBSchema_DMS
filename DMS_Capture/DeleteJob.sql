/****** Object:  StoredProcedure [dbo].[DeleteJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DeleteJob
/****************************************************
**
**	Desc:
**		Deletes the given job from T_Jobs and T_Job_Steps
**		This procedure is called by DeleteAnalysisJob in DMS5
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	09/12/2009 -- initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**
*****************************************************/
(
    @jobNum varchar(32),
	@callingUser varchar(128) = '',
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @jobID int
	set @jobID = convert(int, @jobNum)

	declare @transName varchar(32)
	set @transName = 'DeleteBrokerJob'
	begin transaction @transName
 
	---------------------------------------------------
	-- delete job dependencies
	---------------------------------------------------
	--
	DELETE FROM T_Job_Step_Dependencies
	WHERE (Job_ID = @jobNum)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		--
	if @myError <> 0
	begin
		set @message = 'Error deleting T_Job_Step_Dependencies'
		goto Done
	end

   	---------------------------------------------------
	-- delete job parameters
	---------------------------------------------------
	--
	DELETE FROM T_Job_Parameters
	WHERE Job = @jobNum
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		--
	if @myError <> 0
	begin
		set @message = 'Error deleting T_Job_Parameters'
		goto Done
	end


	---------------------------------------------------
	-- delete job steps
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
	-- delete jobs
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

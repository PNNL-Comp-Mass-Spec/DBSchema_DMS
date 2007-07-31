/****** Object:  StoredProcedure [dbo].[DeleteAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
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
**
*****************************************************/
(
    @jobNum varchar(32)
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
	
	commit transaction @transName

	return 0


GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisJob] TO [DMS_Ops_Admin]
GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisJob] TO [Limited_Table_Write]
GO

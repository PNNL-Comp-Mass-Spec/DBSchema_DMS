/****** Object:  StoredProcedure [dbo].[DeleteAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DeleteAnalysisJob
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
**		Auth: grk
**		Date: 3/6/2001
**            6/9/2004 grk - added delete for analysis job request reference
**			  04/07/2006 grk - eliminated job to request map table
**    
*****************************************************/
    @jobNum varchar(32)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	declare @jobID int
	set @jobID = convert(int, @jobNum)

	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'DeleteAnalysisJob'
	begin transaction @transName
	
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

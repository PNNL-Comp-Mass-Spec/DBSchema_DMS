/****** Object:  StoredProcedure [dbo].[RequestResultsXferTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestResultsXferTaskParams
/****************************************************
**
**	Desc: 
**	Updates job table to show job is in progress, and finds parameters 
**		needed for transferring analysis job results from receiving 
**		folder to dataset folder.
**
**	All information needed for transfer task is returned
**	in the output arguments
**
**	Return values: 0: success, anything else: error
**
**		Auth: dac
**		Date: 5/11/2007
**    
*****************************************************/
   @EntityId int,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Verify job is still in "results received" state
	---------------------------------------------------
	declare @jobStateID int
	set @jobStateID = 0

	SELECT @jobStateID = AJ_StateID  
	FROM T_Analysis_Job 
	WHERE AJ_jobID = @EntityId
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking job state'
		goto done
	end
	if @myRowCount <> 1 
	begin
		set @myError = 50001
		set @message = 'Invalid number of rows returned while checking job state'
		goto done
	end
	if @jobStateID <> 3
	begin
		set @message = 'Invalid job state: ' + Convert(varchar(4), @jobStateID)
		set @myError = 50002
		goto done
	end
	
	---------------------------------------------------
	-- Update job status
	---------------------------------------------------
	set @myError = 0
	set @myRowCount = 0
	
	UPDATE T_Analysis_Job 
	SET 
		AJ_finish = GETDATE(), 
		AJ_StateID = 9 -- transfer in progress
	WHERE (AJ_jobID = @EntityId)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update operation failed'
		goto done
	end

	---------------------------------------------------
	-- Get parameters for this results task
	---------------------------------------------------

	declare @JobNum varchar(32)
	set @JobNum = cast(@EntityId as varchar(32))
	SELECT * 
	FROM V_RequestAnalysisResultsTask 
	WHERE Job = @JobNum
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Unable to retrieve job parameters'
		goto done
	end
	if @myRowCount <> 1 
	begin
		set @myError = 50005
		set @message = 'Invalid number of rows returned getting job params'
		goto done
	end
	
  	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO

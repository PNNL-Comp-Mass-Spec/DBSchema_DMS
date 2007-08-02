/****** Object:  StoredProcedure [dbo].[RequestDataExtractionTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestDataExtractionTaskParams
/****************************************************
**
**	Desc: 
**	Updates job table to show job is in progress, and finds parameters 
**		needed for performing data extraction
**
**	All information needed for extraction task is returned
**	in the output arguments
**
**	Return values: 0: success, anything else: error
**
**		Auth: dac
**		Date: 06/26/2007
**
**		8/1/2007 dac - Added processor name parameter
*****************************************************/
   @EntityId int,
  	@DemProcessorName varchar(64),
	@message varchar(512)='' output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Verify job is still in "Data Extraction Required" state
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
	if @jobStateID <> 16
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
		AJ_extractionProcessor = @DemProcessorName, 
		AJ_StateID = 17 -- data extraction in progress
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
	-- Get parameters for this extraction task
	---------------------------------------------------

--	declare @JobNum varchar(32)
--	set @JobNum = cast(@EntityId as varchar(32))
	SELECT * 
	FROM V_RequestDataExtractionTaskParams
	WHERE JobID = @EntityId
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Unable to retrieve task parameters'
		goto done
	end
	if @myRowCount <> 1 
	begin
		set @myError = 50005
		set @message = 'Invalid number of rows returned getting task params'
		goto done
	end
	
  	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO

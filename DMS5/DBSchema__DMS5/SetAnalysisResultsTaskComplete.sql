/****** Object:  StoredProcedure [dbo].[SetAnalysisResultsTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure SetAnalysisResultsTaskComplete
/****************************************************
**
**	Desc: 
**		Sets status of analysis job to successful
**		completion and processes analysis results
**		or sets status to failed (according to
**		value of input argument).
**		Also sets archive update required for dataset
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@jobNum					unique identifier for analysis job
**  @completionCode			0->success, 1->failure
**
**		Auth: grk
**		Date: 11/20/2002
**            08/03/2005 grk - made setting update archive depend on @completionCode
**            07/28/2006 grk - save completion code to job table and set state according to AJ_Data_Extraction_Error
**    
*****************************************************/
	@jobNum varchar(32),
	@completionCode int = 0,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	-- set nocount on

	declare @jobID int
	declare @completionState int
	declare @currentState int
	declare @extractionError smallint

	set @jobID = convert(int, @jobNum)
	-- future: this could get more complicated


   	---------------------------------------------------
	-- get info about job
	---------------------------------------------------
	
	set @currentState = 0
	--
	SELECT 
		@currentState = AJ_StateID,
		@extractionError = AJ_Data_Extraction_Error
	FROM T_Analysis_Job
	WHERE (AJ_jobID = @jobID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Error trying to look up current job state'
		goto done
	end

   	---------------------------------------------------
	-- check current state
	---------------------------------------------------

	if @currentState <> 9 -- transfer in progress
	begin
		set @message = 'Job was not in correct state'
		goto done
	end

   	---------------------------------------------------
	-- choose completion state
	---------------------------------------------------
	
	if @completionCode = 0
		if @extractionError = 0
			set @completionState = 4 -- normal completion
		else
			set @completionState = 14 -- no export
	else
		set @completionState = 6 -- transfer failed
	
   	---------------------------------------------------
	-- Update job status
	---------------------------------------------------
	
	UPDATE T_Analysis_Job 
	SET 
		AJ_finish = GETDATE(), 
		AJ_StateID = @completionState
	WHERE (AJ_jobID = @jobID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update operation failed'
		goto done
	end

	-- set update required for this job's dataset
	--
	if @completionCode = 0
	begin
		declare @result int
		declare @datasetNum varchar(128)
		set @datasetNum = ''
		set @message = ''
		--
		SELECT    @datasetNum = DatasetNum
		FROM         V_Analysis_Job
		WHERE     (JobNum = @jobID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @datasetNum = ''
		begin
			set @message = 'Could not resolve job to dataset'
			goto done
		end
		--
		exec @result = SetArchiveUpdateRequired @datasetNum, @message output
	end
  ---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError



GO
GRANT EXECUTE ON [dbo].[SetAnalysisResultsTaskComplete] TO [DMS_Ops_Admin]
GO
GRANT EXECUTE ON [dbo].[SetAnalysisResultsTaskComplete] TO [DMS_SP_User]
GO

/****** Object:  StoredProcedure [dbo].[SetResultsXferTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SetResultsXferTaskComplete
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
**            11/15/2006 grk - add logic for propagation mode (ticket #328)
**            03/06/2007 grk - add changes for deep purge (ticket #403)
**				  05/14/2007 dac - renamed from SetAnalysisResultsTaskComplete for consistency with task broker
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
	declare @propMode smallint

	set @jobID = convert(int, @jobNum)
	-- future: this could get more complicated


   	---------------------------------------------------
	-- get info about job
	---------------------------------------------------
	set @propMode = 0	
	set @currentState = 0
	--
	SELECT 
		@currentState = AJ_StateID,
		@extractionError = AJ_Data_Extraction_Error,
		@propMode = AJ_propagationMode
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

	if @completionCode <> 0
		set @completionState = 6 -- transfer failed
	else
		if @propMode > 0 or @extractionError <> 0
			set @completionState = 14 -- no export
		else
			set @completionState = 4 -- normal completion

 	---------------------------------------------------
	--  Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'SetAnalysisResultsTaskComplete'
	begin transaction @transName


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
		rollback transaction @transName
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
			rollback transaction @transName
			set @message = 'Could not resolve job to dataset'
			goto done
		end
		--
		exec @myError = SetArchiveUpdateRequired @datasetNum, @message output
		if @myError <> 0
		begin
			rollback transaction @transName
			goto done
		end
	end
	
	commit transaction @transName

    ---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError



GO

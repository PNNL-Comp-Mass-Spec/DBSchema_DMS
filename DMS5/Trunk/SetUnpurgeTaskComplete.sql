/****** Object:  StoredProcedure [dbo].[SetUnpurgeTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure SetUnpurgeTaskComplete
/****************************************************
**
**	Desc: Sets state of analysis job given by @jobNum
**        according to given completion code
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/6/2003
**			  08/12/2004 grk - added setting for purge holdoff date
**			  11/16/2006 grk - changed @purgeHoldoffInterval to 5 days
**    
*****************************************************/
(
  @jobNum varchar(32),
	@completionCode int = 0, -- @completionCode = 0 -> success, @completionCode <> 0 -> failure
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @jobID int
	set @jobID = convert(int, @jobNum)

	declare @datasetID int
	declare @datasetState int
	declare @archiveCompletionState int
	declare @jobCompletionState int
 	declare @result int
	declare @instrumentClass varchar(32)

 	declare @purgeHoldoffInterval int
 	set  @purgeHoldoffInterval = 5

  ---------------------------------------------------
	-- resolve jobNum into dataset ID and job state 
	---------------------------------------------------
	declare @currentState as int
	--
	SELECT 
		@datasetID = AJ_datasetID,
		@currentState = AJ_StateID
	FROM T_Analysis_Job
	WHERE (AJ_jobID = @jobID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @datasetID = 0
	begin
		set @message = 'Could not get dataset ID for job ' + @jobNum
		goto done
	end
	
  ---------------------------------------------------
	-- check current job state
	---------------------------------------------------

	if @currentState <> 11
	begin
		set @myError = 1
		set @message = 'Current job state incorrect for job ' + @jobNum
		goto done
	end
	
	-- Future: check archive state for database?

  ---------------------------------------------------
	-- choose completion states
	---------------------------------------------------
	
	if @completionCode <> 0
		begin
			set @archiveCompletionState = 0 
			set @jobCompletionState = 12 -- spectra req'd failed
		end
	else
		begin
			set @archiveCompletionState = 3 -- complete 
			set @jobCompletionState = 1 -- new
		end	

  ---------------------------------------------------
	-- update archive and analysis job states
	---------------------------------------------------
	-- note: all jobs that depend upon the same dataset as the
	-- given job will also be set to the 'new' state if they are
	-- in the 'spectra required' state

	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'SetUnpurgeTaskComplete'
	begin transaction @transName

	UPDATE T_Analysis_Job
	SET AJ_StateID = @jobCompletionState
	WHERE 
	(AJ_jobID = @jobID) OR 
	( (AJ_datasetID = @datasetID) and (AJ_StateID = 10) )
--WHERE 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount < 1
	begin
		rollback transaction @transName
		set @message = 'Update operation failed'
		set @myError = 99
		goto done
	end

	if @archiveCompletionState <> 0
	begin
		UPDATE T_Dataset_Archive
		SET
			AS_state_ID = @archiveCompletionState, 
			AS_purge_holdoff_date = DATEADD(dd, @purgeHoldoffInterval, GETDATE())
		WHERE  (AS_Dataset_ID = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			rollback transaction @transName
			set @message = 'Update archive operation failed'
			set @myError = 99
			goto done
		end
	end

	commit transaction @transName

  ---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	if @message <> '' 
	begin
		RAISERROR (@message, 10, 1)
	end
	return @myError

GO
GRANT EXECUTE ON [dbo].[SetUnpurgeTaskComplete] TO [DMS_SP_User]
GO

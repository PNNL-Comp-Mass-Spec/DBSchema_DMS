/****** Object:  StoredProcedure [dbo].[SetArchiveTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure SetArchiveTaskComplete

/****************************************************
**
**	Desc: Sets status of task to successful
**        completion or to failed (according to
**        value of input argument).
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@datasetNum				dataset for which archive task is being completed
**  @completionCode			0->success, 1->failure, anything else ->no intermediate files
**
**		Auth: grk
**		Date: 9/26/2002   
**          06/21/2005 grk -- added handling for "requires_preparation" 
**				11/27/2007 dac -- removed @processorname param, which is no longer required
**    
*****************************************************/
	@datasetNum varchar(128),
	--@processorName varchar(64),
   @completionCode int = 0,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @datasetID int
	declare @archiveState int
	declare @doPrep tinyint

   	---------------------------------------------------
	-- resolve dataset name to ID and archive state
	---------------------------------------------------
	--
	set @datasetID = 0
	set @archiveState = 0
	--
	SELECT     
		@datasetID = Dataset_ID, 
		@archiveState = Archive_State,
		@doPrep = Requires_Prep
	FROM         V_DatasetArchive_Ex
	WHERE     (Dataset_Number = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @myError = 51220
		set @message = 'Error trying to get dataset ID for dataset "' + @datasetNum + '"'
		goto done
	end

   	---------------------------------------------------
	-- check dataset archive state for "in progress"
	---------------------------------------------------
	if @archiveState <> 2
	begin
		set @myError = 51250
		set @message = 'Archive state for dataset "' + @datasetNum + '" is not correct'
		goto done
	end

   	---------------------------------------------------
	-- Update dataset archive state 
	---------------------------------------------------
	
	-- decide what 
	
	if @completionCode = 0  -- task completed successfully
		begin
			-- decide what state is next 
			--
			declare @tmpState int
			if @doPrep = 0 
				set @tmpState = 3
			else
				set @tmpState = 11
			--
			-- update the state
			--
			UPDATE    T_Dataset_Archive
			SET
				AS_state_ID = @tmpState, 
				AS_update_state_ID = 4, 
				AS_last_update = GETDATE(),
				AS_last_verify = GETDATE()
			WHERE     (AS_Dataset_ID = @datasetID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end
	else   -- task completed unsuccessfully
		begin
			UPDATE T_Dataset_Archive
			SET    AS_state_ID = 6
			WHERE  (AS_Dataset_ID = @datasetID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update operation failed'
		set @myError = 99
		goto done
	end

   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[SetArchiveTaskComplete] TO [DMS_SP_User]
GO

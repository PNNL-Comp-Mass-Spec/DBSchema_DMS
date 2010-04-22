/****** Object:  StoredProcedure [dbo].[SetArchiveUpdateTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure SetArchiveUpdateTaskComplete
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
**		Date: 12/3/2002   
**    
**		Mod: dac
**		Date: 12/6/2002
**		Corrected state values used in update state test, update complete output
**
**		Mod: dac
**		Date: 11/30/2007
**		Removed unused processor name parameter
**
*****************************************************/
	@datasetNum varchar(128),
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
	declare @updateState int

   	---------------------------------------------------
	-- resolve dataset name to ID and archive state
	---------------------------------------------------
	--
	set @datasetID = 0
	set @updateState = 0
	--
	SELECT     
		@datasetID = Dataset_ID, 
		@updateState = Update_State
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
	if @updateState <> 3
	begin
		set @myError = 51250
		set @message = 'Archive update state for dataset "' + @datasetNum + '" is not correct'
		goto done
	end

   	---------------------------------------------------
	-- Update dataset archive state 
	---------------------------------------------------
	
	if @completionCode = 0  -- task completed sat
		begin
			UPDATE    T_Dataset_Archive
			SET              AS_update_state_ID = 4, AS_last_update = GETDATE()
			WHERE     (AS_Dataset_ID = @datasetID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end
	else
		begin
			UPDATE T_Dataset_Archive
			SET    AS_update_state_ID = 5
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
GRANT EXECUTE ON [dbo].[SetArchiveUpdateTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveUpdateTaskComplete] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveUpdateTaskComplete] TO [PNL\D3M580] AS [dbo]
GO

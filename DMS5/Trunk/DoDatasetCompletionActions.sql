/****** Object:  StoredProcedure [dbo].[DoDatasetCompletionActions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoDatasetCompletionActions
/****************************************************
**
**	Desc: Sets state of dataset record given by @datasetNum
**        according to given completion code and 
**        adjusts related database entries accordingly.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**  Auth: grk
**  Date: 11/4/2002
**        8/6/2003 grk -- added handling for "Not Ready" state
**        7/1/2005 grk -- changed to use "SchedulePredefinedAnalyses"
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionState int = 0, -- 3 (complete), 5 (capture failed), 6 (received), 8 (prep. failed), 9 (not ready)
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @datasetID int
	declare @datasetState int
 

   	---------------------------------------------------
	-- resolve dataset into ID and state
	---------------------------------------------------
	--
	SELECT     @datasetID = Dataset_ID, @datasetState = DS_state_ID
	FROM         T_Dataset
	WHERE     (Dataset_Num = @datasetNum)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get dataset ID for dataset ' + @datasetNum
		goto done
	end
	
   	---------------------------------------------------
	-- verify that datset is in correct state
	---------------------------------------------------
	--
	if not @completionState  in (3, 5, 6, 8, 9)
	begin
		set @message = 'Completion state argument incorrect '
		goto done
	end

	if not @datasetState in (2, 7)
	begin
		set @message = 'Dataset in incorrect state ' + @datasetNum
		goto done
	end

	if @datasetState = 2 and not @completionState in (3, 5, 6, 9)
	begin
		set @message = 'Transistion 1 not allowed' + @datasetNum
		goto done
	end

	if @datasetState = 7 and not @completionState in (3, 6, 8)
	begin
		set @message = 'Transistion 2 not allowed' + @datasetNum
		goto done
	end
	
   	---------------------------------------------------
	-- Get the default CD burn schedule for the dataset
	---------------------------------------------------
	--
	declare @CDBurnSched varchar(32)
	SELECT @CDBurnSched = T_Instrument_Name.IN_default_CDburn_sched 
	FROM T_Dataset 
	INNER JOIN T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID 
	WHERE (T_Dataset.Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get CD burn schedule for dataset ' + @datasetNum
		goto done
	end

   	---------------------------------------------------
	-- Set up proper compression state
	---------------------------------------------------
	--
	declare @compressonState int
	declare @compressionDate datetime
	--
	-- if dataset is in preparation, 
	-- compression fields must be marked with values
	-- appropriate to success or failure
	--
	if @datasetState = 7  -- dataset is in preparation
	begin
		if @completionState = 8 -- preparation failed
			begin
				set @compressonState = null
				set @compressionDate = null
			end
		else					-- preparation succeeded
			begin
				set @compressonState = 1
				set @compressionDate = getdate()
			end
	end
	--
   	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'SetCaptureComplete'
	begin transaction @transName
	
   	---------------------------------------------------
	-- Update state of dataset
	---------------------------------------------------
	--
	UPDATE T_Dataset 
	SET 
		DS_state_ID = @completionState,
		DS_Comp_State = @compressonState, 
		DS_Compress_Date = @compressionDate
	WHERE 
		(Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or  @myRowCount <> 1
	begin
		rollback transaction @transName
		set @myError = 51252
		set @message = 'Update was unsuccessful for dataset ' + @datasetNum
		goto done
	end
	
   	---------------------------------------------------
	-- Skip further changes if completion was anything 
	-- other than normal completion
	---------------------------------------------------

	if @completionState <> 3
	begin
		commit transaction @transName
		goto done
	end


/*****************************************************
	-- Remove above comment line to enable CD burn schedule
	-- Make new entry into CD burn table to schedule the job
	--
	INSERT INTO T_CDBurn_Requests(
		CDB_Dataset_ID, 
		CDB_qty, 
		CDB_schedule, 
		CDB_created, 
		CDB_Status
	) VALUES (
		@datasetID, 
		1, 
		@CDBurnSched, 
		GETDATE(), 
		1
	)	--
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or  @myRowCount <> 1
	begin
		rollback transaction @transName
		set @myError = 51253
		set @message = 'Update was unsuccessful for CD burn ' + @datasetNum
		goto done
	end

	-- Remove following comment line to enable CD burn schedule
 *****************************************************/

   	---------------------------------------------------
	-- Make new entry into the archive table
	---------------------------------------------------
	--
	declare @result int
	execute @result = AddArchiveDataset @datasetID
	--
	if @result <> 0
	begin
		rollback transaction @transName
		set @myError = 51254
		set @message = 'Update was unsuccessful for archive table ' + @datasetNum
		goto done
	end
	
	commit transaction @transName
	
   	---------------------------------------------------
	-- schedule default analyses for this dataset
	---------------------------------------------------
	--
--	execute @result = ScheduleDefaultAnalyses @datasetNum
	execute @result = SchedulePredefinedAnalyses @datasetNum

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
GRANT VIEW DEFINITION ON [dbo].[DoDatasetCompletionActions] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoDatasetCompletionActions] TO [PNL\D3M580] AS [dbo]
GO

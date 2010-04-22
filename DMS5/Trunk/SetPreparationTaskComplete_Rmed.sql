/****** Object:  StoredProcedure [dbo].[SetPreparationTaskComplete_Rmed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure SetPreparationTaskComplete_Rmed
/****************************************************
**
**	Desc: Sets state of dataset record given by @datasetNum
**        to "completed".
**        Adjusts related database entries accordingly.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 11/18/2002
**    
**    NOTE: This procedure is only to be used for 
**	  remedial operation of the preparation manager
**    and should be used to complete a preparation task
**    that has been requested with the 'RequestPreparationTask_Rmed'
**	  stored procedure
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0, -- 0 -> success,  <> 0 -> failure
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
	declare @completionState int
	declare @result int
 
  ---------------------------------------------------
	-- choose completion state
	---------------------------------------------------
	
	if @completionCode = 0
		set @completionState = 3 -- normal completion
	else
		set @completionState = 8 -- preparation failed

  ---------------------------------------------------
	-- resolve dataset into ID and state
	---------------------------------------------------
	--
	SELECT
		@datasetID = Dataset_ID, 
		@datasetState = DS_state_ID
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
	-- Verify current state of dataset
	---------------------------------------------------

	if @datasetState <> 7
	begin
		set @message = 'Datset not in correct state ' + @datasetNum
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

	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'SetPreparationTaskComplete_Rmed'
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
	-- Update archive state of dataset
	---------------------------------------------------
	if @completionState = 3 -- normal completion
	begin
		UPDATE    T_Dataset_Archive
		SET              AS_state_ID = 1, AS_update_state_ID = 1
		WHERE     (AS_Dataset_ID = @datasetID)
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
GRANT EXECUTE ON [dbo].[SetPreparationTaskComplete_Rmed] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPreparationTaskComplete_Rmed] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPreparationTaskComplete_Rmed] TO [PNL\D3M580] AS [dbo]
GO

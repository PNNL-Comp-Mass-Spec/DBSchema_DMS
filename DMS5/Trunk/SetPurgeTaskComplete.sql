/****** Object:  StoredProcedure [dbo].[SetPurgeTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure SetPurgeTaskComplete
/****************************************************
**
**	Desc: Sets archive state of dataset record given by @datasetNum
**        according to given completion code
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/4/2003
**    
*****************************************************/
(
	@datasetNum varchar(128),
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
	
	declare @datasetID int
	declare @datasetState int
	declare @completionState int
 	declare @result int
	declare @instrumentClass varchar(32)
		
  ---------------------------------------------------
	-- resolve dataset into ID
	---------------------------------------------------
	--
	SELECT 
		@datasetID = T_Dataset.Dataset_ID
	FROM   T_Dataset 
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
	-- check current archive state
	---------------------------------------------------

	declare @currentState as int
	set @currentState = 0
	--
	SELECT @currentState = AS_state_ID
	FROM T_Dataset_Archive
	WHERE (AS_Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get current archive state for dataset ' + @datasetNum
		goto done
	end
	
	if @currentState <> 7
	begin
		set @myError = 1
		set @message = 'Current archive state incorrect for dataset ' + @datasetNum
		goto done
	end

  ---------------------------------------------------
	-- choose completion state and update archive state
	---------------------------------------------------
	
	if @completionCode <> 0
		begin
			set @completionState = 8 -- purge failed
		end
	else
		begin
				set @completionState = 4 -- purged
		end	
		
	UPDATE T_Dataset_Archive
	SET    AS_state_ID = @completionState 
	WHERE  (AS_Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
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
	if @message <> '' 
	begin
		RAISERROR (@message, 10, 1)
	end
	return @myError


GO
GRANT EXECUTE ON [dbo].[SetPurgeTaskComplete] TO [DMS_Ops_Admin]
GO
GRANT EXECUTE ON [dbo].[SetPurgeTaskComplete] TO [DMS_SP_User]
GO

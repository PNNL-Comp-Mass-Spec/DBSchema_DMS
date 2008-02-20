/****** Object:  StoredProcedure [dbo].[DoDatasetOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoDatasetOperation
/****************************************************
**
**	Desc: 
**		Perform dataset operation defined by 'mode'
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 4/8/2002
**		8/7/2003  grk - allowed reset from "Not Ready" state
**		5/5/2005  grk - removed default value from mode
**		3/24/2006 grk - added "restore" mode
**		9/15/2006 grk - repair "restore" mode
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@mode varchar(12), -- 'burn', 'reset', 'delete'
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	declare @datasetID int
	declare @state int
	
	declare @result int

	---------------------------------------------------
	-- get datasetID and current state
	---------------------------------------------------

	SELECT  
		@state = DS_state_ID,
		@datasetID = Dataset_ID 
	FROM T_Dataset 
	WHERE (Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not get Id or state for dataset "' + @datasetNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51140
	end

	---------------------------------------------------
	-- Delete dataset if it is in "new" state only
	---------------------------------------------------

	if @mode = 'delete'
	begin

		---------------------------------------------------
		-- verify that dataset is still in 'new' state
		---------------------------------------------------

		if @state <> 1
		begin
			set @msg = 'Dataset "' + @datasetNum + '" must be in "new" state to be deleted by user'
			RAISERROR (@msg, 10, 1)
			return 51141
		end
		
		---------------------------------------------------
		-- delete the dataset
		---------------------------------------------------

		execute @result = DeleteDataset @datasetNum, @message output
		--
		if @result <> 0
		begin
			RAISERROR ('Could not delete dataset "%s"',
				10, 1, @datasetNum)
			return 51142
		end

		return 0
	end -- mode 'deleteNew'
	
	---------------------------------------------------
	-- Reset state of failed dataset to 'new' 
	---------------------------------------------------

	if @mode = 'reset'
	begin

		-- if dataset not in failed state, can't reset it
		--
		if @state not in (5, 9) -- "Not ready" or "Failed"
		begin
			set @msg = 'Dataset "' + @datasetNum + '" cannot be reset if capture not in failed or in not ready state' + cast(@state as varchar(12))
			RAISERROR (@msg, 10, 1)
			return 51693
		end

		-- Update state of dataset to new
		--
		UPDATE T_Dataset 
		SET DS_state_ID = 1 -- "new' state
		WHERE (Dataset_Num = @datasetNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update was unsuccessful for dataset table "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51694
		end

		return 0
	end -- mode 'reset'
	
	---------------------------------------------------
	-- set state of dataset to "Restore Requested"
	---------------------------------------------------

	if @mode = 'restore'
	begin

		-- if dataset not in complete state, can't request restore
		--
		if @state <> 3
		begin
			set @msg = 'Dataset "' + @datasetNum + '" cannot be restored unless it is in completed state'
			RAISERROR (@msg, 10, 1)
			return 51693
		end

		-- if dataset not in purged archive state, can't request restore
		--
		declare @as int
		set @as = 0
		--
		SELECT 
			@as = T_Dataset_Archive.AS_state_ID
		FROM 
			T_Dataset_Archive INNER JOIN
			T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
		WHERE
			 T_Dataset.Dataset_ID = @datasetID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to check archive state'
			RAISERROR (@msg, 10, 1)
			return 51692
		end
		--
		if @as <> 4
		begin
			set @msg = 'Dataset "' + @datasetNum + '" cannot be restored unless it is purged state'
			return 51690
		end

		-- Update state of dataset to "Restore Requested"
		--
		UPDATE T_Dataset 
		SET DS_state_ID = 10 -- "restore required" state
		WHERE (Dataset_Num = @datasetNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update was unsuccessful for dataset table "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51694
		end

		return 0
	end -- mode 'restore'	

	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @msg = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@msg, 10, 1)
	return 51222


GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS_DS_Entry]
GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS2_SP_User]
GO

/****** Object:  StoredProcedure [dbo].[UpdateArchiveDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateArchiveDatasets 
/****************************************************
**
**	Desc:
**      Updates arvhive parameters to new values for datasets in list
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 08/21/2007
**    
*****************************************************/
    @datasetList varchar(6000),
    @archiveState varchar(32) = '',
    @updateState varchar(32) = '',
    @mode varchar(12) = 'update',
    @message varchar(512) output
As
  set nocount on

  declare @myError int
  set @myError = 0

  declare @myRowCount int
  set @myRowCount = 0
  
  set @message = ''

  declare @msg varchar(512)
  declare @list varchar(1024)


  ---------------------------------------------------
  -- 
  ---------------------------------------------------

	if @datasetList = ''
	begin
		set @msg = 'Dataset list is empty'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	---------------------------------------------------
	--  Create temporary table to hold list of datasets
	---------------------------------------------------
 
 	CREATE TABLE #TDS (
		DatasetNum varchar(128)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Failed to create temporary dataset table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Populate table from dataset list  
	---------------------------------------------------

	INSERT INTO #TDS
	(DatasetNum)
	SELECT Item
	FROM MakeTableFromList(@datasetList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error populating temporary dataset table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Verify that all datasets exist 
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN cast(DatasetNum as varchar(12))
		ELSE ', ' + cast(DatasetNum as varchar(12))
		END
	FROM
		#TDS
	WHERE 
		NOT DatasetNum IN (SELECT Dataset_Num FROM T_Dataset)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets from list were not in database:"' + @list + '"'
		return 51007
	end
	
	declare @datasetCount int
	SELECT @datasetCount = count(*) FROM #TDS
	set @message = 'Number of affected datasets:' + cast(@datasetCount as varchar(12))

	---------------------------------------------------
	-- Resolve archive state
	---------------------------------------------------
	declare @stateID int
	set @stateID = 0
	--

	if @archiveState <> '[no change]'
	begin
		--
		SELECT @stateID = DASN_StateID
		FROM         T_DatasetArchiveStateName
		WHERE     (DASN_StateName = @archiveState)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up state name'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		--
		if @stateID = 0
		begin
			set @msg = 'Could not find state'
			RAISERROR (@msg, 10, 1)
			return 51007
		end

	end -- if @archiveState
	
	---------------------------------------------------
	-- Resolve update state
	---------------------------------------------------
	declare @updateID int
	set @updateID = 0
	--

	if @updateState <> '[no change]'
	begin
		--
		SELECT @updateID =  AUS_stateID
		FROM T_Archive_Update_State_Name
		WHERE (AUS_name = @updateState)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up update state name'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		--
		if @updateID = 0
		begin
			set @msg = 'Could not find update state'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- if @updateState
	
 	---------------------------------------------------
	-- Update datasets from temporary table
	-- in cases where parameter has changed
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0

		---------------------------------------------------
		declare @transName varchar(32)
		set @transName = 'UpdateArchiveDatasets'
		begin transaction @transName

		-----------------------------------------------
		if @archiveState <> '[no change]'
		begin
			UPDATE T_Dataset_Archive
			SET AS_state_ID = @stateID
			FROM 
			T_Dataset_Archive INNER JOIN
            T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
			WHERE (Dataset_Num in (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @updateState <> '[no change]'
		begin
			UPDATE T_Dataset_Archive
			SET AS_update_state_ID = @updateID
			FROM 
			T_Dataset_Archive INNER JOIN
            T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
			WHERE (Dataset_Num in (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end
		commit transaction @transName
	end -- update mode

 	---------------------------------------------------
	-- 
	---------------------------------------------------
	
	return @myError



GO

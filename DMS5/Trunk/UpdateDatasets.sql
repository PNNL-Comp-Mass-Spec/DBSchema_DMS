/****** Object:  StoredProcedure [dbo].[UpdateDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE dbo.UpdateDatasets
/****************************************************
**
**	Desc:
**      Updates parameters to new values for datasets in list
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: jds
**		Date: 09/21/2006
**    
*****************************************************/
    @datasetList varchar(6000),
    @state varchar(32) = '',
    @rating varchar(32) = '',
    @comment varchar(255) = '',
    @findText varchar(255) = '',
    @replaceText varchar(255) = '',
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


	if (@findText = '[no change]' and @replaceText <> '[no change]') OR (@findText <> '[no change]' and @replaceText = '[no change]')
	begin
		set @msg = 'The Find In Comment and Replace In Comment enabled flags must both be enabled or disabled'
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
	-- Resolve state name
	---------------------------------------------------
	declare @stateID int
	set @stateID = 0
	--
	if @state <> '[no change]'
	begin
		--
		SELECT @stateID = Dataset_state_ID
		FROM  T_DatasetStateName
		WHERE (DSS_name = @state)	
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
	end -- if @state

	
	---------------------------------------------------
	-- Resolve rating name
	---------------------------------------------------
	declare @ratingID int
	set @ratingID = 0
	--
	if @rating <> '[no change]'
	begin
		--
		SELECT @ratingID = DRN_state_ID
		FROM  T_DatasetRatingName
		WHERE (DRN_name = @rating)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up rating name'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		--
		if @ratingID = 0
		begin
			set @msg = 'Could not find rating'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- if @rating

	
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
		set @transName = 'UpdateDatasets'
		begin transaction @transName

		-----------------------------------------------
		if @state <> '[no change]'
		begin
			UPDATE T_Dataset
			SET 
				DS_state_ID = @stateID
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
		if @rating <> '[no change]'
		begin
			UPDATE T_Dataset
			SET 
				DS_rating = @ratingID
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
		if @comment <> '[no change]'
		begin
			UPDATE T_Dataset
			SET 
				DS_comment = DS_comment + ' ' + @comment
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
		if @findText <> '[no change]' and @replaceText <> '[no change]'
		begin
			UPDATE T_Dataset 
			SET 
				DS_comment = replace(DS_comment, @findText, @replaceText)
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

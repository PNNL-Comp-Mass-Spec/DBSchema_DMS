/****** Object:  StoredProcedure [dbo].[UpdateDatasetDispositions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDatasetDispositions
/****************************************************
**
**	Desc:
**      Updates datasets in list according to disposition parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 04/25/2007
**            06/26/2007 grk -- fix problem with multiple datasets (Ticket #495)
**    
*****************************************************/
    @datasetIDList varchar(6000),
    @rating varchar(64) = '',
    @comment varchar(512) = '',
    @recycleRequest varchar(32) = '', -- yes/no
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

	if @datasetIDList = ''
	begin
		set @msg = 'Dataset list is empty'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- Resolve rating name
	---------------------------------------------------
	declare @ratingID int
	set @ratingID = 0
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

	---------------------------------------------------
	--  Create temporary table to hold list of datasets
	---------------------------------------------------
 
 	CREATE TABLE #TDS (
		DatasetID int,
		DatasetName varchar(128) NULL,
		RatingID int NULL,
		State int NULL,
		Comment varchar(512) NULL
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
	(DatasetID)
	SELECT CAST(Item as int)
	FROM MakeTableFromList(@datasetIDList)
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
		WHEN @list = '' THEN cast(DatasetID as varchar(12))
		ELSE ', ' + cast(DatasetID as varchar(12))
		END
	FROM
		#TDS
	WHERE 
		NOT DatasetID IN (SELECT Dataset_ID FROM T_Dataset)
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
	-- Get information for datasets in list
	---------------------------------------------------

	UPDATE M
	SET 
		M.RatingID = T.DS_rating,
		M.DatasetName = T.Dataset_Num,
		M.State =  DS_state_ID,
		M.Comment = DS_comment
	FROM #TDS M INNER JOIN 
	T_Dataset T ON T.Dataset_ID = M.DatasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating dataset rating'
		return 51022
	end

	
 	---------------------------------------------------
	-- Update datasets from temporary table
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		declare @prevDatasetID int
		set @prevDatasetID = 0
		--
		declare @curDatasetID int
		set @curDatasetID = 0
		--
		declare @curDatasetName varchar(128)
		set @curDatasetName = ''
		--
		declare @curRatingID int
		set @curRatingID = 0
		--
		declare @curState int
		set @curState = 0
		--
		declare @curComment varchar(512)
		set @curComment = ''
		--
		declare @done int
		set @done = 0
		--
		declare @transName varchar(32)
		set @transName = 'UpdateDatasetDispositions'
		
		---------------------------------------------------
		while @done = 0
		begin

			-----------------------------------------------
			-- get next dataset ID from temp table
			--
			set @curDatasetID = 0
			SELECT TOP 1
				@curDatasetID = DatasetID,
				@curDatasetName = DatasetName,
				@curRatingID = RatingID,
				@curState = State,
				@curComment = Comment
			FROM #TDS
			WHERE DatasetID > @prevDatasetID
			ORDER BY DatasetID
			--
			if @curDatasetID = 0
				begin
					set @done = 1
				end
			else
				begin
					begin transaction @transName
					
					-----------------------------------------------
					-- update dataset
					--
					if @curComment <> '' AND @comment <> ''
						set @curComment = @curComment + ' ' + @comment
					else
					if @curComment = '' AND @comment <> ''
						set @curComment = @comment
					--
					UPDATE T_Dataset
					SET 
						DS_comment = @curComment, 
						DS_rating = @ratingID
					WHERE (Dataset_ID = @curDatasetID)
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
					
					-----------------------------------------------
					-- recycle request?
					--
					if @recycleRequest = 'Yes'
					begin
						exec @myError = UnconsumeScheduledRun @curDatasetName, 'na', 'na', 1, @message output					
						--
						if @myError <> 0
						begin
							rollback transaction @transName
							RAISERROR (@message, 10, 1)
							return 51004
						end
					end

					-----------------------------------------------
					-- evaluate predefined analyses
					--
					-- if rating changes from unreviewed to released
					-- and dataset capture is complete
					--
					if @curRatingID = -10 and @ratingID = 5 AND @curState = 3
					begin
						-- schedule default analyses for this dataset
						--
						execute @myError = SchedulePredefinedAnalyses @curDatasetName
						--
						if @myError <> 0
						begin
							rollback transaction @transName
							return @myError
						end
					
					end
					
					-----------------------------------------------
					-- 
					commit transaction @transName

					set @prevDatasetID = @curDatasetID 
				end

		end -- while
	end -- update mode

 	---------------------------------------------------
	-- 
	---------------------------------------------------
	
	return @myError



GO
GRANT EXECUTE ON [dbo].[UpdateDatasetDispositions] TO [DMS_RunScheduler]
GO

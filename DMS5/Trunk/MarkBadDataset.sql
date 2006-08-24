/****** Object:  StoredProcedure [dbo].[MarkBadDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure MarkBadDataset
/****************************************************
**		File: 
**		Name: MarkBadDataset
**		Desc: Sets a bad dataset to No Interest, Inactive, NonPurgeable and adds comment
**
**		Return values: 0: success, otherwise, error code
** 
**		Parameters:
**			- Dataset name
**			- Comment to be appended to existing comment in dataset table
**
**		Auth: dac
**		Date: 8/4/2004
**    
*****************************************************/
	@datasetNum varchar(64),
	@comment varchar(512),
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	-- declare @msg varchar(256)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@datasetNum) < 1
	begin
		set @myError = 51010
		RAISERROR ('Dataset number was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError
		
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @datasetID int
	declare @curComment varchar(512)
	declare @curDSStateID int
	set @datasetID = 0
	SELECT 
		@datasetID = Dataset_ID,
		@curDSStateID = DS_state_ID,
		@curComment = DS_Comment
    FROM T_Dataset 
	WHERE (Dataset_Num = @datasetNum)

	-- verify a dataset was found
	--
	if @datasetID = 0
	begin
		set @message = 'Dataset "' + @datasetNum + '" is not in database '
		RAISERROR (@message, 10, 1)
		return 51004
	end
	
	---------------------------------------------------
	-- update the archive record for this dataset
	---------------------------------------------------
	--
	begin
		set @myError=0
		--
		-- Start transaction
		--
		declare @transName varchar(32)
		set @transName = 'MarkBadDataset'
		begin transaction @transName
		--
		UPDATE T_Dataset_Archive
		Set
			AS_state_ID = 10
		WHERE (AS_Dataset_ID = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			begin
				set @message = 'Archive table update operation failed: "' + @datasetNum + '"'
				RAISERROR (@message, 10, 1)
				rollback transaction @transName
				return 51005
		end
		if @myRowCount < 1
			begin
				set @message = 'Dataset not in archive table: "' + @datasetNum + '"'
				RAISERROR (@message, 10, 1)
				rollback transaction @transName
				return 51015
			end
		if @myRowCount > 1
			begin
				set @message = 'Multiple records affected by archive update: "' + @datasetNum + '"'
				RAISERROR (@message, 10, 1)
				rollback transaction @transName
				return 51015
			end
		
	end -- achive table update
				
	---------------------------------------------------
	-- update the dataset table
	---------------------------------------------------
	--
	begin
		set @myError = 0
		--
		
		UPDATE T_Dataset 
		SET 
				DS_comment = @curComment + '; ' + @comment, 
				DS_rating = 1,
				DS_State_ID = 4
		WHERE (Dataset_Num = @datasetNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Dataset update operation failed: "' + @datasetNum + '"'
			RAISERROR (@message, 10, 1)
			rollback transaction @transName
			return 51006
		end
	end -- dataset table update
	
	commit transaction @transName

	return 0

GO

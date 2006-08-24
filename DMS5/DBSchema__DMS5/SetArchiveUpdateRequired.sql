/****** Object:  StoredProcedure [dbo].[SetArchiveUpdateRequired] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure SetArchiveUpdateRequired
/****************************************************
**
**	Desc: Sets archive status of dataset
**        to update required
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 12/3/2002   
**    
*****************************************************/
	@datasetNum varchar(128),
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
	if not @updateState in (1, 4, 5)
	begin
		set @myError = 51250
		set @message = 'Archive update state for dataset "' + @datasetNum + '" is not correct'
		goto done
	end

   	---------------------------------------------------
	-- Update dataset archive state 
	---------------------------------------------------
	
	UPDATE    T_Dataset_Archive
	SET              AS_update_state_ID = 2
	WHERE     (AS_Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 2
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
GRANT EXECUTE ON [dbo].[SetArchiveUpdateRequired] TO [DMS_Ops_Admin]
GO

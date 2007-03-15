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
**            03/06/2007 grk - add changes for deep purge (ticket #403)
**            03/07/2007 dac - fixed incorrect check for "in progress" update states (ticket #408)
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
	declare @archiveState int

   	---------------------------------------------------
	-- resolve dataset name to ID and archive state
	---------------------------------------------------
	--
	set @datasetID = 0
	set @updateState = 0
	--
	SELECT     
		@datasetID = Dataset_ID, 
		@updateState = Update_State,
		@archiveState = Archive_State
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
	-- check dataset archive update state for "in progress"
	---------------------------------------------------
	if not @updateState in (1, 2, 4, 5)
	begin
		set @myError = 51250
		set @message = 'Archive update state for dataset "' + @datasetNum + '" is not correct'
		goto done
	end

   	---------------------------------------------------
	-- if archive state is "purged", set it to "complete"
	-- to allow for re-purging
	---------------------------------------------------
	if @archiveState = 4
	begin
		set @archiveState = 3
	end

   	---------------------------------------------------
	-- Update dataset archive state 
	---------------------------------------------------
	
	UPDATE T_Dataset_Archive
	SET AS_update_state_ID = 2,  AS_state_ID = @archiveState
	WHERE     (AS_Dataset_ID = @datasetID)
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
	return @myError




GO
GRANT EXECUTE ON [dbo].[SetArchiveUpdateRequired] TO [DMS_Ops_Admin]
GO

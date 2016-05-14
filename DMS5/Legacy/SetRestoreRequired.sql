/****** Object:  StoredProcedure [dbo].[SetRestoreRequired] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[SetRestoreRequired]
/****************************************************
**
**	Desc: 
**	Sets the state of the given dataset to
**  "restore required" if it is in proper state
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	03/24/2006
**			09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@datasetName varchar(128),
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''


	---------------------------------------------------
	-- verify that the archive state is "purged"
	-- and dataset state is "complete"
	---------------------------------------------------
	declare @as int
	set @as = 0
	declare @ds int
	set @ds = 0
	--
	SELECT 
		@as = T_Dataset_Archive.AS_state_ID, 
		@ds = T_Dataset.DS_state_ID
	FROM 
		T_Dataset_Archive INNER JOIN
		T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
	WHERE
		T_Dataset.Dataset_Num = @datasetName
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to check archive state'
		return @myError
	end
	--
	if @as = 0
	begin
		set @message = 'Could not find archive state for dataset'
		return 51001
	end
	--
	if @as <> 4
	begin
		set @message = 'Dataset not purged'
		return 51002
	end
	--
	if @ds <> 3
	begin
		set @message = 'Dataset not complete'
		return 51003
	end

	---------------------------------------------------
	-- if so, set dataset state to "restore required"
	---------------------------------------------------
	
	UPDATE T_Dataset
	SET DS_state_ID = 10
	WHERE Dataset_Num = @datasetName
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to update dataset state'
		return @myError
	end
	
	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Dataset: ' + @datasetName
	Exec PostUsageLogEntry 'SetRestoreRequired', @UsageMessage

	return @myError


GO

GRANT EXECUTE ON [dbo].[SetRestoreRequired] TO [DMS_Archive_Restore] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRestoreRequired] TO [Limited_Table_Write] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRestoreRequired] TO [PNL\D3M578] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRestoreRequired] TO [PNL\D3M580] AS [dbo]
GO


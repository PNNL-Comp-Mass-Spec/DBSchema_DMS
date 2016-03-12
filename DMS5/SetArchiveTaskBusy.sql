/****** Object:  StoredProcedure [dbo].[SetArchiveTaskBusy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SetArchiveTaskBusy]
/****************************************************
**
**	Desc: 
**	Sets appropriate dataset state to busy
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: grk
**	Date: 12/15/2009
**        01/14/2010 grk - removed path ID fields
**        09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@StorageServerName varchar(64),
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	UPDATE T_Dataset_Archive
	SET
		AS_state_ID = 2,
		AS_archive_processor = @StorageServerName
	FROM
		T_Dataset_Archive
		INNER JOIN T_Dataset ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
	WHERE
		T_Dataset.Dataset_Num = @datasetNum		
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Update operation failed'
	end

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Dataset: ' + @datasetNum
	Exec PostUsageLogEntry 'SetArchiveTaskBusy', @UsageMessage

	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveTaskBusy] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveTaskBusy] TO [PNL\D3M578] AS [dbo]
GO

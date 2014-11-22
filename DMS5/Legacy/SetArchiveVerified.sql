/****** Object:  StoredProcedure [dbo].[SetArchiveVerified] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[SetArchiveVerified]
/****************************************************
**
**	Desc: Set the "last verified" date for dataset given by
**	      @datasetNum 
**        (ignore @archivePath)
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 07/24/2002
**			  09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
		@datasetNum varchar(128),
		@archivePath varchar(255) = ''
)
As
	-- Get the key value for the dataset
	--
	declare @datasetID int
	execute @datasetID = GetDatasetID @datasetNum
	if @datasetID = 0
	begin
		RAISERROR ('Could not get dataset ID for dataset "%s"',
			10, 1, @datasetNum)
		return 51220
	end
	

	UPDATE T_Dataset_Archive 
	SET 
		AS_last_verify= GETDATE() 
	WHERE (AS_Dataset_ID = @datasetID)
	--
	if @@rowcount <> 1 or @@error <> 0
	begin
		RAISERROR ('Update archive table failed: "%s"',
			10, 1, @datasetID)
		return 51222
	end

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Dataset: ' + @datasetNum
	Exec PostUsageLogEntry 'SetArchiveVerified', @UsageMessage

	return 0

GO

GRANT EXECUTE ON [dbo].[SetArchiveVerified] TO [DMS_SP_User] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetArchiveVerified] TO [Limited_Table_Write] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetArchiveVerified] TO [PNL\D3M578] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetArchiveVerified] TO [PNL\D3M580] AS [dbo]
GO


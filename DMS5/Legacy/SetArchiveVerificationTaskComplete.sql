/****** Object:  StoredProcedure [dbo].[SetArchiveVerificationTaskComplete] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE Procedure [dbo].[SetArchiveVerificationTaskComplete]
/****************************************************
**
**	Desc: Sets status of archive verification task to successful
**        completion or to failed (according to
**        value of input argument).
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	 @datasetNum		dataset for which archive task is being completed
**	 @completionCode	0->success, 1->failure, anything else ->no intermediate files
**
**	Auth:	jds
**	Date:	06/27/2005
**			10/26/2007 dac - Removed @processorName parameter, which is no longer used
**			03/23/2009 mem - Now updating AS_Last_Successful_Archive when the archive state is 3=Complete (Ticket #726)
**			09/02/2011 mem - Now calling PostUsageLogEntry
**
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0,
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	declare @datasetID int
	declare @archiveState int

   	---------------------------------------------------
	-- resolve dataset name to ID and archive state
	---------------------------------------------------
	--
	set @datasetID = 0
	set @archiveState = 0
	--
	SELECT
		@datasetID = Dataset_ID,
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
	-- check dataset archive state for "in progress"
	---------------------------------------------------
	if @archiveState <> 12
	begin
		set @myError = 51250
		set @message = 'Archive verification state for dataset "' + @datasetNum + '" is not correct'
		goto done
	end

   	---------------------------------------------------
	-- Update dataset archive state
	---------------------------------------------------

	if @completionCode = 0  -- task completed sat
		begin
			UPDATE    T_Dataset_Archive
			SET
				AS_state_ID = 3,
				AS_last_update = GETDATE(),
				AS_last_verify = GETDATE(),
				AS_Last_Successful_Archive = GETDATE()
			WHERE     (AS_Dataset_ID = @datasetID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end
	else
		begin
			UPDATE T_Dataset_Archive
			SET    AS_state_ID = 13
			WHERE  (AS_Dataset_ID = @datasetID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end
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

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Dataset: ' + @datasetNum
	Exec PostUsageLogEntry 'SetArchiveVerificationTaskComplete', @UsageMessage

	return @myError


GO

GRANT VIEW DEFINITION ON [dbo].[SetArchiveVerificationTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetArchiveVerificationTaskComplete] TO [PNL\D3M578] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetArchiveVerificationTaskComplete] TO [PNL\D3M580] AS [dbo]
GO


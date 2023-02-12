/****** Object:  StoredProcedure [dbo].[DeleteRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteRequestedRun]
/****************************************************
**
**	Desc:
**	Remove a requested run (and all its dependencies)
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	02/23/2006
**			10/29/2009 mem - Made @message an optional output parameter
**          02/26/2010 grk - delete factors
**			12/12/2011 mem - Added parameter @callingUser, which is passed to AlterEventLogEntryUser
**			03/22/2016 mem - Added parameter @skipDatasetCheck
**			06/13/2017 mem - Fix typo
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**          02/10/2023 mem - Call UpdateCachedRequestedRunBatchStats
**
*****************************************************/
(
	@requestID int = 0,						-- Requested run ID to delete
	@skipDatasetCheck tinyint = 0,			-- Set to 1 to allow deleting a requested run even if it has an associated dataset
	@message varchar(512)='' output,
	@callingUser varchar(128) = ''
)
As

	Set nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0
	Declare @batchID int

	set @message = ''
	Set @skipDatasetCheck = Isnull(@skipDatasetCheck, 0)

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------

	Declare @authorized tinyint = 0
	Exec @authorized = VerifySPAuthorized 'DeleteRequestedRun', @raiseError = 1

	If @authorized = 0
	Begin;
		THROW 51000, 'Access denied', 1;
	End;

	---------------------------------------------------
	-- Validate the requested run ID
	---------------------------------------------------
	--
	If @requestID = 0
	Begin
		Set @message = '@requestID is 0; nothing to do'
		goto Done
	End

    -- Verify that the request exists and check whether the request is in a batch
    --
    SELECT @batchID = RDS_BatchID
    FROM dbo.T_Requested_Run
    WHERE ID = @requestID;
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		Set @message = 'ID ' + Cast(@requestID as varchar(9)) + ' not found in T_Requested_Run; nothing to do'
		print @message
		goto Done
	End

	If @skipDatasetCheck = 0
	Begin
		Declare @DatasetID int = 0

		Select @DatasetID = DatasetID
		FROM T_Requested_Run
		WHERE ID = @requestID

		If IsNull(@DatasetID, 0) > 0
		Begin
			Declare @Dataset varchar(128)

			Select @Dataset = Dataset_Num
			FROM T_Dataset
			Where Dataset_ID = @DatasetID

			Set @message = 'Cannot delete requested run ' + Cast(@requestID as varchar(9)) +
			               ' because it is associated with dataset ' + Coalesce(@Dataset, '??') +
			               ' (ID ' + Cast (@DatasetID as varchar(12)) + ')'

			Set @myError = 75
			Goto Done
		End
	End

	---------------------------------------------------
	-- Start a transaction
	---------------------------------------------------

	declare @transName varchar(32) = 'DeleteRequestedRun'
	begin transaction @transName

	---------------------------------------------------
	-- delete associated factors
	---------------------------------------------------
	--
	DELETE FROM T_Factor
	WHERE TargetID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to delete factors for request'
		goto Done
	end

	---------------------------------------------------
	-- delete EUS users associated with request
	---------------------------------------------------
	--
	DELETE FROM dbo.T_Requested_Run_EUS_Users
	WHERE Request_ID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to delete EUS users for request'
		goto Done
	end

	---------------------------------------------------
	-- Delete requested run
	---------------------------------------------------
	--
	DELETE FROM dbo.T_Requested_Run
	WHERE ID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to delete request'
		goto Done
	end

	-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
	If Len(@callingUser) > 0
	Begin
		Declare @stateID int
		Set @stateID = 0

		Exec AlterEventLogEntryUser 11, @requestID, @stateID, @callingUser
	End

	commit transaction @transName

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    If @batchID > 0
    Begin
        Exec UpdateCachedRequestedRunBatchStats @batchID
    End

	---------------------------------------------------
	-- Complete
	---------------------------------------------------
	--
Done:
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[DeleteRequestedRun] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteRequestedRun] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO

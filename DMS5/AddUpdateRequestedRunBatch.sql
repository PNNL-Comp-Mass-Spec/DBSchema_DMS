/****** Object:  StoredProcedure [dbo].[AddUpdateRequestedRunBatch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateRequestedRunBatch
/****************************************************
**
**  Desc: Adds new or edits existing requested run batch
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 01/11/2006
**    
**    jds 9/15/06 Added support for five new variables and fields
**        @RequestedBatchPriority, @ActualBathPriority,
**        @RequestedCompletionDate, @JustificationHighPriority, @Comment
**
**			11/04/2006 grk - added @RequestedInstrument
**			12/03/2009 grk - checking for presence of @JustificationHighPriority if priority is high
**			05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @operPRN contains a person's real name rather than their username
**			08/04/2010 grk - try-catch for error handling
**			08/27/2010 mem - Now auto-switching @RequestedInstrument to be instrument group instead of instrument name
**						   - Expanded @RequestedCompletionDate to varchar(24) to support long dates of the form 'Jan 01 2010 12:00:00AM'
**			05/14/2013 mem - Expanded @RequestedCompletionDate to varchar(32) to support long dates of the form 'Jan 29 2010 12:00:00:000AM'
**			06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**
*****************************************************/
(
	@ID int output,
	@Name varchar(50),
	@Description varchar(256),
	@RequestedRunList varchar(4000),
	@OwnerPRN varchar(64),
	@RequestedBatchPriority varchar(24),
	@RequestedCompletionDate varchar(32),
	@JustificationHighPriority varchar(512),
	@RequestedInstrument varchar(64),				-- Will typically contain an instrument group, not an instrument name; could also contain "(lookup)"
	@Comment varchar(512),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if len(@RequestedCompletionDate) < 1 
	begin
		set @RequestedCompletionDate = null
	end
	else 
		if (SELECT ISDATE(@RequestedCompletionDate)) = 0
		begin
			RAISERROR ('Requested completion date is not a valid date: %s', 11, 1, @RequestedCompletionDate)
		end


	---------------------------------------------------
	-- Determine the Instrument Group
	---------------------------------------------------

	Declare @InstrumentGroup varchar(64) = ''
	
	-- Set the instrument group to @RequestedInstrument for now
	set @InstrumentGroup = @RequestedInstrument
	
	IF NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @InstrumentGroup)
	Begin
		-- Try to update instrument group using T_Instrument_Name
		SELECT @InstrumentGroup = IN_Group
		FROM T_Instrument_Name
		WHERE IN_Name = @RequestedInstrument
	End


	---------------------------------------------------
	-- High priority requires justification
	---------------------------------------------------
	--
	IF @RequestedBatchPriority = 'High' AND ISNULL(@JustificationHighPriority, '') = ''
	BEGIN
		set @message = 'Justification must be entered if high priority is being requested'
		RAISERROR (@message, 11, 15)
	END

	-- future: this could get more complicated
	
	---------------------------------------------------
	-- Is entry already in database? 
	---------------------------------------------------
	declare @tmp int

	-- cannot create an entry that already exists
	--
	if @mode = 'add'
	begin
		SELECT @tmp = ID
		FROM  T_Requested_Run_Batches
		WHERE  (Batch = @Name)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to find existing entry'
			RAISERROR (@message, 11, 16)
		end

		if @tmp <> 0
		begin
			set @message = 'Cannot add: entry already exists in database'
			RAISERROR (@message, 11, 17)
		end
	end

	-- cannot update a non-existent entry
	--
	if @mode = 'update'
	begin
		declare @lock varchar(12)
		--
		SELECT @tmp = ID, @lock = Locked
		FROM  T_Requested_Run_Batches
		WHERE  (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to find existing entry'
			RAISERROR (@message, 11, 18)
		end

		if @tmp = 0
		begin
			set @message = 'Cannot update: entry does not exits in database'
			RAISERROR (@message, 11, 19)
		end
		
		if @lock = 'yes'
		begin
			set @message = 'Cannot update: batch is locked'
			RAISERROR (@message, 11, 20)
		end
	end

	---------------------------------------------------
	-- Resolve user ID for owner PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @OwnerPRN
	if @userID = 0
	begin
		-- Could not find entry in database for PRN @OwnerPRN
		-- Try to auto-resolve the name

		Declare @MatchCount int
		Declare @NewPRN varchar(64)

		exec AutoResolveNameToPRN @OwnerPRN, @MatchCount output, @NewPRN output, @userID output

		If @MatchCount = 1
		Begin
			-- Single match found; update @OwnerPRN
			Set @OwnerPRN = @NewPRN
		End
		Else
		Begin
			set @message = 'Could not find entry in database for operator PRN "' + @OwnerPRN + '"'
			RAISERROR (@message, 11, 21)
		End
	end
	
	---------------------------------------------------
	-- create temporary table for requests in list
	---------------------------------------------------
	--
	CREATE TABLE #XR (
		Request_ID [int] NOT NULL
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table for requests'
		RAISERROR (@message, 11, 22)
	end

	---------------------------------------------------
	-- populate temporary table from list
	---------------------------------------------------
	--
	INSERT INTO #XR (Request_ID)
	SELECT cast(Item as int) 
	FROM MakeTableFromList(@RequestedRunList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to populate temporary table for requests'
		RAISERROR (@message, 11, 23)
	end

	---------------------------------------------------
	-- check status of prospective member requests
	---------------------------------------------------
	declare @count int
	
	-- do all requests in list actually exist?
	--
	set @count = 0
	--
	Select @count = count(*) 
	from #XR
	WHERE NOT (Request_ID IN 
	(
		SELECT ID
		FROM T_Requested_Run)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed trying to check existence of requests in list'
		RAISERROR (@message, 11, 24)
	end

	if @count <> 0
	begin
		set @message = 'Requested run list contains requests that do not exist'
		RAISERROR (@message, 11, 25)
	end

	
	-- are there any requests in the list that are part of another batch 
	-- especially locked batches
/*
	SELECT ID
	FROM T_Requested_Run
	WHERE RDS_BatchID in
	(Select Request_ID from #XR) AND 
	(RDS_BatchID <> 0) AND 
	(RDS_BatchID <> 0) AND 
*/

	-- start transaction
	--
	declare @transName varchar(32)
	set @transName = 'UpdateRequestState'
	begin transaction @transName

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Requested_Run_Batches (
			Batch, 
			Description, 
			Owner, 
			Locked,
			Requested_Batch_Priority,
			Actual_Batch_Priority,
			Requested_Completion_Date,
			Justification_for_High_Priority,
			Requested_Instrument, 
			Comment
		) VALUES (
			@Name, 
			@Description, 
			@userID, 
			'No',
			@RequestedBatchPriority,
			'Normal',
			@RequestedCompletionDate,
			@JustificationHighPriority,
			@InstrumentGroup, 
			@Comment
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 11, 26)
		end
	    
		-- return ID of newly created entry
		--
		Set @ID = SCOPE_IDENTITY()		

		-- As a precaution, query T_Requested_Run_Batches using Batch name to make sure we have the correct Exp_ID
		Declare @BatchIDConfirm int = 0
		
		SELECT @BatchIDConfirm = ID
		FROM T_Requested_Run_Batches
		WHERE Batch = @Name
		
		If @ID <> IsNull(@BatchIDConfirm, @ID)
		Begin
			Declare @DebugMsg varchar(512)
			Set @DebugMsg = 'Warning: Inconsistent identity values when adding batch ' + @Name + ': Found ID ' +
			                Cast(@BatchIDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' + 
			                Cast(@ID as varchar(12))
			                
			exec postlogentry 'Error', @DebugMsg, 'AddUpdateRequestedRunBatch'
			
			Set @ID = @BatchIDConfirm
		End
		
		
  end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Requested_Run_Batches
		SET Batch = @Name,
		    Description = @Description,
		    Owner = @userID,
		    Requested_Batch_Priority = @RequestedBatchPriority,
		    Requested_Completion_Date = @RequestedCompletionDate,
		    Justification_for_High_Priority = @JustificationHighPriority,
		    Requested_Instrument = @InstrumentGroup,
		    Comment = @Comment
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 11, 27)
		end
	end -- update mode
  
  ---------------------------------------------------
  -- update member requests 
  ---------------------------------------------------
  
  	if @Mode = 'add' OR @Mode = 'update' 
	begin
		-- remove any existing references to the batch
		-- from requested runs
		--
		UPDATE T_Requested_Run
		SET RDS_BatchID = 0
		WHERE RDS_BatchID = @ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Failed trying to remove batch reference from existing requests'
			RAISERROR (@message, 11, 28)
		end
		  
		-- add reference to this batch to the requests in the list
		--
 		UPDATE T_Requested_Run
		SET RDS_BatchID = @ID
		WHERE ID IN (Select Request_ID from #XR)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Failed trying to add batch reference to requests'
			RAISERROR (@message, 11, 29)
		end
	end
  
	commit transaction @transName

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'AddUpdateRequestedRunBatch'
	END CATCH
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRunBatch] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRunBatch] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRunBatch] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRunBatch] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[AddUpdateRequestedRunBatch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE AddUpdateRequestedRunBatch
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
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
	@ID int output,
	@Name varchar(50),
	@Description varchar(256),
	@RequestedRunList varchar(4000),
	@OwnerPRN varchar(24),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''


	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

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
			RAISERROR (@message, 10, 1)
			return 51004
		end

		if @tmp <> 0
		begin
			set @message = 'Cannot add: entry already exists in database'
			RAISERROR (@message, 10, 1)
			return 51004
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
			RAISERROR (@message, 10, 1)
			return 51004
		end

		if @tmp = 0
		begin
			set @message = 'Cannot update: entry does not exits in database'
			RAISERROR (@message, 10, 1)
			return 51004
		end
		
		if @lock = 'yes'
		begin
			set @message = 'Cannot update: batch is locked'
			RAISERROR (@message, 10, 1)
			return 51009
		end
	end

	---------------------------------------------------
	-- Resolve user ID for owner PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @OwnerPRN
	if @userID = 0
	begin
		set @message = 'Could not find entry in database for operator PRN "' + @OwnerPRN + '"'
		RAISERROR (@message, 10, 1)
		return 51019
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
		RAISERROR (@message, 10, 1)
		return 51219
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
		RAISERROR (@message, 10, 1)
		return 51219
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
		RAISERROR (@message, 10, 1)
		return 51219
	end

	if @count <> 0
	begin
		set @message = 'Requested run list contains requests that do not exist'
		RAISERROR (@message, 10, 1)
		return 51221
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
			Locked
		) VALUES (
			@Name, 
			@Description, 
			@userID, 
			'No'
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		end
	    
		-- return ID of newly created entry
		--
		set @ID = IDENT_CURRENT('T_Requested_Run_Batches')
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
		SET 
		Batch = @Name, 
		Description = @Description, 
		Owner = @userID
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
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
			rollback transaction @transName
			set @message = 'Failed trying to remove batch reference from existing requests'
			RAISERROR (@message, 10, 1)
			return 51004
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
			rollback transaction @transName
			set @message = 'Failed trying to add batch reference to requests'
			RAISERROR (@message, 10, 1)
			return 51004
		end
	end
  
	commit transaction @transName

	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRunBatch] TO [DMS_User]
GO

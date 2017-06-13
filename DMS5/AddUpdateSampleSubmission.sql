/****** Object:  StoredProcedure [dbo].[AddUpdateSampleSubmission] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateSampleSubmission
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_Sample_Submission
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 04/23/2010
**          04/30/2010 grk - Added call to CallSendMessage
**          09/23/2011 grk - Accomodate researcher field in AssureMaterialContainersExist
**			02/06/2013 mem - Added logic to prevent duplicate entries
**			12/08/2014 mem - Now using Name_with_PRN to obtain the user's name and PRN
**			03/26/2015 mem - Update duplicate sample submission message
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/13/2017 mem - Use SCOPE_IDENTITY()
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@ID int OUTPUT,
	@Campaign varchar(64),
	@ReceivedBy varchar(64),
	@ContainerList varchar(1024) OUTPUT,
	@NewContainerComment varchar(1024),
	@Description varchar(4096),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	DECLARE @msg VARCHAR(512)
	set @msg = ''

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @Campaign = IsNull(@Campaign, '')
	If @Campaign = ''
		RAISERROR('Campaign name cannot be empty', 11, 15)
	
	Set @ContainerList = IsNull(@ContainerList, '')
	If @ContainerList = ''
		RAISERROR('Container list cannot be empty', 11, 16)
	
	Set @ReceivedBy = IsNull(@ReceivedBy, '')
	If @ReceivedBy = ''
		RAISERROR('Received by name cannot be empty', 11, 17)
		
	Set @NewContainerComment = IsNull(@NewContainerComment, '')
	
	Set @Description = IsNull(@Description, '')
	If @Description = ''
		RAISERROR('Description cannot be blank', 11, 18)

	---------------------------------------------------
	-- Resolve Campaign ID
	---------------------------------------------------
	--
	DECLARE @CampaignID int
	SET @CampaignID = 0
	SELECT
		@CampaignID = Campaign_ID
	FROM
		T_Campaign
	WHERE
		Campaign_Num = @Campaign
	--
	IF @CampaignID = 0
		RAISERROR('Campaign "%s" could not be found', 11, 19, @Campaign)

	---------------------------------------------------
	-- Resolve PRN
	---------------------------------------------------
	--
	DECLARE @Researcher VARCHAR(128)
	DECLARE @ReceivedByUserID int
	SET @ReceivedByUserID = 0
	SELECT 
		@ReceivedByUserID = ID,
		@Researcher = Name_with_PRN
	FROM T_Users 
	WHERE U_PRN = @ReceivedBy
	--
	IF @CampaignID = 0
		RAISERROR('Username "%s" could not be found', 11, 20, @ReceivedBy)

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_Sample_Submission
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 21)
	end
	
	---------------------------------------------------
	-- Define the transaction name
	---------------------------------------------------
	declare @transName varchar(32)
	set @transName = 'AddUpdateSampleSubmission'

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	if @Mode = 'add'
	begin

		---------------------------------------------------
		-- verify container list
		---------------------------------------------------
		--
		DECLARE @cl varchar(1024)
		SET @cl = @ContainerList
		--
		EXEC @myError = AssureMaterialContainersExist
							@ContainerList = @cl OUTPUT,
							@Comment = '',
							@Type = '',
							@Researcher = @Researcher,
							@mode = 'verify_only',
							@message = @msg output,
							@callingUser = ''
		--
		IF @myError <> 0
			RAISERROR('AssureMaterialContainersExist: %s', 11, 22, @message)

		---------------------------------------------------
		-- Verify that this doesn't duplicate an existing sample submission request
		---------------------------------------------------
		Set @ID = -1
		--
		SELECT @ID = ID
		FROM T_Sample_Submission
		WHERE Campaign_ID = @CampaignID AND Received_By_User_ID = @ReceivedByUserID AND Description = @Description
		
		If @ID > 0
			RAISERROR('New sample submission is duplicate of existing sample submission, ID %d; both have identical Campaign, Received By User, and Description', 11, 23, @ID)
		
		---------------------------------------------------
		-- Add the new data
		--
		begin transaction @transName

		INSERT INTO T_Sample_Submission (
			Campaign_ID,
			Received_By_User_ID,
			Container_List,
			Description,
			Storage_Path
		) VALUES (
			@CampaignID,
			@ReceivedByUserID,
			@ContainerList,
			@Description,
			NULL
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed', 11, 24)

		-- Return ID of newly created entry
		--
		set @ID = SCOPE_IDENTITY()

		---------------------------------------------------
		-- add containers (as needed)
		--
		DECLARE @Comment varchar(1024)
		If @NewContainerComment = ''
			SET @Comment = '(created via sample submission ' + CONVERT(VARCHAR(12), @ID) + ')'
		Else
			SET @Comment = @NewContainerComment + ' (sample submission ' + CONVERT(VARCHAR(12), @ID) + ')'
		--
		EXEC @myError = AssureMaterialContainersExist
						@ContainerList = @ContainerList OUTPUT,
						@Comment = @Comment,
						@Type = 'Box',
						@Researcher = @Researcher,
						@mode = 'create',
						@message = @msg output,
						@callingUser = @callingUser
		--
		IF @myError <> 0
			RAISERROR('AssureMaterialContainersExist: %s', 11, 25, @message)

		---------------------------------------------------
		-- update container list for sample submission
		--
		UPDATE T_Sample_Submission 
		SET Container_List = @ContainerList 
		WHERE ID = @ID
			
		commit transaction @transName

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Sample_Submission 
		SET 
		Campaign_ID = @CampaignID,
		Received_By_User_ID = @ReceivedByUserID,
		Container_List = @ContainerList,
		Description = @Description
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%d"', 11, 26, @ID)

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'AddUpdateSampleSubmission'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSampleSubmission] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateSampleSubmission] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSampleSubmission] TO [Limited_Table_Write] AS [dbo]
GO

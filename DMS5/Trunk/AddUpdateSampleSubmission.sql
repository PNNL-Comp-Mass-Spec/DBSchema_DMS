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
**			04/30/2010 grk - Added call to CallSendMessage
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@ID int OUTPUT,
	@Campaign varchar(64),
	@ReceivedBy varchar(64),
	@ContainerList varchar(1024) OUTPUT,
	@NewContainerComment varchar(1024),
	@Description varchar(4096),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	DECLARE @msg VARCHAR(512)
	set @msg = ''

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated

	---------------------------------------------------
	-- 
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
		RAISERROR('Campaign "%s" could not be found', 11, 15, @Campaign)

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	DECLARE @ReceivedByUserID int
	SET @ReceivedByUserID = 0
	SELECT @ReceivedByUserID = ID FROM T_Users WHERE U_PRN = @ReceivedBy
	--
	IF @CampaignID = 0
		RAISERROR('User "%s" could not be found', 11, 16, @ReceivedBy)

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
			RAISERROR ('No entry could be found in database for update', 11, 16)
	end
	
	---------------------------------------------------
	--
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
		--
		DECLARE @cl varchar(1024)
		SET @cl = @ContainerList
		--
		EXEC @myError = AssureMaterialContainersExist
						@ContainerList = @cl OUTPUT,
						@Comment = '',
						@Type = '',
						@mode = 'verify_only',
						@message = @msg output,
						@callingUser = ''
		--
		IF @myError <> 0
			RAISERROR('AssureMaterialContainersExist:%s', 11, 31, @message)

		---------------------------------------------------
		begin transaction @transName

		---------------------------------------------------
		--
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
			RAISERROR ('Insert operation failed', 11, 7)

		-- return ID of newly created entry
		--
		set @ID = IDENT_CURRENT('T_Sample_Submission')

		---------------------------------------------------
		-- add containers (as needed)
		--
		DECLARE @Comment varchar(1024)
		SET @Comment = @NewContainerComment + ' (sample submission ' + CONVERT(VARCHAR(12), @ID) + ')'
		--
		EXEC @myError = AssureMaterialContainersExist
						@ContainerList = @ContainerList OUTPUT,
						@Comment = @Comment,
						@Type = 'Box',
						@mode = 'create',
						@message = @msg output,
						@callingUser = @callingUser
		--
		IF @myError <> 0
			RAISERROR('AssureMaterialContainersExist:%s', 11, 31, @message)

		---------------------------------------------------
		-- update container list for sample submission
		--
		UPDATE T_Sample_Submission 
		SET Container_List = @ContainerList 
		WHERE ID = @ID
			
		---------------------------------------------------
		commit transaction @transName

		---------------------------------------------------

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
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateSampleSubmission] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSampleSubmission] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[AddUpdateEUSProposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateEUSProposals
/****************************************************
**
**	Desc: Adds new or updates existing EUS Proposals in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@EUSPropID  EUS Proposal ID
**		@EUSPropState EUS Proposal State
**		@EUSPropTitle EUS Proposal Title
**		@EUSPropImpDate EUS Proposal Import Date
**		@EUSUsersList EUS User list
**
**		Auth: jds
**		Date: 08/15/2006
**			  11/16/2006 grk - fix problem with GetEUSPropID not able to return varchar (ticket #332)   
**		      
**    
*****************************************************/
(
	@EUSPropID varchar(10), 
	@EUSPropState varchar(32), 
	@EUSPropTitle varchar(2048), 
	@EUSPropImpDate varchar(22),
	@EUSUsersList varchar(4096), 
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@EUSPropID) < 1
	begin
		set @myError = 51000
		RAISERROR ('EUS Proposal ID was blank', 10, 1)
	end
	--
	if LEN(@EUSPropState) < 1
	begin
		set @myError = 51000
		RAISERROR ('EUS Proposal State was blank', 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if LEN(@EUSPropTitle) < 1
	begin
		set @myError = 51000
		RAISERROR ('EUS Proposal Title was blank', 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	set @myError = 0
	if LEN(@EUSPropImpDate) < 1 and ISDATE(@EUSPropImpDate) = 1
	begin
		set @myError = 51000
		RAISERROR ('EUS Proposal Import Date was blank or an invalid date', 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	set @myError = 0
	if @EUSPropState = '2' and LEN(@EUSUsersList) < 1
	begin
		set @myError = 51000
		RAISERROR ('An "Active" EUS Proposal must have at least 1 associated EMSL User', 10, 1)
	end
	--
	if @myError <> 0
		return @myError
	---------------------------------------------------
	-- clear all associations if the user list is blank
	---------------------------------------------------
	
	if @EUSUsersList = ''
	begin
		DELETE FROM T_EUS_Proposal_Users
		WHERE     (Proposal_ID = @EUSPropID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to clear all user associations for this proposal'
			RAISERROR (@msg, 10, 1)
			return 51081
		end
	end

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------
	declare @TempEUSPropID varchar(10)
	set @TempEUSPropID = '0'
	--
	SELECT @tempEUSPropID = PROPOSAL_ID 
	FROM T_EUS_Proposals 
	WHERE (PROPOSAL_ID = @EUSPropID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look for entry in table'
		RAISERROR (@msg, 10, 1)
		return 51082
	end

	-- cannot create an entry that already exists
	--
	if @TempEUSPropID <> '0' and @mode = 'add'
	begin
		set @msg = 'Cannot add: EUS Proposal ID "' + @EUSPropID + '" is already in the database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @TempEUSPropID = '0' and @mode = 'update'
	begin
		set @msg = 'Cannot update: EUS Proposal ID "' + @EUSPropID + '" is not in the database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_EUS_Proposals (
			PROPOSAL_ID, 
			TITLE, 
			State_ID, 
			Import_Date
		) VALUES (
			@EUSPropID, 
			@EUSPropTitle, 
			@EUSPropState, 
			@EUSPropImpDate
		)

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @EUSPropTitle + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end


	end -- add mode


	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_EUS_Proposals 
		SET 
			TITLE = @EUSPropTitle, 
			State_ID = @EUSPropState, 
			Import_Date = @EUSPropImpDate 
		WHERE (PROPOSAL_ID = @EUSPropID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @EUSPropTitle + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode


		---------------------------------------------------
		-- delete users that do not exsit in the  
		-- T_EUS_Users table to prevent join failure
		---------------------------------------------------

		CREATE TABLE #tempEUSUsers (
	           PERSON_ID int
	           )

		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error creating temporary user table'
			return 51008
		end

		INSERT INTO #tempEUSUsers
			(Person_ID)
		SELECT 
			CAST(Item as int) as EUS_Person_ID
		FROM 
			MakeTableFromList(@eusUsersList)
		WHERE 
			CAST(Item as int) IN
			(
				SELECT Person_ID
				FROM  T_EUS_Users 
			)

		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to add to temporary user table'
			return 51009
		end
		---------------------------------------------------
		-- add associations between proposal and users 
		-- who are in list, but not in association table
		---------------------------------------------------
		--
		INSERT INTO T_EUS_Proposal_Users
			(Person_ID, Proposal_ID)
		SELECT 
			Person_ID, @EUSPropID as Proposal_ID
		FROM 
			#tempEUSUsers
		WHERE 
			PERSON_ID NOT IN
			(
				SELECT Person_ID
				FROM  T_EUS_Proposal_Users 
				WHERE Proposal_ID = @EUSPropID
			)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to add associations for new users'
			return 51083
		end

	return 0




GO
GRANT EXECUTE ON [dbo].[AddUpdateEUSProposals] TO [DMS_EUS_Admin]
GO
GRANT EXECUTE ON [dbo].[AddUpdateEUSProposals] TO [DMS2_SP_User]
GO

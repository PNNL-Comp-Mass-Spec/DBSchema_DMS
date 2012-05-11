/****** Object:  StoredProcedure [dbo].[AddUpdateEUSProposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateEUSProposals
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
**	Auth:	jds
**	Date:	08/15/2006
**			11/16/2006 grk - fix problem with GetEUSPropID not able to return varchar (ticket #332)  
**			04/01/2011 mem - Now updating State_ID in T_EUS_Proposal_Users
**    
*****************************************************/
(
	@EUSPropID varchar(10), 
	@EUSPropState varchar(32),				-- 1=New, 2=Active, 3=Inactive, 4=No Interest
	@EUSPropTitle varchar(2048), 
	@EUSPropImpDate varchar(22),
	@EUSUsersList varchar(4096), 
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	Declare @EUSPropStateID int
	
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
	
	Set @EUSPropStateID = Convert(int, @EUSPropState)
	
	if @EUSPropStateID = 2 and LEN(@EUSUsersList) < 1
	begin
		set @myError = 51000
		RAISERROR ('An "Active" EUS Proposal must have at least 1 associated EMSL User', 10, 1)
	end
	--
	if @myError <> 0
		return @myError
	
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
			@EUSPropStateID, 
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
			State_ID = @EUSPropStateID, 
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
	-- Associate users in @eusUsersList with the proposal
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
	SELECT EUS_Person_ID
	FROM ( SELECT CAST(Item AS int) AS EUS_Person_ID
	       FROM MakeTableFromList ( @eusUsersList ) 
	     ) SourceQ
	     INNER JOIN T_EUS_Users
	       ON SourceQ.EUS_Person_ID = T_EUS_Users.Person_ID
	--
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
	Declare @ProposalUserStateID int
	
	If @EUSPropStateID IN (1,2)
		Set @ProposalUserStateID = 1
	Else
		Set @ProposalUserStateID = 2
	
	
	MERGE T_EUS_Proposal_Users AS target
	USING 
		(
			SELECT @EUSPropID AS Proposal_ID,
			        Person_ID,
			        'Y' AS Of_DMS_Interest
			FROM #tempEUSUsers
		) AS Source (Proposal_ID, Person_ID, Of_DMS_Interest)
	ON (target.Proposal_ID = source.Proposal_ID AND
		target.Person_ID = source.Person_ID)
	WHEN MATCHED AND IsNull(target.State_ID, 0) NOT IN (@ProposalUserStateID, 4)
		THEN UPDATE 
			Set	State_ID = @ProposalUserStateID,
				Last_Affected = GetDate()
	WHEN Not Matched THEN
		INSERT (Proposal_ID, Person_ID, Of_DMS_Interest, State_ID, Last_Affected)
		VALUES (source.Proposal_ID, source.PERSON_ID, source.Of_DMS_Interest, @ProposalUserStateID, GetDate())
	WHEN NOT MATCHED BY SOURCE AND IsNull(State_ID, 0) NOT IN (4) THEN
		-- User/proposal mapping is defined in T_EUS_Proposal_Users but not in #tempEUSUsers
		-- Change state to 5="No longer associated with proposal"
		UPDATE SET State_ID=5, Last_Affected = GetDate()
	;
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to add associations between users and proposal'
		return 51083
	end

		
	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateEUSProposals] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateEUSProposals] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateEUSProposals] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateEUSProposals] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateEUSProposals] TO [PNL\D3M580] AS [dbo]
GO

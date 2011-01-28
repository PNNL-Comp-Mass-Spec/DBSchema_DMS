/****** Object:  StoredProcedure [dbo].[ValidateEUSUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ValidateEUSUsage
/****************************************************
**
**	Desc: 
**    Verifies that given usage type, proposal ID, 
**    and user list are valid for DMS
**
**    Clears contents of @eusProposalID and @eusUsersList
**    for certain values of @eusUsageType
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	07/11/2007 grk - Initial Version
**			09/09/2010 mem - Added parameter @AutoPopulateUserListIfBlank
**						   - Now auto-clearing @eusProposalID and @eusUsersList if @eusUsageType is not 'USER'
**
*****************************************************/
(
	@eusUsageType varchar(50),
	@eusProposalID varchar(10) output,
	@eusUsersList varchar(1024) output,
	@eusUsageTypeID int output,
	@message varchar(512) output,
	@AutoPopulateUserListIfBlank tinyint = 0	-- When 1, then will auto-populate @eusUsersList if it is empty and @eusUsageType = 'USER'
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0

	set @myRowCount = 0
	
	declare @n int
	declare @UserCount int
	declare @PersonID int
	declare @NewUserList varchar(1024)
	
	set @message = ''
	Set @eusUsersList = IsNull(@eusUsersList, '')
	Set @AutoPopulateUserListIfBlank = IsNull(@AutoPopulateUserListIfBlank, 0)

	---------------------------------------------------
	-- resolve EUS usage type name to ID
	---------------------------------------------------
	set @eusUsageTypeID = 0
	--
	SELECT @eusUsageTypeID = ID
	FROM T_EUS_UsageType
	WHERE  (Name = @eusUsageType)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to resolve EUS usage type: "' + @eusUsageType + '"'
		return 51070
	end
	--
	if @eusUsageTypeID = 0
	begin
		set @message = 'Could not resolve EUS usage type: "' + @eusUsageType + '"'
		return 51071
	end

	---------------------------------------------------
	-- validate EUS proposal and user
	-- if EUS usage type requires them
	---------------------------------------------------
	--
	if @eusUsageType <> 'USER'
	begin
		-- Make sure no proposal ID or users are specified
		if IsNull(@eusProposalID, '') <> '' OR @eusUsersList <> ''
			Set @message = 'Warning: Cleared proposal ID and/or users since usage type is "' + @eusUsageType + '"'

		set @eusProposalID = NULL
		set @eusUsersList = ''
	end
	
	if @eusUsageType = 'USER'
	begin -- <a>

		---------------------------------------------------
		-- proposal and user list cannot be blank when the usage type is 'USER'
		---------------------------------------------------
		if IsNull(@eusProposalID, '') = ''
		begin
			set @message = 'A Proposal ID must be selected for usage type "' + @eusUsageType + '"'
			return 51073
		end

		---------------------------------------------------
		-- verify EUS proposal ID
		---------------------------------------------------
		
		IF NOT EXISTS (SELECT * FROM T_EUS_Proposals WHERE PROPOSAL_ID = @eusProposalID)	
		begin
			set @message = 'Unknown EUS proposal ID: "' + @eusProposalID + '"'
			return 51075
		end
		
		If @eusUsersList = ''
		Begin
			-- Blank user list
			--
			If @AutoPopulateUserListIfBlank = 0
			Begin
				set @message = 'Associated users must be selected for usage type "' + @eusUsageType + '"'
				return 51074
			End
		
			-- Auto-populate @eusUsersList with the first user associated with the given user proposal
			--
			Set @PersonID = 0
			
			SELECT @PersonID = MIN(EUSU.Person_ID)
			FROM T_EUS_Proposals EUSP
				INNER JOIN T_EUS_Proposal_Users EUSU
				ON EUSP.PROPOSAL_ID = EUSU.Proposal_ID
			WHERE (EUSP.PROPOSAL_ID = @eusProposalID)
			
			If IsNull(@PersonID, 0) > 0
			Begin
				Set @eusUsersList = Convert(varchar(12), @PersonID)
				Set @message = 'Warning: EUS User list was empty; auto-selected user "' + @eusUsersList + '"'
			End
		End
 
		
		If @eusUsersList <> ''
		Begin -- <b>
			---------------------------------------------------
			-- verify that all users in list have access to
			-- given proposal
			---------------------------------------------------

			declare @tmpUsers TABLE
			(
				Item varchar(256)
			)
   
			INSERT INTO @tmpUsers (Item)
			SELECT Item
			FROM MakeTableFromList(@eusUsersList)
			
			set @n = 0

			SELECT 
				@n = @n + (1 - isnumeric(item))
			FROM @tmpUsers
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to verify that all user ID are numeric'
				return 51076
			end

			if @n <> 0
			begin
				set @message = 'EMSL User IDs must be numeric'
				return 51077
			end
			
			set @n = 0
			SELECT @n = count(*)
			FROM  @tmpUsers
			WHERE 
				CAST(Item as int) NOT IN
				(
					SELECT Person_ID
					FROM  T_EUS_Proposal_Users
					WHERE Proposal_ID = @eusProposalID
				)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to verify that all users are associated with proposal'
				return 51078
			end

			if @n <> 0
			begin -- <c>
			
				-- Invalid users were found
				--
				If @AutoPopulateUserListIfBlank = 0
				Begin
					set @message = Convert(varchar(12), @n)
					If @n = 1
						set @message = @message + ' user is'
					Else
						set @message = @message + ' users are'
						
					set @message = @message + ' not associated with the specified proposal'
					return 51079
				End
			
				-- Auto-remove invalid entries from @tmpUsers
				--
				DELETE
				FROM  @tmpUsers
				WHERE 
					CAST(Item as int) NOT IN
					(
						SELECT Person_ID
						FROM  T_EUS_Proposal_Users
						WHERE Proposal_ID = @eusProposalID
					)

				set @UserCount = 0			
				SELECT @UserCount = COUNT(*)
				FROM @tmpUsers
			
				Set @NewUserList = ''
			
				If @UserCount >= 1
				Begin
					-- Reconstruct the users list
					Set @NewUserList = ''
					SELECT @NewUserList = @NewUserList + ', ' + Item
					FROM @tmpUsers
					
					-- Remove the first two characters
					if IsNull(@NewUserList, '') <> ''
						Set @NewUserList = SubString(@NewUserList, 3, Len(@NewUserList))
				End
				
				If IsNull(@NewUserList, '') = ''
				Begin
					-- Auto-populate @eusUsersList with the first user associated with the given user proposal
					Set @PersonID = 0
					
					SELECT @PersonID = MIN(EUSU.Person_ID)
					FROM T_EUS_Proposals EUSP
						INNER JOIN T_EUS_Proposal_Users EUSU
						ON EUSP.PROPOSAL_ID = EUSU.Proposal_ID
					WHERE (EUSP.PROPOSAL_ID = @eusProposalID)
					
					If IsNull(@PersonID, 0) > 0
						Set @NewUserList = Convert(varchar(12), @PersonID)
				End
				
				Set @eusUsersList = IsNull(@NewUserList, '')
				Set @message = 'Warning: Removed useres from EUS User list that are not associated with proposal "' + @eusProposalID + '"'
								
			End -- </c>
			
		End -- </b>

	end -- </a>

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [PNL\D3M580] AS [dbo]
GO

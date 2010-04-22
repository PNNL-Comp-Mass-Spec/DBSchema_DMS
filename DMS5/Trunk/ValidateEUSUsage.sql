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
**		Auth: grk
**		Date: 07/11/2007
**
*****************************************************/
	@eusUsageType varchar(50),
	@eusProposalID varchar(10) output,
	@eusUsersList varchar(1024) output,
	@eusUsageTypeID int output,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @n int
	
	set @message = ''

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
			if @eusProposalID <> '' OR @eusUsersList <> ''
			begin
				set @message = 'No Proposal ID nor users are to be associated with "' + @eusUsageType + '" usage type'
				return 51072
			end
			set @eusProposalID = NULL
			set @eusUsersList = ''
		end
	else
		begin			
			---------------------------------------------------
			-- proposal and user list cannot be blank
			---------------------------------------------------
			if @eusProposalID = '' OR @eusUsersList = ''
			begin
				set @message = 'A Proposal ID and associated users must be selected for "' + @eusUsageType + '" usage type'
				return 51073
			end

			---------------------------------------------------
			-- verify EUS proposal ID
			---------------------------------------------------
			set @n = 0
			--
			SELECT @n = count(*)
			FROM T_EUS_Proposals
			WHERE (PROPOSAL_ID = @eusProposalID)	
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to verify EUS proposal ID: "' + @eusProposalID + '"'
				return 51074
			end
			--
			if @n <> 1
			begin
				set @message = 'Could not verify EUS proposal ID: "' + @eusProposalID + '"'
				return 51075
			end

		end

	---------------------------------------------------
	-- verify that all users in list have access to
	-- given proposal
	---------------------------------------------------

	if @eusUsageType = 'USER'
	begin
		set @n = 0

		SELECT 
			@n = @n + (1 - isnumeric(item))
		FROM 
			MakeTableFromList(@eusUsersList)
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
		SELECT 
			@n = count(*)
		FROM 
			MakeTableFromList(@eusUsersList)
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
		begin
			set @message = 'Some assigned users are not associated with the specified proposal'
			return 51079
		end
	end -- if @eusUsageType = 'USER'

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [PNL\D3M580] AS [dbo]
GO

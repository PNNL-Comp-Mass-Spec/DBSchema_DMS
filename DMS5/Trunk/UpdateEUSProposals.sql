/****** Object:  StoredProcedure [dbo].[UpdateEUSProposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure UpdateEUSProposals
/****************************************************
**
**	Desc: 
**	Changes atributes of EUS proposals
**	to given new value for given list of requested runs
**  and updates associated EUS user associations for
**  proposals that are currently active in DMS
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 2/26/2006
**    
*****************************************************/
	@mode varchar(32), -- ''
	@newValue varchar(512),
	@eusProposalIDList varchar(2048)
As
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	--
	declare @id int
	--
	declare @tPos int
	set @tPos = 1
	declare @tFld varchar(128)

	-- process lists into rows
	-- and insert into DB table
	--
	set @count = 0
	set @done = 0

	if @mode = 'state'
	begin -- mode 'state'
		-------------------------------------------------
		-- resolve new state to ID
		--
		declare @st int
		set @st = 0
		--
		SELECT @st = ID
		FROM T_EUS_Proposal_State_Name
		WHERE (Name = @newValue)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		--
		if @st = 0
		begin
			RAISERROR ('Could not resolve state name', 10, 1)
			return 51302
		end
		
		-------------------------------------------------
		-- check allowed state transition
		--
		if @st = 1
		begin
			RAISERROR ('Cannot set state to new: "%s"', 10, 1, @tFld)
			return 51310
		end
		
		-------------------------------------------------
		-- update state of proposals in list
		--
		UPDATE T_EUS_Proposals
		SET State_ID = @st
		WHERE PROPOSAL_ID IN
		(
		SELECT * FROM dbo.MakeTableFromList(@eusProposalIDList)
		)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		--
		if @myError <> 0
		begin
			RAISERROR ('Error trying up update state in table', 10, 1)
			return 51310
		end
	
		---------------------------------------------------
		-- update EUS user information for active proposals
		---------------------------------------------------
		declare @message varchar(512)
		set @message = ''
		--
		exec @myError = UpdateEUSUsersFromEUSImports @message output
		--
		if @myError <> 0
		begin
			RAISERROR (@message, 10, 1)
			return @myError
		end	
	end -- mode 'state'
	
	if @mode = 'import'
	begin -- mode 'import'
		---------------------------------------------------
		-- add proposals from EUS import DB
		-- that are not already in the DMS EUS proposal table
		---------------------------------------------------
		--
		INSERT INTO T_EUS_Proposals
			(PROPOSAL_ID, TITLE)
		SELECT PROPOSAL_ID, TITLE
		FROM EMSL_User.dbo.PROPOSALS
		WHERE PROPOSAL_ID not in 
		(
			SELECT PROPOSAL_ID
			FROM T_EUS_Proposals
		)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		--
		if @myError <> 0
		begin
			RAISERROR ('Error trying to import new proposals from EUS', 10, 1)
			return 51310
		end
	end -- mode 'import'


	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateEUSProposals] TO [DMS_EUS_Admin]
GO

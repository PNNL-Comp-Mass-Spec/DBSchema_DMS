/****** Object:  StoredProcedure [dbo].[UpdateEUSProposalUsers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Procedure UpdateEUSProposalUsers
/****************************************************
**
**	Desc: 
**	Changes atributes of EUS users
**	to given new value for given list of users
**  for the given EUS proposal
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
	@eusProposalID varchar(10),
	@eusUserIDList varchar(2048)
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

	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'dms_interest'
	begin -- mode 'dms_interest'

		---------------------------------------------------
		-- Update DMS interest of all users in list
		--
		UPDATE T_EUS_Proposal_Users
		SET Of_DMS_Interest = @newValue
		WHERE Proposal_ID = @eusProposalID AND 
		PERSON_ID IN 
		(
			SELECT * FROM dbo.MakeTableFromList(@eusUserIDList)
		)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		--
		if @myError <> 0
		begin
			RAISERROR ('Error trying to update DMS interest', 10, 1)
			return 51310
		end
	end  -- mode 'dms_interest'

	---------------------------------------------------
	-- 
	---------------------------------------------------


	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateEUSProposalUsers] TO [DMS_EUS_Admin]
GO

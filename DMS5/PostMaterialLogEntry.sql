/****** Object:  StoredProcedure [dbo].[PostMaterialLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure dbo.PostMaterialLogEntry
/****************************************************
**
**  Desc: Adds new entry to T_Material_Log
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	03/20/2008
**			03/25/2008 mem - Now validating that @callingUser is not blank
**			03/26/2008 grk - added handling for comment
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@Type varchar(32),
	@Item varchar(128),
	@InitialState varchar(128),
	@FinalState varchar(128),
	@callingUser varchar(128) = '',
	@comment varchar(512)
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	declare @message varchar(512)
	set @message = ''

	---------------------------------------------------
	-- Make sure @callingUser is not blank
	---------------------------------------------------
	
	Set @callingUser = IsNull(@callingUser, '')
	If Len(@callingUser) = ''
		Set @callingUser = suser_sname()

	---------------------------------------------------
	-- weed out useless postings 
	-- (example: movement where origin same as destination)
	---------------------------------------------------

	if @InitialState = @FinalState
	begin
		return 0
	end

	---------------------------------------------------
	-- action
	---------------------------------------------------

	INSERT INTO T_Material_Log (
		Type, 
		Item, 
		Initial_State, 
		Final_State, 
		User_PRN,
		Comment
	) VALUES (
		@Type, 
		@Item, 
		@InitialState, 
		@FinalState, 
		@callingUser,
		@comment
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Insert operation failed'
		RAISERROR (@message, 10, 1)
		return 51007
	end


	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[PostMaterialLogEntry] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[PostMaterialLogEntry] TO [PNL\D3M578] AS [dbo]
GO

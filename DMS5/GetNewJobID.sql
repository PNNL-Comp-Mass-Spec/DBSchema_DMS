/****** Object:  StoredProcedure [dbo].[GetNewJobID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE dbo.GetNewJobID
/****************************************************
**
**  Desc: 
**    Gets a unique number for making a new job
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 08/04/2009
**			08/05/2009 grk - initial release (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**			08/05/2009 mem - Now using SCOPE_IDENTITY() to determine the ID of the newly added row
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@note varchar(266)
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @id int
	set @id = 0

	-- insert new row in job ID table to create unique ID
	--
	INSERT INTO T_Analysis_Job_ID (
		Note
	) VALUES (
		@Note
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError = 0
	begin
		-- get ID of newly created entry
		--
		set @id = SCOPE_IDENTITY()
	end

	return @id

GO
GRANT EXECUTE ON [dbo].[GetNewJobID] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetNewJobID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetNewJobID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetNewJobID] TO [PNL\D3M580] AS [dbo]
GO

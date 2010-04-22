/****** Object:  StoredProcedure [dbo].[ReplaceLCCartComponent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ReplaceLCCartComponent
/****************************************************
**
**  Desc: 
**    Replaces component (if any) currently
**    installed at the given cart position
**    with the given component
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 06/25/2008 - (ticket http://prismtrac.pnl.gov/trac/ticket/604)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @PositionID int,
  @CartName varchar(128),
  @PositionName varchar(64),
  @ComponentType varchar(128),
  @ComponentID int, 
  @Comment varchar(1024),
  @mode varchar(12) = 'update',
  @message varchar(512) output,
  @callingUser varchar(128) = ''
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''



	---------------------------------------------------
	-- make sure new component is valid
	---------------------------------------------------
	--
	exec @myError = UpdateLCCartComponentPosition
						'replace',
						@PositionID,
						@ComponentID, 
						@Comment,
						@message output,
						@callingUser
	--
	if @myError <> 0
	begin
		set @message = 'Error updating position'
		RAISERROR (@message, 10, 1)
		return @myError
	end

	return @myError

 
GO
GRANT EXECUTE ON [dbo].[ReplaceLCCartComponent] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReplaceLCCartComponent] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReplaceLCCartComponent] TO [PNL\D3M580] AS [dbo]
GO

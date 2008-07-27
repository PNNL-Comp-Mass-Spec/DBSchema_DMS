/****** Object:  StoredProcedure [dbo].[ServiceLCCartComponent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ServiceLCCartComponent
/****************************************************
**
**  Desc: 
**    Adds service record for given component
**    to component history
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    06/25/2008 grk -- initial release
**    07/18/2008 grk -- pruned uneeded arguments
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
	@ComponentID int,
	@Type int, -- ignore
	@SerialNumber varchar(128), -- ignore
	@Action varchar(128),
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
	-- resolve user
	---------------------------------------------------
	--
	set @callingUser = IsNull(@callingUser, '')
	--
	declare @userID int
	set @userID = 0
	--
	SELECT @userID = ID
	FROM	T_Users
	WHERE U_PRN = @callingUser
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving user ID'
		RAISERROR (@message, 10, 1)
		return 51000
	end

	---------------------------------------------------
	-- make sure new component is valid
	---------------------------------------------------
	--
	declare @tmp int
	set @tmp = 0
	--
	declare @current_position int
	--
	SELECT
		@tmp = Type,
		@current_position =  Component_Position
	FROM
		T_LC_Cart_Components
	WHERE
		ID = @ComponentID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting information about component'
		RAISERROR (@message, 10, 1)
		return 51001
	end
	--
	if @tmp = 0
	begin
		set @message = 'Component ID is not valid'
		RAISERROR (@message, 10, 1)
		return 51002
	end

	---------------------------------------------------
	-- make new history entry for new component
	---------------------------------------------------
	--
	INSERT INTO T_LC_Cart_Component_History (
		Operator,
		Action,
		Starting_Date,
		Ending_Date,
		COMMENT,
		Cart_Component,
		Component_Position
	) VALUES (  
		@userID,
		@Action,
		Getdate(),
		Getdate(),
		@comment,
		@ComponentID,
		@current_position
	)
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error making entry for new component'
		RAISERROR (@message, 10, 1)
		return 51003
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------


  return @myError

 
GO
GRANT EXECUTE ON [dbo].[ServiceLCCartComponent] TO [DMS2_SP_User]
GO

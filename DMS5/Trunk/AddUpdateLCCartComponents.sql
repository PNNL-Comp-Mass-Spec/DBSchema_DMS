/****** Object:  StoredProcedure [dbo].[AddUpdateLCCartComponents] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE AddUpdateLCCartComponents
/****************************************************
**
**  Desc: Adds new or edits existing LC Cart Component
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 06/23/2008
**		Auth: grk   - (ticket http://prismtrac.pnl.gov/trac/ticket/604)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
  @ID int,
  @Type varchar(128),
  @Status varchar(32),
  @Description varchar(1024),
  @Manufacturer varchar(128),
  @PartNumber varchar(128),
  @SerialNumber varchar(128),
  @PropertyNumber varchar(128),
  @CartName varchar(128),
  @PositionName varchar(64),
  @Comment varchar(1024),
  @mode varchar(12) = 'add', -- or 'update'
  @message varchar(512) output,
  @callingUser varchar(128) = ''
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	declare @result int

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	---------------------------------------------------
	-- Validate cart name and position
	---------------------------------------------------
	--
	if(@mode != 'add' AND (@CartName = '' or @PositionName = ''))
	begin
		set @message = 'Cart name and position must be blank except for creating new component'
		RAISERROR (@message, 10, 1)
		return 51001
	end

	if(NOT ((@CartName = '' and @PositionName = '') OR (@CartName != '' and @PositionName != '')))
	begin
		set @message = 'Cart name and position must both be blank or both be not blank'
		RAISERROR (@message, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- resolve cart and position to position ID
	---------------------------------------------------
	--
	if @CartName <> '' and @PositionName <> ''
	begin
		declare @PositionID int
		set @PositionID = 0
		--
		SELECT 
		  @PositionID = T_LC_Cart_Component_Postition.ID
		FROM   
		  T_LC_Cart
		  INNER JOIN T_LC_Cart_Component_Postition
			ON T_LC_Cart.ID = T_LC_Cart_Component_Postition.Cart_ID
		  INNER JOIN T_LC_Cart_Positions
			ON T_LC_Cart_Component_Postition.Position_ID = T_LC_Cart_Positions.ID
		WHERE  (T_LC_Cart.Cart_Name = @CartName)
		AND (T_LC_Cart_Positions.Name = @PositionName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error resolving cart position ID'
			RAISERROR (@message, 10, 1)
			return 51002
		end
		--
		if @PositionID = 0
		begin
			set @message = 'No cart position found'
			RAISERROR (@message, 10, 1)
			return 51002
		end
	end

	---------------------------------------------------
	-- resolve component type name to id
	---------------------------------------------------
	--
	declare @typeID int
	set @typeID = 0
	-- 
	SELECT @typeID =  ID
	FROM T_LC_Cart_Component_Type
	WHERE Type = @Type
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving type ID'
		RAISERROR (@message, 10, 1)
		return 51003
	end

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_LC_Cart_Components
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
		begin
			set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			return 51007
		end
	end

	---------------------------------------------------
	-- Validate serial number (only applies to new entries)
	---------------------------------------------------
	--
	set @tmp = 0
	--
	if @mode = 'add'
	begin

		SELECT @tmp = ID
		FROM
			T_LC_Cart_Components
		WHERE
			Type = @typeID AND 
			Serial_Number = @SerialNumber
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error looking for duplicate serial numbers'
			RAISERROR (@message, 10, 1)
			return 51007
		end
		--
		if @tmp <> 0
		begin
			set @message = 'A component of type "' + @Type + '" already exists with the same serial number'
			RAISERROR (@message, 10, 1)
			return 51008
		end
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_LC_Cart_Components (
			Type, 
			Status, 
			Description, 
			Manufacturer, 
			Part_Number, 
			Serial_Number, 
			Property_Number,
			Comment
			) VALUES (
			@typeID, 
			@Status, 
			@Description, 
			@Manufacturer, 
			@PartNumber, 
			@SerialNumber,
			@PropertyNumber,
			@Comment
		)
		/**/
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
		  set @message = 'Insert operation failed'
		  RAISERROR (@message, 10, 1)
		  return 51007
		end

		-- return IDof newly created entry
		--
		set @ID = IDENT_CURRENT('T_LC_Cart_Components')
		
		if @PositionID != 0
		begin
			exec @myError = UpdateLCCartComponentPosition
								'replace',
								@PositionID,
								@ID, 
								'Component created',
								@message output,
   								@callingUser
			if @myError <> 0
			begin
			  set @message = 'Insert operation failed'
			  RAISERROR (@message, 10, 1)
			  return 51007
			end
		
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

	UPDATE T_LC_Cart_Components 
	SET 
	  Type = @typeID, 
	  Status = @Status, 
	  Description = @Description, 
	  Manufacturer = @Manufacturer, 
	  Part_Number = @PartNumber, 
	  Serial_Number = @SerialNumber,
	  Property_Number = @PropertyNumber, 
	  Comment = @Comment
	WHERE (ID = @ID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
	  set @message = 'Update operation failed: "' + @ID + '"'
	  RAISERROR (@message, 10, 1)
	  return 51004
	end
	end -- update mode

	return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartComponents] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartComponents] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartComponents] TO [PNL\D3M580] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[AddUpdateLCCart] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateLCCart
/****************************************************
**
**  Desc: Adds new or edits existing LC Cart
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 02/23/2006
**          03/03/2006 grk - fixed problem with duplicate entries
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @ID int output,
  @CartName varchar(128),
  @CartDescription varchar(1024),
  @CartState varchar(50),
  @mode varchar(12) = 'add', -- or 'update'
  @message varchar(512) output
As
  set nocount on

  declare @myError int
  set @myError = 0

  declare @myRowCount int
  set @myRowCount = 0
  
  set @message = ''


  ---------------------------------------------------
  -- Validate input fields
  ---------------------------------------------------

  -- future: this could get more complicated
  
  ---------------------------------------------------
  -- Resolve cart state name to ID
  ---------------------------------------------------
  --
  declare @CartStateID int
  set @CartStateID = 0
  --
  SELECT @CartStateID = ID
  FROM T_LC_Cart_State_Name
  WHERE  [Name] = @CartState
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to resolve state name to ID'
      RAISERROR (@message, 10, 1)
      return 51007
    end
    --
    if @CartStateID = 0
    begin
      set @message = 'Could not resolve state name to ID'
      RAISERROR (@message, 10, 1)
      return 51008
    end

  ---------------------------------------------------
  -- Verify whether entry exists or not
  ---------------------------------------------------
	declare @tmp int
	set @tmp = 0
	--
	SELECT @tmp = ID
		FROM  T_LC_Cart
	WHERE (ID = @ID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to find entry in database'
		RAISERROR (@message, 10, 1)
		return 51007
    end

  if @mode = 'update' and @tmp = 0
  begin
	set @message = 'Cannot update - Entry does not exist.'
	RAISERROR (@message, 10, 1)
	return 51007
  end

  if @Mode = 'add' and @tmp <> 0
  begin
	set @message = 'Cannot Add - Entry already exists'
	RAISERROR (@message, 10, 1)
	return 51007
  end

  ---------------------------------------------------
  -- action for add mode
  ---------------------------------------------------
  if @Mode = 'add'
  begin
 
  INSERT INTO T_LC_Cart (
    Cart_Name, 
    Cart_State_ID, 
    Cart_Description
  ) VALUES (
    @CartName, 
    @CartStateID, 
    @CartDescription
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
    set @ID = IDENT_CURRENT('T_LC_Cart')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_LC_Cart 
    SET 
      Cart_Name = @CartName, 
      Cart_State_ID = @CartStateID, 
      Cart_Description = @CartDescription
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
GRANT EXECUTE ON [dbo].[AddUpdateLCCart] TO [DMS_LC_Column_Admin]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCart] TO [DMS2_SP_User]
GO

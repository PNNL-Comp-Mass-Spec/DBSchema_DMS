/****** Object:  StoredProcedure [dbo].[AddUpdateLCCartVersion] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateLCCartVersion
/****************************************************
**
**  Desc: Adds new or edits existing LC Cart Version
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/03/2006
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @ID int,
  @CartName varchar(128),
  @EffectiveDate datetime,
  @Version varchar(50),
  @VersionNumber int,
  @Description varchar(1024),
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
  -- Resolve cart name to ID
  ---------------------------------------------------

	declare @CartID int
	set @CartID = 0
	--
	SELECT @CartID = ID
	FROM T_LC_Cart
	WHERE Cart_Name = @CartName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to resolve cart ID'
		RAISERROR (@message, 10, 1)
		return 51003
	end
	--
	if @CartID = 0
	begin
		set @message = 'Could not resolve cart name to ID'
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
     FROM  T_LC_Cart_Version
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
  -- action for add mode
  ---------------------------------------------------
  if @Mode = 'add'
  begin
	-- get current highest version number for cart
	declare @VersionNum int
	--
	SELECT @VersionNum = MAX(Version_Number)
	FROM T_LC_Cart_Version
	WHERE Cart_ID = @CartID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to get current highest cart version'
		RAISERROR (@message, 10, 1)
		return 51007
	end  
	
	set @VersionNum = @VersionNum + 1
 
	INSERT INTO T_LC_Cart_Version (
		Cart_ID, 
		Effective_Date, 
		Version, 
		Version_Number,
		Description
	) VALUES (
		@CartID, 
		@EffectiveDate, 
		@Version, 
		@VersionNum,
		@Description
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
	set @ID = IDENT_CURRENT('T_LC_Cart_Version')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_LC_Cart_Version 
    SET 
      Effective_Date = @EffectiveDate, 
      Version = @Version, 
      Description = @Description
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
GRANT EXECUTE ON [dbo].[AddUpdateLCCartVersion] TO [DMS_LC_Column_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartVersion] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartVersion] TO [PNL\D3M580] AS [dbo]
GO

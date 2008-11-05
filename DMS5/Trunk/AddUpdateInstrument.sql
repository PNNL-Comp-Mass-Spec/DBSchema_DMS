/****** Object:  StoredProcedure [dbo].[AddUpdateInstrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateInstrument
/****************************************************
**
**  Desc: Edits existing Instrument
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    06/07/2005 grk - Initial release
**	  10/15/2008 grk - Allowed for null Usage
**    
*****************************************************/
  @InstrumentID int Output,
  @InstrumentName varchar(24),
  @InstrumentClass varchar(32),
  @CaptureMethod varchar(10),
  @Status varchar(8),
  @RoomNumber varchar(50),
  @Description varchar(50),
  @Usage varchar(50),
  @OperationsRole varchar(50),
  @mode varchar(12) = 'update', -- 'add' is presently disabled
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
  
  if @Usage is null
	set @Usage = ''

  -- future: this could get more complicated
  

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
  SELECT @tmp = Instrument_ID
     FROM  T_Instrument_Name
    WHERE (IN_name = @InstrumentName)
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
	set @message = 'This mode is disabled'
	return 1
 
  INSERT INTO T_Instrument_Name (
    IN_name, 
    IN_class, 
    IN_capture_method, 
    IN_status, 
    IN_Room_Number, 
    IN_Description, 
    IN_usage, 
    IN_operations_role
   ) VALUES (
    @InstrumentName, 
    @InstrumentClass, 
    @CaptureMethod, 
    @Status, 
    @RoomNumber, 
    @Description, 
    @Usage, 
    @OperationsRole
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
    set @InstrumentID = IDENT_CURRENT('T_Instrument_Name')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_Instrument_Name 
    SET 
      IN_name = @InstrumentName, 
      Instrument_ID = @InstrumentID, 
      IN_class = @InstrumentClass, 
      IN_capture_method = @CaptureMethod, 
      IN_status = @Status, 
      IN_Room_Number = @RoomNumber, 
      IN_Description = @Description, 
      IN_usage = @Usage, 
      IN_operations_role = @OperationsRole
   WHERE (Instrument_ID = @InstrumentID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Update operation failed: "' + @InstrumentID + '"'
      RAISERROR (@message, 10, 1)
      return 51004
    end
  end -- update mode

  return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS_Instrument_Admin]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS2_SP_User]
GO

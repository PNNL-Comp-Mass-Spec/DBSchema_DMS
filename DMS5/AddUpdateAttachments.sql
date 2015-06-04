/****** Object:  StoredProcedure [dbo].[AddUpdateAttachments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateAttachments
/****************************************************
**
**  Desc: Adds new or edits existing Attachments
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/24/2009
**    Date: 07/22/2010 grk -- allowed update mode
**			06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
  @ID int output,
  @AttachmentType varchar(24),
  @AttachmentName varchar(128),
  @AttachmentDescription varchar(1024),
  @OwnerPRN varchar(24),
  @Active varchar(8),
  @Contents text,
  @FileName varchar(128),
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

--set @myError = 7
--set @message = convert(varchar(128), @Contents);
--set @message = @FileName;
--set @mode = 'add'
  ---------------------------------------------------
  -- Validate input fields
  ---------------------------------------------------

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
  SELECT @tmp = ID
     FROM  T_Attachments
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
 
  INSERT INTO T_Attachments (
    Attachment_Type, 
    Attachment_Name, 
    Attachment_Description, 
    Owner_PRN, 
    Active, 
    Contents, 
    File_Name
  ) VALUES (
    @AttachmentType, 
    @AttachmentName, 
    @AttachmentDescription, 
    @OwnerPRN, 
    @Active, 
    @Contents, 
    @FileName
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
    
    -- return ID of newly created entry
    --
    set @ID = SCOPE_IDENTITY()

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_Attachments 
    SET 
      Attachment_Type = @AttachmentType, 
      Attachment_Name = @AttachmentName, 
      Attachment_Description = @AttachmentDescription, 
      Owner_PRN = @OwnerPRN, 
      Active = @Active, 
      Contents = @Contents, 
      File_Name = @FileName
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
GRANT EXECUTE ON [dbo].[AddUpdateAttachments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAttachments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAttachments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAttachments] TO [PNL\D3M580] AS [dbo]
GO

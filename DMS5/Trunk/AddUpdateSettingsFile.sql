/****** Object:  StoredProcedure [dbo].[AddUpdateSettingsFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateSettingsFile
/****************************************************
**
**  Desc: Adds new or edits existing entity in T_Settings_Files table
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 08/22/2008
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
	@ID int,
	@AnalysisTool varchar(64),
	@FileName varchar(255),
	@Description varchar(1024),
	@Active tinyint,
	@Contents text,
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

	declare @xmlContents xml
	set @xmlContents = @Contents
	
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
	 FROM  T_Settings_Files
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

	INSERT INTO T_Settings_Files (
	Analysis_Tool, 
	File_Name, 
	Description, 
	Active, 
	Contents
	) VALUES (
	@AnalysisTool, 
	@FileName, 
	@Description, 
	@Active, 
	@xmlContents
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
	set @ID = IDENT_CURRENT('T_Settings_Files')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
	set @myError = 0
	--

	UPDATE T_Settings_Files 
	SET 
	  Analysis_Tool = @AnalysisTool, 
	  File_Name = @FileName, 
	  Description = @Description, 
	  Active = @Active, 
	  Contents = @xmlContents
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
GRANT EXECUTE ON [dbo].[AddUpdateSettingsFile] TO [DMS2_SP_User]
GO

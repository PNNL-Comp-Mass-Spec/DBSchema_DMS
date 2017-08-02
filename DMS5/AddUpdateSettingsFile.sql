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
**  Auth:	grk
**  Date:	08/22/2008
**			03/30/2015 mem - Added parameters @HMSAutoSupersede and @MSGFPlusAutoCentroid
**			03/21/2016 mem - Update column Last_Updated
**			06/13/2017 mem - Use SCOPE_IDENTITY()
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
	@ID int,
	@AnalysisTool varchar(64),
	@FileName varchar(255),
	@Description varchar(1024),
	@Active tinyint,
	@Contents text,
	@HMSAutoSupersede varchar(255) = '',
	@MSGFPlusAutoCentroid varchar(255) = '',
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	declare @xmlContents xml
	set @xmlContents = @Contents

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateSettingsFile', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @AnalysisTool = LTrim(RTrim(IsNull(@AnalysisTool, '')))
	Set @FileName = LTrim(RTrim(IsNull(@FileName, '')))
	Set @HMSAutoSupersede = LTrim(RTrim(IsNull(@HMSAutoSupersede, '')))
	Set @MSGFPlusAutoCentroid = LTrim(RTrim(IsNull(@MSGFPlusAutoCentroid, '')))
	
	If @AnalysisTool = ''
	Begin
		set @message = 'Analysis Tool cannot be empty'
		RAISERROR (@message, 10, 1)
		return 51006
	End
	
	If @FileName = ''
	Begin
		set @message = 'Filename cannot be empty'
		RAISERROR (@message, 10, 1)
		return 51006
	End
	
	
	If Len(@HMSAutoSupersede) > 0
	Begin
		If @HMSAutoSupersede = @FileName
		Begin
			set @message = 'The HMS_AutoSupersede file cannot have the same name as this settings file'
			RAISERROR (@message, 10, 1)
			return 51006
		End
	
		If Not Exists (SELECT * FROM T_Settings_Files WHERE File_name = @HMSAutoSupersede)
		Begin
			set @message = 'HMS_AutoSupersede settings file not found in the database: ' + @HMSAutoSupersede
			RAISERROR (@message, 10, 1)
			return 51006
		End
		
		Declare @AnalysisToolForAutoSupersede varchar(64) = ''
		
		SELECT @AnalysisToolForAutoSupersede = Analysis_Tool
		FROM T_Settings_Files
		WHERE File_name = @HMSAutoSupersede
	
		If @AnalysisToolForAutoSupersede <> @AnalysisTool
		Begin
			set @message = 'The Analysis Tool for the HMS_AutoSupersede file ("' + @HMSAutoSupersede + '") must match the analysis tool for this settings file: ' + @AnalysisToolForAutoSupersede + ' vs. ' + @AnalysisTool
			RAISERROR (@message, 10, 1)
			return 51006
		End
		
	End
	Else
	Begin
		Set @HMSAutoSupersede = null
	End
	
	
	If Len(@MSGFPlusAutoCentroid) > 0
	Begin
		If @MSGFPlusAutoCentroid = @FileName
		Begin
			set @message = 'The MSGFPlus_AutoCentroid file cannot have the same name as this settings file'
			RAISERROR (@message, 10, 1)
			return 51006
		End

		If Not Exists (SELECT * FROM T_Settings_Files WHERE File_name = @MSGFPlusAutoCentroid)
		Begin
			set @message = 'MSGFPlus AutoCentroid settings file not found in the database: ' + @MSGFPlusAutoCentroid
			RAISERROR (@message, 10, 1)
			return 51006
		End
	
		Declare @AnalysisToolForAutoCentroid varchar(64) = ''
		
		SELECT @AnalysisToolForAutoCentroid = Analysis_Tool
		FROM T_Settings_Files
		WHERE File_name = @MSGFPlusAutoCentroid
	
		If @AnalysisToolForAutoCentroid <> @AnalysisTool
		Begin
			set @message = 'The Analysis Tool for the MSGFPlus_AutoCentroid file ("' + @MSGFPlusAutoCentroid + '") must match the analysis tool for this settings file: ' + @AnalysisToolForAutoCentroid + ' vs. ' + @AnalysisTool
			RAISERROR (@message, 10, 1)
			return 51006
		End
		
	End
	Else
	Begin
		Set @MSGFPlusAutoCentroid = null
	End
		
	
	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------
	--	
	If @mode = 'update'
	Begin
		-- cannot update a non-existent entry
		--
		declare @tmp int = 0
		--
		SELECT @tmp = ID
		FROM T_Settings_Files
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0 OR @tmp = 0
		Begin
			set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			return 51007
		End

	End


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	If @Mode = 'add'
	Begin

		INSERT INTO T_Settings_Files(
			Analysis_Tool,
			File_Name,
			Description,
			Active,
			Contents,
			HMS_AutoSupersede,
			MSGFPlus_AutoCentroid 
		) VALUES (
			@AnalysisTool, 
			@FileName, 
			@Description, 
			@Active, 
			@xmlContents, 
			@HMSAutoSupersede,
			@MSGFPlusAutoCentroid
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		End

		-- Return ID of newly created entry
		--
		set @ID = SCOPE_IDENTITY()

	End -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	If @Mode = 'update' 
	Begin
		set @myError = 0
		--

		UPDATE T_Settings_Files
		SET Analysis_Tool = @AnalysisTool,
		    File_Name = @FileName,
		    Description = @Description,
		    Active = @Active,
		    Contents = @xmlContents,
		    HMS_AutoSupersede = @HMSAutoSupersede,
		    MSGFPlus_AutoCentroid = @MSGFPlusAutoCentroid,
		    Last_Updated = GetDate()
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		End
	End -- update mode

	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSettingsFile] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateSettingsFile] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSettingsFile] TO [Limited_Table_Write] AS [dbo]
GO

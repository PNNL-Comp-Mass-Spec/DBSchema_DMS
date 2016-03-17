/****** Object:  StoredProcedure [dbo].[CreatePSMJobRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure CreatePSMJobRequest
/****************************************************
**
**	Desc: Creates a new analysis job request using the appropriate
**		  parameter file and settings file for the specified settings
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	11/14/2012 mem - Initial version
**			11/21/2012 mem - No longer passing work package to AddUpdateAnalysisJobRequest
**			               - Now calling PostUsageLogEntry
**			12/13/2012 mem - Added parameter @previewMode, which indicates what should be passed to AddUpdateAnalysisJobRequest for @mode
**			01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**			03/05/2013 mem - Now passing @AutoRemoveNotReleasedDatasets to ValidateAnalysisJobRequestDatasets
**			04/09/2013 mem - Now automatically updating the settings file to the MSConvert equivalent if processing QExactive data
**			03/30/2015 mem - Now passing @toolName to AutoUpdateSettingsFileToCentroid
**						   - Now using T_Dataset_Info.ProfileScanCount_MSn to look for datasets with profile-mode MS/MS spectra
**			04/23/2015 mem - Now passing @toolName to ValidateAnalysisJobRequestDatasets
**    
*****************************************************/
(
	@requestID int output,
	@requestName varchar(128),
    @datasets varchar(max) output,				-- Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
    @toolName varchar(64),
    @jobTypeName varchar(64),
	@protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
    @DynMetOxEnabled tinyint,    
    @StatCysAlkEnabled tinyint,
    @DynSTYPhosEnabled tinyint,
	@comment varchar(512),
	@ownerPRN varchar(64),
	@previewMode tinyint = 0,
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set NoCount On

	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @result int
	
	Declare @SettingsFile varchar(255)
	Declare @ParamFile varchar(255)
	Declare @msg varchar(255)
	
	Declare @DatasetCount int = 0
	
	BEGIN TRY 

		---------------------------------------------------
		-- Validate the inputs
		---------------------------------------------------
	
		Set @requestID = 0
		Set @toolName = IsNull(@toolName, '')
		
		Set @requestName = IsNull(@requestName, 'New ' + @toolName + ' request on ' + CONVERT(varchar(32), GetDate()))
		Set @datasets = IsNull(@datasets, '')		
		Set @jobTypeName = IsNull(@jobTypeName, '')
		Set @protCollNameList = IsNull(@protCollNameList, '')
		Set @protCollOptionsList = IsNull(@protCollOptionsList, '')
				
		Set @DynMetOxEnabled = IsNull(@DynMetOxEnabled, 0)
		Set @StatCysAlkEnabled = IsNull(@StatCysAlkEnabled, 0)
		Set @DynSTYPhosEnabled = IsNull(@DynSTYPhosEnabled, 0)
		
		Set @comment = IsNull(@comment, '')
		Set @ownerPRN = IsNull(@ownerPRN, SUSER_SNAME())
		set @previewMode = IsNull(@previewMode, 0)
		Set @message = ''
		Set @callingUser = IsNull(@callingUser, '')

		---------------------------------------------------
		-- Assure that key parameters are not empty
		---------------------------------------------------
		--
		If IsNull(@datasets, '') = ''
			RAISERROR ('Dataset list is empty', 11, 10)

		If IsNull(@toolName, '') = ''
			RAISERROR ('Tool name is empty', 11, 10)
			
		If IsNull(@jobTypeName, '') = ''
			RAISERROR ('Job Type Name is empty', 11, 10)
			
		If IsNull(@protCollNameList, '') = ''
			RAISERROR ('Protein collection list is empty', 11, 10)
		
		---------------------------------------------------
		-- Assure that @jobTypeName, @toolName, and @requestName are valid
		---------------------------------------------------
		--
		If Not Exists (SELECT * FROM T_Default_PSM_Job_Types WHERE Job_Type_Name = @jobTypeName)
			RAISERROR ('Invalid job type name: %s', 11, 10, @jobTypeName)
		
		If Not Exists (SELECT * FROM T_Default_PSM_Job_Settings Where Tool_Name = @toolName)
			RAISERROR ('Invalid analysis tool for creating a defaults-based PSM job: %s', 11, 10, @toolName)
			
		If Exists (SELECT * FROM T_Analysis_Job_Request WHERE AJR_requestName = @requestName)
			RAISERROR ('Cannot add; analysis job request named "%s" already exists', 11, 4, @requestName)

		If @toolName Like '%_DTARefinery' And @jobTypeName = 'Low Res MS1'
			RAISERROR ('DTARefinery cannot be used with datasets that have low resolution MS1 spectra', 11, 4)
	
		---------------------------------------------------
		-- Create temporary table to hold list of datasets
		---------------------------------------------------

		CREATE TABLE #TD (
			Dataset_Num varchar(128),
			Dataset_ID int NULL,
			IN_class varchar(64) NULL, 
			DS_state_ID int NULL, 
			AS_state_ID int NULL,
			Dataset_Type varchar(64) NULL,
			DS_rating smallint NULL
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
			RAISERROR ('Failed to create temporary table', 11, 10)

		CREATE INDEX #IX_TD_DatasetID ON #TD (Dataset_ID)
		
		---------------------------------------------------
		-- Populate #TD using the dataset list
		-- Remove any duplicates that may be present
		---------------------------------------------------
		--
		INSERT INTO #TD ( Dataset_Num )
		SELECT DISTINCT Item
		FROM MakeTableFromList ( @datasets )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			RAISERROR ('Error populating temporary table #TD', 11, 10)
		End

		Set @DatasetCount = @myRowCount

		---------------------------------------------------
		-- Validate the datasets in #TD
		---------------------------------------------------
		
		exec @result = ValidateAnalysisJobRequestDatasets @message output, @AutoRemoveNotReleasedDatasets=1, @toolName=@toolName
		
		If @result <> 0
			RAISERROR (@message, 11, 10)
	
		---------------------------------------------------
		-- Regenerate the dataset list, sorting by dataset name
		---------------------------------------------------
		--
		Set @datasets = ''
		
		SELECT @datasets = @datasets + Dataset_Num + ', '
		FROM #TD
		ORDER BY Dataset_Num
			
		-- Remove the trailing comma
		If Len(@datasets) > 0
		Set @datasets = SubString(@datasets, 1, Len(@datasets)-1)
	
	
		---------------------------------------------------
		-- Determine the appropriate parameter file and settings file given @toolName and @jobTypeName
		---------------------------------------------------
		
		-- First determine the settings file
		--		
		SELECT @SettingsFile = Settings_File_Name
		FROM T_Default_PSM_Job_Settings
		WHERE Tool_Name = @toolName AND
		      Job_Type_Name = @jobTypeName AND
		      StatCysAlk = @StatCysAlkEnabled AND
		      DynSTYPhos = @DynSTYPhosEnabled

		If IsNull(@SettingsFile, '') = ''
		Begin
			Set @msg = 'Tool ' + @toolName + ' and job type ' + @jobTypeName + ' do not have a default settings file defined with ' + 
			           'Stat Cys Alk ' + dbo.TinyintToEnabledDisabled(@StatCysAlkEnabled) + ' and ' +
			           'Dyn STY Phos ' + dbo.TinyintToEnabledDisabled(@DynSTYPhosEnabled)
			           
			RAISERROR (@msg, 11, 10)
		End
		
		Declare @QExactiveDSCount int = 0
		Declare @ProfileModeMSnDatasets int = 0
		
		-- Count the number of QExactive datasets
		--
		SELECT @QExactiveDSCount = COUNT(*)
		FROM #TD
		     INNER JOIN T_Dataset DS ON #TD.Dataset_Num = DS.Dataset_Num
		     INNER JOIN T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
		     INNER JOIN T_Instrument_Group InstGroup ON InstName.IN_Group = InstGroup.IN_Group
		WHERE (InstGroup.IN_Group = 'QExactive')

		-- Count the number of datasets with profile mode MS/MS
		--
		SELECT @ProfileModeMSnDatasets = Count(Distinct DS.Dataset_ID)
		FROM #TD
		     INNER JOIN T_Dataset DS ON #TD.Dataset_Num = DS.Dataset_Num
		     INNER JOIN T_Dataset_Info DI ON DS.Dataset_ID = DI.Dataset_ID
		WHERE DI.ProfileScanCount_MSn > 0
	
		If @QExactiveDSCount > 0 Or @ProfileModeMSnDatasets > 0
		Begin
			-- Auto-update the settings file since we have one or more Q Exactive datasets or one or more datasets with profile-mode MS/MS spectra
			Set @SettingsFile = dbo.AutoUpdateSettingsFileToCentroid(@SettingsFile, @toolName)
		End
			
		
		-- Next determine the parameter file
		-- 
		SELECT @ParamFile = Parameter_File_Name
		FROM T_Default_PSM_Job_Parameters
		WHERE Job_Type_Name = @jobTypeName AND
		 Tool_Name = @toolName AND
		      DynMetOx = @DynMetOxEnabled AND
		      StatCysAlk = @StatCysAlkEnabled AND
		      DynSTYPhos = @DynSTYPhosEnabled

		If IsNull(@ParamFile, '') = '' And @toolName Like '%_DTARefinery'
		Begin
			-- Remove '_DTARefinery' from the end of @toolName and re-query T_Default_PSM_Job_Parameters
			
			SELECT @ParamFile = Parameter_File_Name
			FROM T_Default_PSM_Job_Parameters
			WHERE Job_Type_Name = @jobTypeName AND
				Tool_Name = Replace(@toolName, '_DTARefinery', '') AND
				DynMetOx = @DynMetOxEnabled AND
				StatCysAlk = @StatCysAlkEnabled AND
				DynSTYPhos = @DynSTYPhosEnabled

		End
		

		If IsNull(@ParamFile, '') = ''
		Begin
			Set @msg = 'Tool ' + @toolName + ' and job type ' + @jobTypeName + ' do not have a default parameter file defined with ' + 
			            'Dyn Met Ox ' +   dbo.TinyintToEnabledDisabled(@DynMetOxEnabled) + ', ' + 
			            'Stat Cys Alk ' + dbo.TinyintToEnabledDisabled(@StatCysAlkEnabled) + ', and ' + 
			            'Dyn STY Phos ' + dbo.TinyintToEnabledDisabled(@DynSTYPhosEnabled)
			            
			RAISERROR (@msg, 11, 10)
		End
		
		---------------------------------------------------
		-- Lookup the most common organism for the datasets in #TD
		---------------------------------------------------
		--
		Declare @organismName varchar(128) = ''
		
		SELECT TOP 1 @organismName = T_Organisms.OG_name
		FROM #TD
		     INNER JOIN T_Dataset DS
		       ON #TD.Dataset_ID = DS.Dataset_ID
		     INNER JOIN T_Experiments E
		       ON DS.Exp_ID = E.Exp_ID
		     INNER JOIN T_Organisms
		     ON E.EX_organism_ID = T_Organisms.Organism_ID
		GROUP BY T_Organisms.OG_name
		ORDER BY COUNT(*) DESC
	
		---------------------------------------------------
		-- Automatically switch from decoy to forward if using MSGFPlus
		-- AddUpdateAnalysisJobRequest also does this, but it displays a warning message to the user
		-- We don't want the warning message to appear when the user is using CreatePSMJobRequest; instead we silently update things
		---------------------------------------------------
		--
		If @toolName LIKE 'MSGFPlus%' And @protCollOptionsList Like '%decoy%' And @ParamFile Not Like '%[_]NoDecoy%'
		Begin
			Set @protCollOptionsList = 'seq_direction=forward,filetype=fasta'
		End
		
		Declare @mode varchar(12) = 'add'
		If @previewMode <> 0
			Set @mode = 'PreviewAdd'

		---------------------------------------------------
		-- Now create the analysis job request
		---------------------------------------------------
		--
		exec @myError = AddUpdateAnalysisJobRequest @datasets = @datasets,
				@requestName = @requestName,
				@toolName = @toolName,
				@parmFileName = @ParamFile,
				@settingsFileName = @SettingsFile,
				@protCollNameList = @protCollNameList,
				@protCollOptionsList = @protCollOptionsList,
				@organismName = @organismName,
				@organismDBName = 'na',					-- Legacy fasta file
				@requestorPRN = @ownerPRN,
				@comment = @comment,
				@specialProcessing = null,
				@adminReviewReqd = 'No',
				@state = 'New',
				@requestID = @requestID output,
				@mode = @mode,
				@message = @message output
		
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	If @requestID > 0
	Begin
		Declare @UsageMessage varchar(512)
		Set @UsageMessage = 'Created job request ' + Convert(varchar(12), @requestID) + ' for ' + Convert(varchar(12), @DatasetCount) + ' dataset'
		If @DatasetCount <> 1
			Set @UsageMessage = @UsageMessage + 's'
		
		Set @UsageMessage = @UsageMessage + '; user ' + @callingUser
		
		Exec PostUsageLogEntry 'CreatePSMJobRequest', @UsageMessage, @MinimumUpdateInterval=2
	End
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CreatePSMJobRequest] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreatePSMJobRequest] TO [PNL\D3M580] AS [dbo]
GO

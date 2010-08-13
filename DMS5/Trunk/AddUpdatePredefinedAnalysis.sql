/****** Object:  StoredProcedure [dbo].[AddUpdatePredefinedAnalysis] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdatePredefinedAnalysis
/****************************************************
** 
**	Desc: Adds a new default analysis to DB 
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	grk
**	Date:	06/21/2005 grk - superseded AddUpdateDefaultAnalysis
**			03/28/2006 grk - added protein collection fields
**			01/26/2007 mem - Switched to organism ID instead of organism name (Ticket #368)
**			07/30/2007 mem - Now validating dataset type and instrument class for the matching instruments against the specified analysis tool (Ticket #502)
**			08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**			09/04/2009 mem - Added DatasetType parameter
**			09/16/2009 mem - Now checking dataset type against T_Instrument_Allowed_Dataset_Type (Ticket #748)
**			10/05/2009 mem - Now validating the parameter file name
**			12/18/2009 mem - Switched to use GetInstrumentDatasetTypeList() to get the allowed dataset types for the dataset and GetAnalysisToolAllowedDSTypeList() to get the allowed dataset types for the analysis tool
**			05/06/2010 mem - Now calling AutoResolveNameToPRN to validate @creator
**    
*****************************************************/
(
	@level int,
	@sequence varchar(12),
	@instrumentClassCriteria varchar(32),
	@campaignNameCriteria varchar(128),
	@experimentNameCriteria varchar(128),
	@instrumentNameCriteria varchar(64),
	@organismNameCriteria varchar(64),
	@datasetNameCriteria varchar(128),
	@expCommentCriteria varchar(128),
	@labellingInclCriteria varchar(64),
	@labellingExclCriteria varchar(64),
	@analysisToolName varchar(64),
	@parmFileName varchar(255),
	@settingsFileName varchar(255),
	@organismName varchar(64),
	@organismDBName varchar(64),
	@protCollNameList varchar(512),
	@protCollOptionsList varchar(256),
	@priority int,
	@enabled tinyint,
	@description varchar(255),
	@creator varchar(50),
	@nextLevel varchar(12),
	@ID int output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@separationTypeCriteria varchar(64)='',
	@campaignExclCriteria varchar(128)='',
	@experimentExclCriteria varchar(128)='',
	@datasetExclCriteria varchar(128)='',
	@datasetTypeCriteria varchar(64)=''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @allowedDatasetTypes varchar(255)
	declare @AllowedDSTypesForTool varchar(1024)
	declare @AllowedInstClassesForTool varchar(1024)
	
	declare @UniqueID int
	declare @continue int
	declare @MatchCount int
	declare @instrumentName varchar(128)
	declare @InstrumentID int
	declare @instrumentClass varchar(128)
	declare @analysisToolID int
	
	declare @msg varchar(512)
	set @msg = ''

	set @message = ''

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(IsNull(@analysisToolName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Analysis tool name was blank',
			10, 1)
	end
	
	if LEN(IsNull(@parmFileName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Parameter file name was blank',
			10, 1)
	end

	if LEN(IsNull(@settingsFileName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Settings file name was blank',
			10, 1)
	end

	if LEN(IsNull(@organismName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Organism name was blank; use "(default)" to auto-assign at job creation',
			10, 1)
	end

	if LEN(IsNull(@organismDBName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Organism DB name was blank',
			10, 1)
	end

	If @myError <> 0
		Goto Done
		
	---------------------------------------------------
	-- Update any null filter criteria
	---------------------------------------------------
	Set @instrumentClassCriteria = LTrim(RTrim(IsNull(@instrumentClassCriteria, '')))
	Set @campaignNameCriteria    = LTrim(RTrim(IsNull(@campaignNameCriteria   , '')))
	Set @experimentNameCriteria  = LTrim(RTrim(IsNull(@experimentNameCriteria , '')))
	Set @instrumentNameCriteria  = LTrim(RTrim(IsNull(@instrumentNameCriteria , '')))
	Set @organismNameCriteria    = LTrim(RTrim(IsNull(@organismNameCriteria   , '')))
	Set @datasetNameCriteria = LTrim(RTrim(IsNull(@datasetNameCriteria    , '')))
	Set @expCommentCriteria      = LTrim(RTrim(IsNull(@expCommentCriteria     , '')))
	Set @labellingInclCriteria   = LTrim(RTrim(IsNull(@labellingInclCriteria  , '')))
	Set @labellingExclCriteria   = LTrim(RTrim(IsNull(@labellingExclCriteria  , '')))
	Set @separationTypeCriteria  = LTrim(RTrim(IsNull(@separationTypeCriteria , '')))
	Set @campaignExclCriteria    = LTrim(RTrim(IsNull(@campaignExclCriteria   , '')))
	Set @experimentExclCriteria  = LTrim(RTrim(IsNull(@experimentExclCriteria , '')))
	Set @datasetExclCriteria     = LTrim(RTrim(IsNull(@datasetExclCriteria    , '')))
	Set @datasetTypeCriteria     = LTrim(RTrim(IsNull(@datasetTypeCriteria    , '')))


	---------------------------------------------------
	-- Validate @sequence and @nextLevel
	---------------------------------------------------

	declare @seqVal int
	declare @nextLevelVal int

	if @sequence <> ''
	set @seqVal = convert(int, @sequence)

	if @nextLevel <> ''
	begin
	set @nextLevelVal = convert(int, @nextLevel)
	if @nextLevelVal <= @level 
		begin
			set @msg = 'Next level must be greater than current level'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end

	--------------------------------------------------
	-- Validate the analysis tool name and lookup the allowed
	-- dataset types and instrument classes
	--------------------------------------------------
	
	Set @AllowedInstClassesForTool = ''
	
	SELECT @AllowedInstClassesForTool = IsNull(AJT_allowedInstClass, ''),
	       @analysisToolID = AJT_toolID
	FROM dbo.T_Analysis_Tool
	WHERE (AJT_toolName = @analysisToolName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		Set @msg = 'Analysis tool "' + @analysisToolName + '" not found in T_Analysis_Tool'
		RAISERROR (@msg, 10, 1)
		return 51008
	End

	---------------------------------------------------
	-- If @instrumentClassCriteria and/or @instrumentNameCriteria are defined 
	-- then determine the associated Dataset Types and make sure they are 
	-- valid for @analysisToolName
	---------------------------------------------------
	
	If Len(@instrumentClassCriteria) > 0 Or Len(@instrumentNameCriteria) > 0
	Begin -- <a>
		
		---------------------------------------------------
		-- Parse out the dataset types and instrument classes for the specified analysis tool
		---------------------------------------------------
		
		CREATE TABLE #TmpAllowedInstClassesForTool (
			InstrumentClass varchar(64)
		)
		
		If Not Exists (
			SELECT ADT.Dataset_Type
			FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
			     INNER JOIN T_Analysis_Tool Tool
			       ON ADT.Analysis_Tool_ID = Tool.AJT_toolID
			WHERE (Tool.AJT_toolName = @analysisToolName)
			)
		Begin
			Set @msg = 'Analysis tool "' + @analysisToolName + '" does not have any allowed dataset types; unable to continue'
			RAISERROR (@msg, 10, 1)
			return 51009
		End
		
		INSERT INTO #TmpAllowedInstClassesForTool (InstrumentClass)
		SELECT item 
		FROM MakeTableFromList(@AllowedInstClassesForTool)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
		Begin
			Set @msg = 'Analysis tool "' + @analysisToolName + '" does not have any allowed instrument classes; unable to continue'
			RAISERROR (@msg, 10, 1)
			return 51010
		End
		
		---------------------------------------------------
		-- Populate a temporary table with allowed dataset types
		-- associated with the matching instruments
		---------------------------------------------------
		
		CREATE TABLE #TmpMatchingInstruments (
			UniqueID int Identity(1,1),
			InstrumentName varchar(128),
			InstrumentClass varchar(128),
			InstrumentID int
		)
		
		INSERT INTO #TmpMatchingInstruments( InstrumentName,
		                                     InstrumentClass,
		                                     InstrumentID )
		SELECT DISTINCT InstName.IN_Name,
		                InstClass.IN_class,
		                InstName.Instrument_ID
		FROM T_Instrument_Name InstName
		     INNER JOIN T_Instrument_Class InstClass
		       ON InstName.IN_class = InstClass.IN_class
		WHERE (InstClass.IN_Class LIKE @instrumentClassCriteria OR @instrumentClassCriteria = '') AND
		      (InstName.IN_name LIKE @instrumentNameCriteria OR @instrumentNameCriteria = '')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
		Begin -- <b1>
			set @msg = 'Did not match any instruments using the instrument name and class criteria; update not allowed'
			RAISERROR (@msg, 10, 1)
			return 51011
		End -- </b1>


		---------------------------------------------------
		-- Step through #TmpMatchingInstruments and make sure
		--  each entry has at least one Dataset Type that is present in T_Analysis_Tool_Allowed_Dataset_Type
		--  for this analysis tool
		-- Also validate each instrument class with #TmpAllowedInstClassesForTool
		---------------------------------------------------

		Set @UniqueID = 0
		Set @continue = 1
		While @continue = 1
		Begin -- <b2>
			SELECT TOP 1 @UniqueID = UniqueID,
					@instrumentName = InstrumentName,
					@InstrumentID = InstrumentID,
					@instrumentClass = InstrumentClass
			FROM #TmpMatchingInstruments
			WHERE UniqueID > @UniqueID
			ORDER BY UniqueID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount = 0
				Set @continue = 0
			Else
			Begin -- <c>

				If Not Exists (
					SELECT *
					FROM T_Instrument_Allowed_Dataset_Type IADT
					     INNER JOIN ( SELECT ADT.Dataset_Type
					                  FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
					                       INNER JOIN T_Analysis_Tool Tool
					                         ON ADT.Analysis_Tool_ID = Tool.AJT_toolID
					                  WHERE (Tool.AJT_toolName = @analysisToolName) ) ToolQ
					       ON ToolQ.Dataset_Type = IADT.Dataset_Type
					WHERE IADT.Instrument = @instrumentName
					)
				Begin -- <d1>
					-- Example criteria that will result in this message: Instrument Criteria=Agilent_TOF%, Tool=AgilentSequest
					
					Set @allowedDatasetTypes = dbo.GetInstrumentDatasetTypeList(@InstrumentID)
					
					SELECT @AllowedDSTypesForTool = AllowedDatasetTypes
					FROM dbo.GetAnalysisToolAllowedDSTypeList(@analysisToolID)

					set @msg = 'Criteria matched instrument "' + @instrumentName + '" with allowed dataset types of "' + @allowedDatasetTypes + '"'
					set @msg = @msg + '; however, analysis tool ' + @analysisToolName + ' only allows "' + @AllowedDSTypesForTool + '"'
					RAISERROR (@msg, 10, 1)
					return 51012
				End	 -- </d1>			

				Set @MatchCount = 0
				SELECT @MatchCount = COUNT(*)
				FROM #TmpAllowedInstClassesForTool
				WHERE InstrumentClass = @instrumentClass
				
				If @MatchCount = 0
				Begin -- <d2>
					-- Example criteria that will result in this message: Instrument Class=BRUKERFTMS, Tool=XTandem
					-- 2nd example: Instrument Criteria=Agilent_TOF%, Tool=Decon2LS
					set @msg = 'Criteria matched instrument "' + @instrumentName + '" which is Instrument Class "' + @instrumentClass + '"'
					set @msg = @msg + '; however, analysis tool ' + @analysisToolName + ' is not valid for that instrument class'
					RAISERROR (@msg, 10, 1)
					return 51013
				End	 -- </d2>		
				
			End -- </c>
		End -- </b2>
		
	End -- </a>

	
	---------------------------------------------------
	-- Resolve organism ID
	---------------------------------------------------

	declare @organismID int
	execute @organismID = GetOrganismID @organismName
	if @organismID = 0
	begin
		set @msg = 'Could not find entry in database for organismName "' + @organismName + '"'
		RAISERROR (@msg, 10, 1)
		return 51014
	end

	---------------------------------------------------
	-- Validate the parameter file name
	---------------------------------------------------
	If @parmFileName <> 'na'
	Begin
		If Not Exists (SELECT * FROM T_Param_Files WHERE Param_File_Name = @parmFileName)
		Begin
			set @msg = 'Could not find entry in database for parameter file "' + @parmFileName + '"'
			RAISERROR (@msg, 10, 1)
			return 51018
		End
	End
	
	---------------------------------------------------
	-- @creator should be a userPRN
	-- Auto-capitalize it or auto-resolve it from a name to a PRN
	---------------------------------------------------

	Declare @userID int
	
	execute @userID = GetUserID @creator
	if @userID = 0
	begin
		---------------------------------------------------
		-- @creator did not resolve to a User_ID
		-- In case a name was entered (instead of a PRN),
		--  try to auto-resolve using the U_Name column in T_Users
		---------------------------------------------------
		Declare @NewPRN varchar(64)

		exec AutoResolveNameToPRN @creator, @MatchCount output, @NewPRN output, @userID output
					
		If @MatchCount = 1
		Begin
			-- Single match was found; update @creator
			Set @creator = @NewPRN
		End
	end
	Else
	Begin
		-- Make sure U_Prn is capitalized
		SELECT @creator = U_PRN 
		FROM T_Users WHERE ID = @userID 
	End
	
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
	SELECT @tmp = AD_ID
		FROM  T_Predefined_Analysis
	WHERE (AD_ID = @ID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 OR @tmp = 0
	begin
		set @msg = 'No entry could be found in database for update'
		RAISERROR (@msg, 10, 1)
		return 51015
	end

	end
	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Predefined_Analysis (
			AD_level,
			AD_sequence, 
			AD_instrumentClassCriteria, 
			AD_campaignNameCriteria, 
			AD_campaignExclCriteria, 
			AD_experimentNameCriteria, 
			AD_experimentExclCriteria, 
			AD_instrumentNameCriteria, 
			AD_organismNameCriteria, 
			AD_datasetNameCriteria, 
			AD_datasetExclCriteria,
			AD_datasetTypeCriteria,
			AD_expCommentCriteria, 
			AD_labellingInclCriteria, 
			AD_labellingExclCriteria, 
			AD_separationTypeCriteria, 
			AD_analysisToolName, 
			AD_parmFileName, 
			AD_settingsFileName, 
			AD_organism_ID, 
			AD_organismDBName, 
			AD_proteinCollectionList,
			AD_proteinOptionsList,
			AD_priority, 
			AD_enabled, 
			AD_description, 
			AD_creator,
			AD_nextLevel
		) VALUES (
			@level, 
			@seqVal, 
			@instrumentClassCriteria, 
			@campaignNameCriteria, 
			@campaignExclCriteria,
			@experimentNameCriteria, 
			@experimentExclCriteria,
			@instrumentNameCriteria, 
			@organismNameCriteria, 
			@datasetNameCriteria, 
			@datasetExclCriteria,
			@datasetTypeCriteria,
			@expCommentCriteria, 
			@labellingInclCriteria, 
			@labellingExclCriteria, 
			@separationTypeCriteria,
			@analysisToolName, 
			@parmFileName, 
			@settingsFileName, 
			@organismID, 
			@organismDBName, 
			@protCollNameList,
			@protCollOptionsList,
			@priority, 
			@enabled, 
			@description, 
			@creator,
			@nextLevelVal
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
		set @msg = 'Insert operation failed'
			RAISERROR (@msg, 10, 1)
			return 51016
		end

		-- return IDof newly created entry
		--
		set @ID = IDENT_CURRENT('T_Predefined_Analysis')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Predefined_Analysis 
		SET 
			AD_level = @level, 
			AD_sequence = @seqVal, 
			AD_instrumentClassCriteria = @instrumentClassCriteria, 
			AD_campaignNameCriteria = @campaignNameCriteria, 
			AD_campaignExclCriteria = @campaignExclCriteria,
			AD_experimentNameCriteria = @experimentNameCriteria, 
			AD_experimentExclCriteria = @experimentExclCriteria,
			AD_instrumentNameCriteria = @instrumentNameCriteria, 
			AD_organismNameCriteria = @organismNameCriteria, 
			AD_datasetNameCriteria = @datasetNameCriteria, 
			AD_datasetExclCriteria = @datasetExclCriteria,
			AD_datasetTypeCriteria = @datasetTypeCriteria,
			AD_expCommentCriteria = @expCommentCriteria, 
			AD_labellingInclCriteria = @labellingInclCriteria, 
			AD_labellingExclCriteria = @labellingExclCriteria, 
			AD_separationTypeCriteria = @separationTypeCriteria,
			AD_analysisToolName = @analysisToolName, 
			AD_parmFileName = @parmFileName, 
			AD_settingsFileName = @settingsFileName, 
			AD_organism_ID = @organismID, 
			AD_organismDBName = @organismDBName, 
			AD_proteinCollectionList = @protCollNameList,
			AD_proteinOptionsList = @protCollOptionsList,
			AD_priority = @priority, 
			AD_enabled = @enabled, 
			AD_description = @description, 
			AD_creator = @creator,
			AD_nextLevel = @nextLevelVal
		WHERE (AD_ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@msg, 10, 1)
			return 51017
		end
	end -- update mode

Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysis] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysis] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePredefinedAnalysis] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePredefinedAnalysis] TO [PNL\D3M580] AS [dbo]
GO

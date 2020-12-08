/****** Object:  StoredProcedure [dbo].[AddUpdatePredefinedAnalysis] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdatePredefinedAnalysis]
/****************************************************
**
**  Desc: Adds a new default analysis to DB
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   06/21/2005 grk - superseded AddUpdateDefaultAnalysis
**          03/28/2006 grk - added protein collection fields
**          01/26/2007 mem - Switched to organism ID instead of organism name (Ticket #368)
**          07/30/2007 mem - Now validating dataset type and instrument class for the matching instruments against the specified analysis tool (Ticket #502)
**          08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**          09/04/2009 mem - Added DatasetType parameter
**          09/16/2009 mem - Now checking dataset type against the Instrument_Allowed_Dataset_Type table (Ticket #748)
**          10/05/2009 mem - Now validating the parameter file name
**          12/18/2009 mem - Switched to use GetInstrumentDatasetTypeList() to get the allowed dataset types for the dataset and GetAnalysisToolAllowedDSTypeList() to get the allowed dataset types for the analysis tool
**          05/06/2010 mem - Now calling AutoResolveNameToPRN to validate @creator
**          08/26/2010 mem - Now calling ValidateProteinCollectionParams to validate the protein collection info
**          08/28/2010 mem - Now using T_Instrument_Group_Allowed_DS_Type to determine allowed dataset types for matching instruments
**                         - Added try-catch for error handling
**          11/12/2010 mem - Now using T_Analysis_Tool_Allowed_Instrument_Class to lookup the allowed instrument class names for a given analysis tool
**          02/09/2011 mem - Added parameter @TriggerBeforeDisposition
**          02/16/2011 mem - Added parameter @PropagationMode
**          05/02/2012 mem - Added parameter @SpecialProcessing
**          09/25/2012 mem - Expanded @organismNameCriteria and @organismName to varchar(128)
**          04/18/2013 mem - Expanded @description to varchar(512)
**          11/02/2015 mem - Population of #TmpMatchingInstruments now considers the DatasetType criterion
**          02/23/2016 mem - Add set XACT_ABORT on
**          10/27/2016 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**                         - Explicitly update Last_Affected
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/21/2017 mem - Add @instrumentExclCriteria
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/10/2018 mem - Validate the settings file name
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**
*****************************************************/
(
    @level int,
    @sequence varchar(12),
    @instrumentClassCriteria varchar(32),
    @campaignNameCriteria varchar(128),
    @experimentNameCriteria varchar(128),
    @instrumentNameCriteria varchar(64),
    @instrumentExclCriteria varchar(64),
    @organismNameCriteria varchar(128),
    @datasetNameCriteria varchar(128),
    @expCommentCriteria varchar(128),
    @labellingInclCriteria varchar(64),
    @labellingExclCriteria varchar(64),
    @analysisToolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(255),
    @organismName varchar(128),
    @organismDBName varchar(128),
    @protCollNameList varchar(512),
    @protCollOptionsList varchar(256),
    @priority int,
    @enabled tinyint,
    @description varchar(512),
    @creator varchar(50),
    @nextLevel varchar(12),
    @ID int output,
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @separationTypeCriteria varchar(64)='',
    @campaignExclCriteria varchar(128)='',
    @experimentExclCriteria varchar(128)='',
    @datasetExclCriteria varchar(128)='',
    @datasetTypeCriteria varchar(64)='',
    @TriggerBeforeDisposition tinyint = 0,
    @PropagationMode varchar(24)='Export',
    @SpecialProcessing varchar(512)=''
)
As
    Set XACT_ABORT, nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

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

    declare @msg varchar(512) = ''

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdatePredefinedAnalysis', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    if LEN(IsNull(@analysisToolName,'')) < 1
    begin
        set @myError = 51033
        RAISERROR ('Analysis tool name was blank', 11, 1)
    end

    if LEN(IsNull(@parmFileName,'')) < 1
    begin
        set @myError = 51033
        RAISERROR ('Parameter file name was blank', 11, 1)
    end

    if LEN(IsNull(@settingsFileName,'')) < 1
    begin
        set @myError = 51033
        RAISERROR ('Settings file name was blank', 11, 1)
    end

    if LEN(IsNull(@organismName,'')) < 1
    begin
        set @myError = 51033
        RAISERROR ('Organism name was blank; use "(default)" to auto-assign at job creation', 11, 1)
    end

    if LEN(IsNull(@organismDBName,'')) < 1
    begin
        set @myError = 51033
        RAISERROR ('Organism DB name was blank', 11, 1)
    end

    If @myError <> 0
        return @myError

    ---------------------------------------------------
    -- Update any null filter criteria
    ---------------------------------------------------
    Set @instrumentClassCriteria = LTrim(RTrim(IsNull(@instrumentClassCriteria, '')))
    Set @campaignNameCriteria    = LTrim(RTrim(IsNull(@campaignNameCriteria   , '')))
    Set @experimentNameCriteria  = LTrim(RTrim(IsNull(@experimentNameCriteria , '')))
    Set @instrumentNameCriteria  = LTrim(RTrim(IsNull(@instrumentNameCriteria , '')))
    Set @instrumentExclCriteria  = LTrim(RTrim(IsNull(@instrumentExclCriteria , '')))
    Set @organismNameCriteria    = LTrim(RTrim(IsNull(@organismNameCriteria   , '')))
    Set @datasetNameCriteria     = LTrim(RTrim(IsNull(@datasetNameCriteria    , '')))
    Set @expCommentCriteria      = LTrim(RTrim(IsNull(@expCommentCriteria     , '')))
    Set @labellingInclCriteria   = LTrim(RTrim(IsNull(@labellingInclCriteria  , '')))
    Set @labellingExclCriteria   = LTrim(RTrim(IsNull(@labellingExclCriteria  , '')))
    Set @separationTypeCriteria  = LTrim(RTrim(IsNull(@separationTypeCriteria , '')))
    Set @campaignExclCriteria    = LTrim(RTrim(IsNull(@campaignExclCriteria   , '')))
    Set @experimentExclCriteria  = LTrim(RTrim(IsNull(@experimentExclCriteria , '')))
    Set @datasetExclCriteria     = LTrim(RTrim(IsNull(@datasetExclCriteria    , '')))
    Set @datasetTypeCriteria     = LTrim(RTrim(IsNull(@datasetTypeCriteria    , '')))
    Set @SpecialProcessing       = LTrim(RTrim(IsNull(@SpecialProcessing      , '')))

    ---------------------------------------------------
    -- Resolve propagation mode
    ---------------------------------------------------
    declare @propMode tinyint
    set @propMode = CASE IsNull(@PropagationMode, '')
                        WHEN 'Export' THEN 0
                        WHEN 'No Export' THEN 1
                        ELSE 0
                    END

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
            RAISERROR (@msg, 11, 2)
        end
    end

    --------------------------------------------------
    -- Validate the analysis tool name
    --------------------------------------------------

    SELECT @analysisToolID = AJT_toolID
    FROM dbo.T_Analysis_Tool
    WHERE (AJT_toolName = @analysisToolName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @msg = 'Analysis tool "' + @analysisToolName + '" not found in T_Analysis_Tool'
        RAISERROR (@msg, 11, 3)
    End

    ---------------------------------------------------
    -- If @instrumentClassCriteria or @instrumentNameCriteria or @instrumentExclCriteria are defined,
    -- determine the associated Dataset Types and make sure they are
    -- valid for @analysisToolName
    ---------------------------------------------------

    If Len(@instrumentClassCriteria) > 0 Or Len(@instrumentNameCriteria) > 0 Or Len(@instrumentExclCriteria) > 0
    Begin -- <a>

        If Not Exists (
            SELECT ADT.Dataset_Type
            FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
                 INNER JOIN T_Analysis_Tool Tool
                   ON ADT.Analysis_Tool_ID = Tool.AJT_toolID
            WHERE (Tool.AJT_toolName = @analysisToolName)
            )
        Begin
            Set @msg = 'Analysis tool "' + @analysisToolName + '" does not have any allowed dataset types; unable to continue'
            RAISERROR (@msg, 11, 4)
        End

        If Not Exists (
            SELECT AIC.Instrument_Class
            FROM T_Analysis_Tool_Allowed_Instrument_Class AIC
                 INNER JOIN T_Analysis_Tool Tool
                   ON AIC.Analysis_Tool_ID = Tool.AJT_toolID
            WHERE (Tool.AJT_toolName = @analysisToolName)
            )
        Begin
            Set @msg = 'Analysis tool "' + @analysisToolName + '" does not have any allowed instrument classes; unable to continue'
            RAISERROR (@msg, 11, 5)
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
             INNER JOIN T_Instrument_Group_Allowed_DS_Type InstGroupDSType
               ON InstName.IN_Group = InstGroupDSType.IN_Group AND
                  (InstGroupDSType.Dataset_Type LIKE @datasetTypeCriteria OR @datasetTypeCriteria = '')
        WHERE (InstClass.IN_Class LIKE @instrumentClassCriteria OR @instrumentClassCriteria = '') AND
              (InstName.IN_name LIKE @instrumentNameCriteria OR @instrumentNameCriteria = '') AND
              (NOT (InstName.IN_name LIKE @instrumentExclCriteria) OR @instrumentExclCriteria = '')
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin -- <b1>
            set @msg = 'Did not match any instruments using the instrument name and class criteria; update not allowed'
            RAISERROR (@msg, 11, 6)
        End -- </b1>


        ---------------------------------------------------
        -- Step through #TmpMatchingInstruments and make sure
        --  each entry has at least one Dataset Type that is present in T_Analysis_Tool_Allowed_Dataset_Type
        --  for this analysis tool
        -- Also validate each instrument class with T_Analysis_Tool_Allowed_Instrument_Class
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
                    FROM T_Instrument_Name InstName
                         INNER JOIN T_Instrument_Group_Allowed_DS_Type IGADT
                           ON InstName.IN_Group = IGADT.IN_Group
                         INNER JOIN ( SELECT ADT.Dataset_Type
                                      FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
                                           INNER JOIN T_Analysis_Tool Tool
                                             ON ADT.Analysis_Tool_ID = Tool.AJT_toolID
                                      WHERE (Tool.AJT_toolName = @analysisToolName)
                                    ) ToolQ
                           ON IGADT.Dataset_Type = ToolQ.Dataset_Type
                    WHERE (InstName.IN_name = @instrumentName)
                    )
                Begin -- <d1>
                    -- Example criteria that will result in this message: Instrument Criteria=Agilent_TOF%, Tool=AgilentSequest

                    Set @allowedDatasetTypes = dbo.GetInstrumentDatasetTypeList(@InstrumentID)

                    Set @AllowedDSTypesForTool = ''
                    SELECT @AllowedDSTypesForTool = AllowedDatasetTypes
                    FROM dbo.GetAnalysisToolAllowedDSTypeList(@analysisToolID)

                    set @msg = 'Criteria matched instrument "' + @instrumentName + '" with allowed dataset types of "' + @allowedDatasetTypes + '"'
                    set @msg = @msg + '; however, analysis tool ' + @analysisToolName + ' allows these dataset types "' + @AllowedDSTypesForTool + '"'
                    RAISERROR (@msg, 11, 7)
                End     -- </d1>

                If Not Exists (
                    SELECT AIC.Instrument_Class
                    FROM T_Analysis_Tool_Allowed_Instrument_Class AIC
                        INNER JOIN T_Analysis_Tool Tool
                        ON AIC.Analysis_Tool_ID = Tool.AJT_toolID
                    WHERE Tool.AJT_toolName = @analysisToolName AND
                        AIC.Instrument_Class = @instrumentClass
                    )
                Begin -- <d2>
                    -- Example criteria that will result in this message: Instrument Class=BRUKERFTMS, Tool=XTandem
                    -- 2nd example: Instrument Criteria=Agilent_TOF%, Tool=Decon2LS

                    Set @AllowedInstClassesForTool = ''
                    SELECT @AllowedInstClassesForTool = AllowedInstrumentClasses
                    FROM dbo.GetAnalysisToolAllowedInstClassList (@analysisToolID)

                    set @msg = 'Criteria matched instrument "' + @instrumentName + '" which is Instrument Class "' + @instrumentClass + '"'
                    set @msg = @msg + '; however, analysis tool ' + @analysisToolName + ' allows these instrument classes "' + @AllowedInstClassesForTool + '"'
                    RAISERROR (@msg, 11, 8)
                End     -- </d2>

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
        RAISERROR (@msg, 11, 9)
    end

    ---------------------------------------------------
    -- Validate the parameter file name
    ---------------------------------------------------
    --
    If @parmFileName <> 'na'
    Begin
        If Not Exists (SELECT * FROM T_Param_Files WHERE Param_File_Name = @parmFileName)
        Begin
            set @msg = 'Could not find entry in database for parameter file "' + @parmFileName + '"'
            RAISERROR (@msg, 11, 10)
        End
    End

    ---------------------------------------------------
    -- Validate the settings file name
    ---------------------------------------------------
    --
    If @settingsFileName <> 'na'
    Begin
        If Not Exists (SELECT * FROM T_Settings_Files WHERE File_Name = @settingsFileName)
        Begin
            set @msg = 'Could not find entry in database for settings file "' + @settingsFileName + '"'
            RAISERROR (@msg, 11, 10)
        End
    End

    ---------------------------------------------------
    -- Check protein parameters
    ---------------------------------------------------

    Declare @result int
    Declare @ownerPRN varchar(64)

    set @result = 0
    Set @ownerPRN = ''

    exec @result = ValidateProteinCollectionParams
                    @analysisToolName,
                    @organismDBName output,
                    @organismName,
                    @protCollNameList output,
                    @protCollOptionsList output,
                    @ownerPRN,
                    @message output,
                    @debugMode=0

    if @result <> 0
    Begin
        set @msg = @message
        RAISERROR (@msg, 11, 11)
    End

    ---------------------------------------------------
    -- @creator should be a userPRN
    -- Auto-capitalize it or auto-resolve it from a name to a PRN
    ---------------------------------------------------

    Declare @userID int

    execute @userID = GetUserID @creator

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @creator contains simply the username
        --
        SELECT @creator = U_PRN
        FROM T_Users
	    WHERE ID = @userID
    End
    Else
    Begin
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
        RAISERROR (@msg, 11, 12)
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
            AD_instrumentExclCriteria,
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
            AD_specialProcessing,
            AD_enabled,
            AD_description,
            AD_creator,
            AD_nextLevel,
            Trigger_Before_Disposition,
            Propagation_Mode,
            Last_Affected
        ) VALUES (
            @level,
            @seqVal,
            @instrumentClassCriteria,
            @campaignNameCriteria,
            @campaignExclCriteria,
            @experimentNameCriteria,
            @experimentExclCriteria,
            @instrumentNameCriteria,
            @instrumentExclCriteria,
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
            @SpecialProcessing,
            @enabled,
            @description,
            @creator,
            @nextLevelVal,
            IsNull(@TriggerBeforeDisposition, 0),
            @propMode,
            GetDate()
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
        set @msg = 'Insert operation failed'
            RAISERROR (@msg, 11, 13)
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
            AD_instrumentExclCriteria = @instrumentExclCriteria,
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
            AD_specialProcessing = @SpecialProcessing,
            AD_enabled = @enabled,
            AD_description = @description,
            AD_creator = @creator,
            AD_nextLevel = @nextLevelVal,
            Trigger_Before_Disposition = IsNull(@TriggerBeforeDisposition, 0),
            Propagation_Mode = @propMode,
            Last_Affected = GetDate()
        WHERE (AD_ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Update operation failed: "' + @ID + '"'
            RAISERROR (@msg, 11, 14)
        end
    end -- update mode

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AddUpdatePredefinedAnalysis'
    END CATCH

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePredefinedAnalysis] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysis] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysis] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePredefinedAnalysis] TO [Limited_Table_Write] AS [dbo]
GO

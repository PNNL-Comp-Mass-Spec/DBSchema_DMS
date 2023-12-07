/****** Object:  StoredProcedure [dbo].[add_update_predefined_analysis] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_predefined_analysis]
/****************************************************
**
**  Desc: Adds a new default analysis to DB
**
**  Return values: 0: success, otherwise, error code
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
**          12/18/2009 mem - Switched to use get_instrument_dataset_type_list() to get the allowed dataset types for the dataset and get_analysis_tool_allowed_dataset_type_list() to get the allowed dataset types for the analysis tool
**          05/06/2010 mem - Now calling auto_resolve_name_to_username to validate @creator
**          08/26/2010 mem - Now calling validate_protein_collection_params to validate the protein collection info
**          08/28/2010 mem - Now using T_Instrument_Group_Allowed_DS_Type to determine allowed dataset types for matching instruments
**                         - Added try-catch for error handling
**          11/12/2010 mem - Now using T_Analysis_Tool_Allowed_Instrument_Class to lookup the allowed instrument class names for a given analysis tool
**          02/09/2011 mem - Added parameter @triggerBeforeDisposition
**          02/16/2011 mem - Added parameter @PropagationMode
**          05/02/2012 mem - Added parameter @specialProcessing
**          09/25/2012 mem - Expanded @organismNameCriteria and @organismName to varchar(128)
**          04/18/2013 mem - Expanded @description to varchar(512)
**          11/02/2015 mem - Population of #TmpMatchingInstruments now considers the DatasetType criterion
**          02/23/2016 mem - Add set XACT_ABORT on
**          10/27/2016 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**                         - Explicitly update Last_Affected
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/21/2017 mem - Add @instrumentExclCriteria
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/10/2018 mem - Validate the settings file name
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          06/30/2022 mem - Rename parameter file argument
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          12/06/2023 mem - Add support for scan type criteria
**
*****************************************************/
(
    @level int,
    @sequence varchar(12),
    @nextLevel varchar(12),
    @triggerBeforeDisposition tinyint,
    @propagationMode varchar(24),
    @instrumentClassCriteria varchar(32),
    @instrumentNameCriteria varchar(64),
    @instrumentExclCriteria varchar(64),
    @campaignNameCriteria varchar(128),
    @campaignExclCriteria varchar(128),
    @experimentNameCriteria varchar(128),
    @experimentExclCriteria varchar(128),
    @experimentCommentCriteria varchar(128),
    @organismNameCriteria varchar(128),
    @datasetNameCriteria varchar(128),
    @datasetExclCriteria varchar(128),
    @datasetTypeCriteria varchar(64),
    @scanTypeCriteria varchar(64),
    @scanTypeExclCriteria varchar(64),
    @labellingInclCriteria varchar(64),
    @labellingExclCriteria varchar(64),
    @separationTypeCriteria varchar(64)='',
    @analysisToolName varchar(64),
    @paramFileName varchar(255),
    @settingsFileName varchar(255),
    @organismName varchar(128),
    @organismDBName varchar(128),
    @protCollNameList varchar(512),
    @protCollOptionsList varchar(256),
    @priority int,
    @enabled tinyint,
    @description varchar(512),
    @specialProcessing varchar(512),
    @creator varchar(50),
    @id int output,
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @allowedDatasetTypes varchar(255)
    Declare @AllowedDSTypesForTool varchar(1024)
    Declare @AllowedInstClassesForTool varchar(1024)

    Declare @UniqueID int
    Declare @continue int
    Declare @MatchCount int
    Declare @instrumentName varchar(128)
    Declare @InstrumentID int
    Declare @instrumentClass varchar(128)
    Declare @analysisToolID int

    Declare @msg varchar(512) = ''

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0

    Exec @authorized = verify_sp_authorized 'add_update_predefined_analysis', @raiseError = 1

    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @analysisToolName = LTrim(RTrim(Coalesce(@analysisToolName, '')))
    Set @paramFileName    = LTrim(RTrim(Coalesce(@paramFileName   , '')))
    Set @settingsFileName = LTrim(RTrim(Coalesce(@settingsFileName, '')))
    Set @organismName     = LTrim(RTrim(Coalesce(@organismName    , '')))
    Set @organismDBName   = LTrim(RTrim(Coalesce(@organismDBName  , '')))


    If LEN(@analysisToolName) < 1
    Begin
        Set @myError = 51033
        RAISERROR ('Analysis tool name must be specified', 11, 1)
    End

    If LEN(@paramFileName) < 1
    Begin
        Set @myError = 51033
        RAISERROR ('Parameter file name must be specified', 11, 1)
    End

    If LEN(@settingsFileName) < 1
    Begin
        Set @myError = 51033
        RAISERROR ('Settings file name must be specified', 11, 1)
    End

    If LEN(@organismName) < 1
    Begin
        Set @myError = 51033
        RAISERROR ('Organism name must be specified; use "(default)" to auto-assign at job creation', 11, 1)
    End

    If LEN(@organismDBName) < 1
    Begin
        Set @myError = 51033
        RAISERROR ('Organism DB name must be specified', 11, 1)
    End

    If @myError <> 0
        return @myError

    ---------------------------------------------------
    -- Update any null filter criteria
    ---------------------------------------------------

    Set @triggerBeforeDisposition   = Coalesce(@triggerBeforeDisposition, 0)
    Set @priority                   = Coalesce(@priority, 3);
    Set @enabled                    = Coalesce(@enabled, 1);

    Set @instrumentClassCriteria    = LTrim(RTrim(Coalesce(@instrumentClassCriteria  , '')))
    Set @instrumentNameCriteria     = LTrim(RTrim(Coalesce(@instrumentNameCriteria   , '')))
    Set @instrumentExclCriteria     = LTrim(RTrim(Coalesce(@instrumentExclCriteria   , '')))
    Set @campaignNameCriteria       = LTrim(RTrim(Coalesce(@campaignNameCriteria     , '')))
    Set @campaignExclCriteria       = LTrim(RTrim(Coalesce(@campaignExclCriteria     , '')))
    Set @experimentNameCriteria     = LTrim(RTrim(Coalesce(@experimentNameCriteria   , '')))
    Set @experimentExclCriteria     = LTrim(RTrim(Coalesce(@experimentExclCriteria   , '')))
    Set @experimentCommentCriteria  = LTrim(RTrim(Coalesce(@experimentCommentCriteria, '')))
    Set @datasetNameCriteria        = LTrim(RTrim(Coalesce(@datasetNameCriteria      , '')))
    Set @datasetExclCriteria        = LTrim(RTrim(Coalesce(@datasetExclCriteria      , '')))
    Set @datasetTypeCriteria        = LTrim(RTrim(Coalesce(@datasetTypeCriteria      , '')))
    Set @scanTypeCriteria           = LTrim(RTrim(Coalesce(@scanTypeCriteria         , '')))
    Set @scanTypeExclCriteria       = LTrim(RTrim(Coalesce(@scanTypeExclCriteria     , '')))
    Set @labellingInclCriteria      = LTrim(RTrim(Coalesce(@labellingInclCriteria    , '')))
    Set @labellingExclCriteria      = LTrim(RTrim(Coalesce(@labellingExclCriteria    , '')))
    Set @separationTypeCriteria     = LTrim(RTrim(Coalesce(@separationTypeCriteria   , '')))
    Set @organismName               = LTrim(RTrim(Coalesce(@organismName             , '')))
    Set @protCollNameList           = LTrim(RTrim(Coalesce(@protCollNameList         , '')))
    Set @protCollOptionsList        = LTrim(RTrim(Coalesce(@protCollOptionsList      , '')))
    Set @description                = LTrim(RTrim(Coalesce(@description              , '')))
    Set @specialProcessing          = LTrim(RTrim(Coalesce(@specialProcessing        , '')))

    ---------------------------------------------------
    -- Resolve propagation mode
    ---------------------------------------------------
    Declare @propMode tinyint = CASE Coalesce(@PropagationMode, '')
                                    WHEN 'Export' THEN 0
                                    WHEN 'No Export' THEN 1
                                    ELSE 0
                                END

    ---------------------------------------------------
    -- Validate @level, @sequence, and @nextLevel
    ---------------------------------------------------

    If @level Is Null
    Begin
        Set @msg = 'Level cannot be null'
        RAISERROR (@msg, 11, 2)
    End

    Declare @seqVal int
    Declare @nextLevelVal int

    If LTrim(RTrim(Coalesce(@sequence, ''))) <> ''
    Begin
        Set @seqVal = convert(int, @sequence)
    End

    If LTrim(RTrim(Coalesce(@nextLevel, ''))) <> ''
    Begin
        Set @nextLevelVal = convert(int, @nextLevel)

        If @nextLevelVal <= @level
        Begin
            Set @msg = 'Next level must be greater than current level'
            RAISERROR (@msg, 11, 2)
        End
    End

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
    -- determine the associated Dataset Types and make sure they are valid for @analysisToolName
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
        Begin
            Set @msg = 'Did not match any instruments using the instrument name, instrument class, and dataset type criteria; update not allowed'
            RAISERROR (@msg, 11, 6)
        End


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

                    Set @allowedDatasetTypes = dbo.get_instrument_dataset_type_list(@InstrumentID)

                    Set @AllowedDSTypesForTool = ''
                    SELECT @AllowedDSTypesForTool = AllowedDatasetTypes
                    FROM dbo.get_analysis_tool_allowed_dataset_type_list(@analysisToolID)

                    Set @msg = 'Criteria matched instrument "' + @instrumentName + '" with allowed dataset types of "' + @allowedDatasetTypes + '"'
                    Set @msg = @msg + '; however, analysis tool ' + @analysisToolName + ' allows these dataset types "' + @AllowedDSTypesForTool + '"'
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
                    FROM dbo.get_analysis_tool_allowed_inst_class_list (@analysisToolID)

                    Set @msg = 'Criteria matched instrument "' + @instrumentName + '" which is Instrument Class "' + @instrumentClass + '"'
                    Set @msg = @msg + '; however, analysis tool ' + @analysisToolName + ' allows these instrument classes "' + @AllowedInstClassesForTool + '"'
                    RAISERROR (@msg, 11, 8)
                End     -- </d2>

            End -- </c>
        End -- </b2>

    End -- </a>


    ---------------------------------------------------
    -- Resolve organism ID
    ---------------------------------------------------

    Declare @organismID int

    exec @organismID = get_organism_id @organismName

    If @organismID = 0
    Begin
        Set @msg = 'Could not find entry in database for organismName "' + @organismName + '"'
        RAISERROR (@msg, 11, 9)
    End

    ---------------------------------------------------
    -- Validate the parameter file name
    ---------------------------------------------------
    --
    If @paramFileName <> 'na'
    Begin
        If Not Exists (SELECT * FROM T_Param_Files WHERE Param_File_Name = @paramFileName)
        Begin
            Set @msg = 'Could not find entry in database for parameter file "' + @paramFileName + '"'
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
            Set @msg = 'Could not find entry in database for settings file "' + @settingsFileName + '"'
            RAISERROR (@msg, 11, 10)
        End
    End

    ---------------------------------------------------
    -- Check protein parameters
    ---------------------------------------------------

    Declare @result int = 0
    Declare @ownerUsername varchar(64) = ''

    exec @result = validate_protein_collection_params
                    @analysisToolName,
                    @organismDBName output,
                    @organismName,
                    @protCollNameList output,
                    @protCollOptionsList output,
                    @ownerUsername,
                    @message output,
                    @debugMode=0

    If @result <> 0
    Begin
        Set @msg = @message
        RAISERROR (@msg, 11, 11)
    End

    ---------------------------------------------------
    -- @creator should be a username
    -- Auto-capitalize it or auto-resolve it from a name to a username
    ---------------------------------------------------

    Declare @userID int

    exec @userID = get_user_id @creator

    If @userID > 0
    Begin
        -- SP get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
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
        -- In case a name was entered (instead of a username),
        --  try to auto-resolve using the U_Name column in T_Users
        ---------------------------------------------------
        Declare @newUsername varchar(64)

        exec auto_resolve_name_to_username @creator, @MatchCount output, @newUsername output, @userID output

        If @MatchCount = 1
        Begin
            -- Single match was found; update @creator
            Set @creator = @newUsername
        End
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp int = 0

        SELECT @tmp = AD_ID
        FROM  T_Predefined_Analysis
        WHERE (AD_ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0 OR @tmp = 0
        Begin
            Set @msg = 'No entry could be found in database for update'
            RAISERROR (@msg, 11, 12)
        End

    End
    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @Mode = 'add'
    Begin

        INSERT INTO T_Predefined_Analysis (
            AD_level,
            AD_sequence,
            AD_nextLevel,
            Trigger_Before_Disposition,
            Propagation_Mode,
            AD_instrumentClassCriteria,
            AD_instrumentNameCriteria,
            AD_instrumentExclCriteria,
            AD_campaignNameCriteria,
            AD_campaignExclCriteria,
            AD_experimentNameCriteria,
            AD_experimentExclCriteria,
            AD_expCommentCriteria,
            AD_organismNameCriteria,
            AD_datasetNameCriteria,
            AD_datasetExclCriteria,
            AD_datasetTypeCriteria,
            AD_scanTypeCriteria,
            AD_scanTypeExclCriteria,
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
            AD_specialProcessing,
            AD_creator,
            Last_Affected
        ) VALUES (
            @level,
            @seqVal,
            @nextLevelVal,
            @triggerBeforeDisposition,
            @propMode,
            @instrumentClassCriteria,
            @instrumentNameCriteria,
            @instrumentExclCriteria,
            @campaignNameCriteria,
            @campaignExclCriteria,
            @experimentNameCriteria,
            @experimentExclCriteria,
            @experimentCommentCriteria,
            @organismNameCriteria,
            @datasetNameCriteria,
            @datasetExclCriteria,
            @datasetTypeCriteria,
            @scanTypeCriteria,
            @scanTypeExclCriteria,
            @labellingInclCriteria,
            @labellingExclCriteria,
            @separationTypeCriteria,
            @analysisToolName,
            @paramFileName,
            @settingsFileName,
            @organismID,
            @organismDBName,
            @protCollNameList,
            @protCollOptionsList,
            @priority,
            @enabled,
            @description,
            @specialProcessing,
            @creator,
            GetDate()
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
        Set @msg = 'Insert operation failed'
            RAISERROR (@msg, 11, 13)
        End

        -- return ID of newly created entry
        --
        Set @ID = SCOPE_IDENTITY()

    End -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @Mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_Predefined_Analysis
        SET
            AD_level                   = @level,
            AD_sequence                = @seqVal,
            AD_nextLevel               = @nextLevelVal,
            Trigger_Before_Disposition = @triggerBeforeDisposition,
            Propagation_Mode           = @propMode,
            AD_instrumentClassCriteria = @instrumentClassCriteria,
            AD_instrumentNameCriteria  = @instrumentNameCriteria,
            AD_instrumentExclCriteria  = @instrumentExclCriteria,
            AD_campaignNameCriteria    = @campaignNameCriteria,
            AD_campaignExclCriteria    = @campaignExclCriteria,
            AD_experimentNameCriteria  = @experimentNameCriteria,
            AD_experimentExclCriteria  = @experimentExclCriteria,
            AD_expCommentCriteria      = @experimentCommentCriteria,
            AD_organismNameCriteria    = @organismNameCriteria,
            AD_datasetNameCriteria     = @datasetNameCriteria,
            AD_datasetExclCriteria     = @datasetExclCriteria,
            AD_datasetTypeCriteria     = @datasetTypeCriteria,
            AD_scanTypeCriteria        = @scanTypeCriteria,
            AD_scanTypeExclCriteria    = @scanTypeExclCriteria,
            AD_labellingInclCriteria   = @labellingInclCriteria,
            AD_labellingExclCriteria   = @labellingExclCriteria,
            AD_separationTypeCriteria  = @separationTypeCriteria,
            AD_analysisToolName        = @analysisToolName,
            AD_parmFileName            = @paramFileName,
            AD_settingsFileName        = @settingsFileName,
            AD_organism_ID             = @organismID,
            AD_organismDBName          = @organismDBName,
            AD_proteinCollectionList   = @protCollNameList,
            AD_proteinOptionsList      = @protCollOptionsList,
            AD_priority                = @priority,
            AD_enabled                 = @enabled,
            AD_description             = @description,
            AD_specialProcessing       = @specialProcessing,
            AD_creator                 = @creator,
            Last_Affected              = GetDate()
        WHERE AD_ID = @ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @msg = 'Update operation failed: "' + @ID + '"'
            RAISERROR (@msg, 11, 14)
        End
    End -- update mode

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'add_update_predefined_analysis'
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_predefined_analysis] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_predefined_analysis] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_predefined_analysis] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_predefined_analysis] TO [Limited_Table_Write] AS [dbo]
GO

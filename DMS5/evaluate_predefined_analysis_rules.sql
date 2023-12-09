/****** Object:  StoredProcedure [dbo].[evaluate_predefined_analysis_rules] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[evaluate_predefined_analysis_rules]
/****************************************************
**
**  Desc:
**      Evaluate predefined analysis rules for given dataset and generate the specifed output type
**
**      When @outputType is 'Export Jobs', the calling procedure must create table #JX
**
**      CREATE TABLE #JX (
**          predefine_id int,
**          dataset varchar(128),
**          priority varchar(8),
**          analysisToolName varchar(64),
**          paramFileName varchar(255),
**          settingsFileName varchar(128),
**          organismName varchar(128),
**          proteinCollectionList varchar(4000),
**          proteinOptionsList varchar(256),
**          organismDBName varchar(128),
**          ownerUsername varchar(128),
**          comment varchar(128),
**          associatedProcessorGroup varchar(64),
**          numJobs int,
**          propagationMode tinyint,
**          specialProcessing varchar(512),
**          ID int IDENTITY (1, 1) NOT NULL
**      )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/23/2005
**          03/03/2006 mem - Increased size of the AD_datasetNameCriteria and AD_expCommentCriteria fields in temporary table #AD
**          03/28/2006 grk - added protein collection fields
**          04/04/2006 grk - increased sized of param file name
**          11/30/2006 mem - Now evaluating dataset type for each analysis tool (Ticket #335)
**          12/21/2006 mem - Updated 'Show Rules' to include explanations for why a rule was used, altered, or skipped (Ticket #339)
**          01/26/2007 mem - Now getting organism name from T_Organisms (Ticket #368)
**          03/15/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**          03/16/2007 mem - Updated to use processor group ID (Ticket #419)
**          09/04/2007 grk - corrected bug in "@RuleEvalNotes" update.
**          12/28/2007 mem - Updated to allow preview of jobs for datasets with rating -10 (unreviewed)
**          01/04/2007 mem - Fixed bug that incorrectly allowed rules to be evaluated when rating = -10 and @outputType = 'Export Jobs'
**          01/30/2008 grk - Set several in #RuleEval to be explicitly null (needed by DMS2)
**          04/11/2008 mem - Added parameter @RaiseErrorMessages; now using RaiseError to inform the user of errors if @RaiseErrorMessages is non-zero
**          08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**          05/14/2009 mem - Added parameter @ExcludeDatasetsNotReleased
**          07/22/2009 mem - Now returning 0 if @jobsCreated = 0 and @myError = 0 (previously, we were returning 1, which a calling procedure could erroneously interpret as meaning an error had occurred)
**          09/04/2009 mem - Added DatasetType filter
**          12/18/2009 mem - Now using T_Analysis_Tool_Allowed_Dataset_Type to determine valid dataset types for a given analysis tool
**          07/12/2010 mem - Now calling validate_protein_collection_list_for_datasets to validate the protein collection list (and possibly add mini proteome or enzyme-related protein collections)
**                         - Expanded protein Collection fields and variables to varchar(4000)
**          09/24/2010 mem - Now testing for a rating of -6 (Not Accepted)
**          11/18/2010 mem - Rearranged rating check code for clarity
**          02/09/2011 mem - Added support for predefines with Trigger_Before_Disposition = 1
**                         - Added parameter @CreateJobsForUnreviewedDatasets
**          02/16/2011 mem - Added support for Propagation Mode (aka Export Mode)
**          05/03/2012 mem - Added support for the Special Processing field
**          09/25/2012 mem - Expanded @organismName and @organismDBName to varchar(128)
**          08/02/2013 mem - Added parameter @AnalysisToolNameFilter
**          04/30/2015 mem - Added support for min and max ScanCount
**          04/21/2017 mem - Add AD_instrumentNameCriteria
**          10/05/2017 mem - Create jobs for datasets with rating -4: "Not released (allow analysis)"
**          08/29/2018 mem - Create jobs for datasets with rating -6: "Rerun (Good Data)"
**          06/30/2022 mem - Rename parameter file column
**          11/08/2022 mem - Rename Rule_ID to Predefine_ID
**          11/09/2022 mem - Replace % signs with %% in the text sent to RAISERROR()
**          01/26/2023 mem - Show the predefine ID when mode is 'Show Jobs'
**                         - Use lowercase column names when mode is 'Show Jobs'
**          01/27/2023 mem - Rename dataset argument to @datasetName
**                         - No longer show processor group for mode 'Show Jobs'
**                         - Remove periods from output columns for mode 'Show Rules' (and change to lowercase)
**                         - Rename columns in temporary table #JX, and add column predefine_id
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          12/07/2023 mem - Add support for scan type inclusion or exclusion
**          12/08/2023 mem - Store or show standalone FASTA files (organism DBs) after protein collections
**
*****************************************************/
(
    @datasetName varchar(128),
    @outputType varchar(12) = 'Show Rules',         -- 'Show Rules', 'Show Jobs', 'Export Jobs'
    @message varchar(512) = '' output,
    @raiseErrorMessages tinyint = 1,
    @excludeDatasetsNotReleased tinyint = 1,        -- When non-zero, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
    @createJobsForUnreviewedDatasets tinyint = 1,   -- When non-zero, will create jobs for datasets with a rating of -10 using predefines with Trigger_Before_Disposition = 1
    @analysisToolNameFilter varchar(128) = ''       -- If not blank, then only considers predefines that match the given tool name (can contain wildcards)
)
AS
    Set nocount on

    Declare @myError Int =  0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @datasetName = IsNull(@datasetName, '')
    Set @RaiseErrorMessages = IsNull(@RaiseErrorMessages, 1)
    Set @ExcludeDatasetsNotReleased = IsNull(@ExcludeDatasetsNotReleased, 1)
    Set @CreateJobsForUnreviewedDatasets = IsNull(@CreateJobsForUnreviewedDatasets, 1)
    Set @AnalysisToolNameFilter = IsNull(@AnalysisToolNameFilter, '')

    ---------------------------------------------------
    -- Validate @outputType
    ---------------------------------------------------
    Set @outputType = IsNull(@outputType, '')

    If NOT @outputType IN ('Show Rules', 'Show Jobs', 'Export Jobs')
    Begin
        Set @message = 'Unknown value for @outputType (' + @outputType + '); should be "Show Rules", "Show Jobs", or "Export Jobs"'
        If @RaiseErrorMessages <> 0
        Begin
            RAISERROR (@message, 10, 1)
        End

        return 51001
    End

    ---------------------------------------------------
    ---------------------------------------------------
    -- Rule selection section
    ---------------------------------------------------
    ---------------------------------------------------

    ---------------------------------------------------
    -- get evaluation information for this dataset
    ---------------------------------------------------

    Declare @Campaign varchar(128)
    Declare @Experiment varchar(128)
    Declare @ExperimentComment varchar(128)
    Declare @ExperimentLabelling varchar(128)
    Declare @Dataset varchar(128)
    Declare @DatasetType varchar(128)
    Declare @ScanTypes varchar(128)
    Declare @SeparationType varchar(64)
    Declare @Organism varchar(128)
    Declare @InstrumentName varchar(128)
    Declare @InstrumentClass varchar(128)
    Declare @DatasetComment varchar(128)
    Declare @Rating smallint
    Declare @ScanCount int

    Declare @ID int  = 0
    Declare @msg Varchar(512)
    --
    SELECT
        @Campaign = Campaign,
        @Experiment = Experiment,
        @ExperimentComment = Experiment_Comment,
        @ExperimentLabelling = Experiment_Labelling,
        @Dataset = Dataset,
        @DatasetType = Dataset_Type,
        @ScanTypes = Scan_Types,
        @SeparationType = Separation_Type,
        @Organism = Organism,
        @InstrumentName = Instrument,
        @InstrumentClass = InstrumentClass,
        @DatasetComment = Dataset_Comment,
        @Rating = Rating,
        @ScanCount = Scan_Count,
        @ID = ID
    FROM V_Predefined_Analysis_Dataset_Info
    Where Dataset = @datasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0 or @ID = 0
    Begin
        Set @message = 'Dataset name not found in DMS: ' + @datasetName

        If @RaiseErrorMessages <> 0
        Begin
            Set @msg = Replace(@message, '%', '%%')
            RAISERROR (@msg, 10, 1)
        End

        If @myError = 0
            Set @myError = 53500

        goto done
    End

    -- Only perform the following checks if the rating is less than 2
    If (@Rating < 2)
    Begin

        -- Continue with these checks if the rating is > -10 or if we are creating jobs
        -- (If the rating is -10 and @outputType is not 'Export Jobs', we want to
        --  allow the predefined analysis rules to be evaluated so that we can preview the results)
        If @Rating <> -10 OR @outputType = 'Export Jobs'
        Begin
            If @ExcludeDatasetsNotReleased = 0 And @Rating IN (-4, -5, -6)
            Begin
                -- Allow the jobs to be created
                Set @message = ''
            End
            Else
            Begin
                If @Rating = -10 And @CreateJobsForUnreviewedDatasets <> 0 OR @Rating IN (-4, -6)
                Begin
                    -- Either the dataset is unreviewed, but @CreateJobsForUnreviewedDatasets is non-zero
                    -- or Rating is -4 (Not released, allow analysis)
                    -- or Rating is -6 (Not released, good data)
                    -- Allow the jobs to be created
                    Set @message = ''
                End
                Else
                Begin
                    -- Do not allow the jobs to be created
                    -- Note that SP create_predefined_analysis_jobs expects the format of @message to be something like:
                    --   Dataset rating (-10) does not allow creation of jobs: 47538_Pls_FF_IGT_23_25Aug10_Andromeda_10-07-10
                    -- Thus, be sure to update create_predefined_analysis_jobs if you change the following line
                    Set @message = 'Dataset rating (' + Convert(varchar(6), @Rating) + ') does not allow creation of jobs: ' + @datasetName

                    If @RaiseErrorMessages <> 0
                    Begin
                        Set @myError = 53501
                        Set @msg = Replace(@message, '%', '%%')
                        RAISERROR (@msg, 10, 1)
                    End

                    goto done
                End
            End
        End
    End

    ---------------------------------------------------
    -- create temporary table to hold evaluation criteria
    ---------------------------------------------------

    CREATE TABLE #AD (
        AD_level int NOT NULL,
        AD_sequence int NULL,
        AD_instrumentClassCriteria varchar (32) NOT NULL,
        AD_campaignNameCriteria    varchar (128) NOT NULL,
        AD_campaignExclCriteria    varchar (128) NOT NULL,
        AD_experimentNameCriteria  varchar (128) NOT NULL,
        AD_experimentExclCriteria  varchar (128) NOT NULL,
        AD_expCommentCriteria      varchar (128) NOT NULL,
        AD_instrumentNameCriteria  varchar (64) NOT NULL,
        AD_instrumentExclCriteria  varchar (64) NOT NULL,
        AD_organismNameCriteria    varchar (128) NOT NULL,
        AD_datasetNameCriteria     varchar (128) NOT NULL,
        AD_datasetExclCriteria     varchar (128) NOT NULL,
        AD_datasetTypeCriteria     varchar (64) NOT NULL,
        AD_scanTypeCriteria        varchar (64) NOT NULL,
        AD_scanTypeExclCriteria    varchar (64) NOT NULL,
        AD_labellingInclCriteria   varchar (64) NOT NULL,
        AD_labellingExclCriteria   varchar (64) NOT NULL,
        AD_separationTypeCriteria  varchar (64) NOT NULL,
        AD_scanCountMin            int NOT NULL,
        AD_scanCountMax            int NOT NULL,
        AD_analysisToolName        varchar (64) NOT NULL,
        AD_paramFileName           varchar (255) NOT NULL,
        AD_settingsFileName        varchar (255) NULL,
        AD_organismName            varchar (128) NOT NULL,
        AD_proteinCollectionList   varchar(4000),
        AD_proteinOptionsList      varchar(256),
        AD_organismDBName          varchar (128) NOT NULL,
        AD_priority                int NOT NULL,
        AD_nextLevel               int NULL,
        Trigger_Before_Disposition tinyint NOT NULL,
        Propagation_Mode           tinyint NOT NULL,
        Special_Processing         varchar(512) NULL,
        AD_ID int  NOT NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Could not create temporary criteria table'
        goto done
    End


    If @outputType = 'Show Rules'
    Begin
        CREATE TABLE #RuleEval (
            [Step] int IDENTITY(1,1),
            [Level] int,
            [Seq.] int NULL,
            Predefine_ID int,
            [Next Lvl.] int NULL,
            [Trigger Mode] varchar(32) NULL,
            [Export Mode] varchar(32) NULL,
            [Action] varchar(64) NULL,
            [Reason] varchar(256) NULL,
            [Notes] varchar(256) NULL,
            [Analysis Tool] varchar(64) NULL,
            [Instrument Class Crit.] varchar(32) NULL,
            [Instrument Crit.] varchar(128) NULL,
            [Instrument Exclusion] varchar(128) NULL,
            [Campaign Crit.] varchar(128) NULL,
            [Campaign Exclusion] varchar(128),
            [Experiment Crit.] varchar(128) NULL,
            [Experiment Exclusion] varchar(128),
            [Exp. Comment Crit.] varchar(128) NULL,
            [Organism Crit.] varchar(128) NULL,
            [Dataset Crit.] varchar(128) NULL,
            [Dataset Exclusion] varchar(128),
            [Dataset Type] varchar(128) NULL,
            [Scan Type Crit.] varchar(64) NULL,
            [Scan Type Exclusion] varchar(64) NULL,
            [Labelling Incl.] varchar(64) NULL,
            [Labelling Excl.] varchar(64) NULL,
            [Separation Type Crit.] varchar(64) NULL,
            [ScanCount Min] int NULL,
            [ScanCount Max] int NULL,
            [Param File] varchar(255) NULL,
            [Settings File] varchar(255) NULL,
            Organism varchar(128) NULL,
            [Organism DB] varchar(128) NULL,
            [Prot. Coll.] varchar(4000) NULL,
            [Prot. Opts.] varchar(256) NULL,
            [Special Proc.] varchar(512) NULL,
            Priority int NULL,
            [Processor Group] varchar(64) NULL
        )
    End


    ---------------------------------------------------
    -- Populate the rule holding table with rules
    -- that the target dataset satisfies
    ---------------------------------------------------

    INSERT INTO #AD (
        AD_level,
        AD_sequence,
        AD_instrumentClassCriteria,
        AD_campaignNameCriteria,
        AD_campaignExclCriteria,
        AD_experimentNameCriteria,
        AD_experimentExclCriteria,
        AD_expCommentCriteria,
        AD_instrumentNameCriteria,
        AD_instrumentExclCriteria,
        AD_organismNameCriteria,
        AD_datasetNameCriteria,
        AD_datasetExclCriteria,
        AD_datasetTypeCriteria,
        AD_scanTypeCriteria,
        AD_scanTypeExclCriteria,
        AD_labellingInclCriteria,
        AD_labellingExclCriteria,
        AD_separationTypeCriteria,
        AD_scanCountMin,
        AD_scanCountMax,
        AD_analysisToolName,
        AD_paramFileName,
        AD_settingsFileName,
        AD_organismName,
        AD_proteinCollectionList,
        AD_proteinOptionsList,
        AD_organismDBName,
        AD_priority,
        AD_nextLevel,
        Trigger_Before_Disposition,
        Propagation_Mode,
        Special_Processing,
        AD_ID
    )
    SELECT
        PA.AD_level,
        PA.AD_sequence,
        PA.AD_instrumentClassCriteria,
        PA.AD_campaignNameCriteria,
        PA.AD_campaignExclCriteria,
        PA.AD_experimentNameCriteria,
        PA.AD_experimentExclCriteria,
        PA.AD_expCommentCriteria,
        PA.AD_instrumentNameCriteria,
        PA.AD_instrumentExclCriteria,
        PA.AD_organismNameCriteria,
        PA.AD_datasetNameCriteria,
        PA.AD_datasetExclCriteria,
        PA.AD_datasetTypeCriteria,
        PA.AD_scanTypeCriteria,
        PA.AD_scanTypeExclCriteria,
        PA.AD_labellingInclCriteria,
        PA.AD_labellingExclCriteria,
        PA.AD_separationTypeCriteria,
        PA.AD_scanCountMinCriteria,
        PA.AD_scanCountMaxCriteria,
        PA.AD_analysisToolName,
        PA.AD_parmFileName,
        PA.AD_settingsFileName,
        Org.OG_Name,
        PA.AD_proteinCollectionList,
        PA.AD_proteinOptionsList,
        PA.AD_organismDBName,
        PA.AD_priority,
        PA.AD_nextLevel,
        PA.Trigger_Before_Disposition,
        PA.Propagation_Mode,
        PA.AD_specialProcessing,
        PA.AD_ID
    FROM T_Predefined_Analysis PA INNER JOIN
         T_Organisms Org ON PA.AD_organism_ID = Org.Organism_ID
    WHERE (PA.AD_enabled > 0)
        AND ((@InstrumentClass         LIKE PA.AD_instrumentClassCriteria) OR (PA.AD_instrumentClassCriteria = ''))
        AND ((@InstrumentName          LIKE PA.AD_instrumentNameCriteria)  OR (PA.AD_instrumentNameCriteria = ''))
        AND (NOT (@InstrumentName      LIKE PA.AD_instrumentExclCriteria)  OR (PA.AD_instrumentExclCriteria = ''))
        AND ((@Campaign                LIKE PA.AD_campaignNameCriteria)    OR (PA.AD_campaignNameCriteria = ''))
        AND (NOT (@Campaign            LIKE PA.AD_campaignExclCriteria)    OR (PA.AD_campaignExclCriteria = ''))
        AND ((@Experiment              LIKE PA.AD_experimentNameCriteria)  OR (PA.AD_experimentNameCriteria = ''))
        AND (NOT (@Experiment          LIKE PA.AD_experimentExclCriteria)  OR (PA.AD_experimentExclCriteria = ''))
        AND ((@ExperimentComment       LIKE PA.AD_expCommentCriteria)      OR (PA.AD_expCommentCriteria = ''))
        AND ((@Dataset                 LIKE PA.AD_datasetNameCriteria)     OR (PA.AD_datasetNameCriteria = ''))
        AND (NOT (@Dataset             LIKE PA.AD_datasetExclCriteria)     OR (PA.AD_datasetExclCriteria = ''))
        AND ((@DatasetType             LIKE PA.AD_datasetTypeCriteria)     OR (PA.AD_datasetTypeCriteria = ''))
        AND ((@ScanTypes               LIKE PA.AD_scanTypeCriteria)        OR (PA.AD_scanTypeCriteria = ''))
        AND (NOT (@ScanTypes           LIKE PA.AD_scanTypeExclCriteria)    OR (PA.AD_scanTypeExclCriteria = ''))
        AND ((@ExperimentLabelling     LIKE PA.AD_labellingInclCriteria)   OR (PA.AD_labellingInclCriteria = ''))
        AND (NOT (@ExperimentLabelling LIKE PA.AD_labellingExclCriteria)   OR (PA.AD_labellingExclCriteria = ''))
        AND ((@SeparationType          LIKE PA.AD_separationTypeCriteria)  OR (PA.AD_separationTypeCriteria = ''))
        AND ((@Organism                LIKE PA.AD_organismNameCriteria)    OR (PA.AD_organismNameCriteria = ''))
        AND (
              -- Note that we always create jobs for predefines with Trigger_Before_Disposition = 1
              -- Procedure schedule_predefined_analysis_jobs will typically be called with @PreventDuplicateJobs = 1 so duplicate jobs will not get created after a dataset is reviewed
             (PA.Trigger_Before_Disposition = 1) OR
             (@Rating <> -10 AND PA.Trigger_Before_Disposition = 0) OR
             (@outputType = 'Show Rules')
            )
        AND (@AnalysisToolNameFilter = '' Or PA.AD_analysisToolName LIKE @AnalysisToolNameFilter)
        AND ((PA.AD_scanCountMinCriteria <= 0 AND PA.AD_scanCountMaxCriteria <= 0) OR
             (@ScanCount Between PA.AD_scanCountMinCriteria and PA.AD_scanCountMaxCriteria))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Could not load temporary criteria table'
        goto done
    End
    --
    If @myRowCount = 0
    Begin
        Set @message = 'No rules found'
        If @Rating = -10
            Set @message = @message + ' (dataset is unreviewed)'

        If @outputType = 'Show Rules' Or @OutputType = 'Show Jobs'
        Begin
            SELECT @datasetName AS Dataset, 'No matching rules were found' as Message
            --
            goto Done
        End

        goto done
    End

    If @outputType = 'Show Rules'
    Begin
        INSERT INTO #RuleEval (
            [Level], [Seq.], Predefine_ID, [Next Lvl.], [Trigger Mode], [Export Mode],
            [Action], [Reason],
            [Notes], [Analysis Tool],
            [Instrument Class Crit.], [Instrument Crit.], [Instrument Exclusion],
            [Campaign Crit.], [Campaign Exclusion],
            [Experiment Crit.], [Experiment Exclusion],
            [Organism Crit.],
            [Dataset Crit.], [Dataset Exclusion],
            [Dataset Type],
            [Scan Type Crit.], [Scan Type Exclusion],
            [Exp. Comment Crit.],
            [Labelling Incl.], [Labelling Excl.],
            [Separation Type Crit.],
            [ScanCount Min], [ScanCount Max],
            [Param File], [Settings File],
            Organism,
            [Prot. Coll.], [Prot. Opts.],
            [Organism DB],
            [Special Proc.],
            Priority, [Processor Group])
        SELECT  AD_level, AD_sequence, AD_ID, AD_nextLevel,
                CASE WHEN Trigger_Before_Disposition = 1
                     THEN 'Before Disposition'
                     ELSE 'Normal'
                     END AS [Trigger Mode],
                CASE Propagation_Mode WHEN 0
                     THEN 'Export'
                     ELSE 'No Export'
                     END AS [Export Mode],
                'Skip' AS [Action], 'Level skip' AS [Reason],
                '' AS [Notes], AD_analysisToolName,
                AD_instrumentClassCriteria, AD_instrumentNameCriteria, AD_instrumentExclCriteria,
                AD_campaignNameCriteria, AD_campaignExclCriteria,
                AD_experimentNameCriteria, AD_experimentExclCriteria,
                AD_organismNameCriteria,
                AD_datasetNameCriteria, AD_datasetExclCriteria,
                AD_datasetTypeCriteria,
                AD_scanTypeCriteria, AD_scanTypeExclCriteria,
                AD_expCommentCriteria,
                AD_labellingInclCriteria, AD_labellingExclCriteria,
                AD_separationTypeCriteria,
                AD_scanCountMin, AD_scanCountMax,
                AD_paramFileName, AD_settingsFileName,
                AD_organismName,
                AD_proteinCollectionList, AD_proteinOptionsList,
                AD_organismDBName,
                Special_Processing,
                AD_priority, '' AS [Processor Group]
        FROM #AD
        ORDER BY AD_level, AD_Sequence, AD_ID

    End

    ---------------------------------------------------
    ---------------------------------------------------
    -- Job Creation / Rule Evaluation Section
    ---------------------------------------------------
    ---------------------------------------------------

    ---------------------------------------------------
    -- Get current number of jobs for dataset
    ---------------------------------------------------
    Declare @numJobs int = 0
    --
    SELECT @numJobs = COUNT(*)
    FROM T_Analysis_Job
    WHERE AJ_datasetID = @ID

    ---------------------------------------------------
    -- Get list of jobs to create
    ---------------------------------------------------

    ---------------------------------------------------
    -- Temporary table to hold created jobs
    ---------------------------------------------------

    CREATE TABLE #JB (
        dataset varchar(128),
        priority varchar(8),
        analysisToolName varchar(64),
        paramFileName varchar(255),
        settingsFileName varchar(128),
        organismName varchar(128),
        proteinCollectionList varchar(4000),
        proteinOptionsList varchar(256),
        organismDBName varchar(128),
        ownerUsername varchar(128),
        comment varchar(128),
        associatedProcessorGroup varchar(64),
        numJobs int,
        propagationMode tinyint,
        specialProcessing varchar(512),
        predefineID int
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Could not create temporary job table'
        goto done
    End

    ---------------------------------------------------
    -- Cycle through all rules in the holding table
    -- in evaluation order applying precedence rules
    -- and creating jobs as appropriate
    ---------------------------------------------------

    Declare @level int
    Declare @sequence int
    Declare @RuleNextLevel int

    Declare @priority int
    Declare @paramFileName varchar(255)
    Declare @settingsFileName varchar(255)

    Declare @proteinCollectionList varchar(4000)
    Declare @proteinOptionsList varchar(256)

    Declare @proteinCollectionListValidated varchar(4000)

    Declare @analysisToolName varchar(64)
    Declare @organismName varchar(128)
    Declare @organismDBName varchar(128)

    Declare @comment varchar(128)
    Declare @associatedProcessorGroup varchar(64)
    Declare @predefineRuleID int
    Declare @TriggerBeforeDisposition tinyint
    Declare @PropagationMode tinyint
    Declare @SpecialProcessing varchar(512)

    Declare @ownerUsername varchar(32)

    Declare @tmpPriority int
    Declare @tmpProcessorGroupID int
    Declare @SchedulingRulesID int

    Declare @result int
    Declare @Continue int

    Declare @jobsCreated int = 0

    Declare @minLevel int  = 0

    Declare @UseRule tinyint
    Declare @RuleAction varchar(64)
    Declare @RuleActionReason varchar(256)
    Declare @RuleEvalNotes varchar(256)

    ---------------------------------------------------
    -- cycle through all the rules in the holding table
    ---------------------------------------------------
    Set @Continue = 1
    While @Continue > 0 and @myError = 0
    Begin -- <a>
        ---------------------------------------------------
        -- get next evaluation rule    from holding table
        ---------------------------------------------------
        SELECT TOP 1
            @analysisToolName = AD_analysisToolName,
            @paramFileName = AD_paramFileName,
            @settingsFileName = AD_settingsFileName,
            @organismName = AD_organismName,
            @proteinCollectionList = AD_proteinCollectionList,
            @proteinOptionsList = AD_proteinOptionsList,
            @organismDBName = AD_organismDBName,
            @priority = AD_priority,
            @RuleNextLevel = AD_nextLevel,
            @associatedProcessorGroup = '',
            @predefineRuleID = AD_ID,
            @TriggerBeforeDisposition = Trigger_Before_Disposition,
            @PropagationMode = Propagation_Mode,
            @SpecialProcessing = Special_Processing
        FROM #AD
        WHERE AD_level >= @minLevel
        ORDER BY AD_level, AD_Sequence, AD_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Could not create temporary job table'
            goto done
        End

        Set @Continue = @myRowCount

        ---------------------------------------------------
        -- remove the rule from the holding table
        ---------------------------------------------------
        DELETE FROM #AD WHERE AD_ID = @predefineRuleID

        If @Continue <> 0
        Begin -- <b>

            Set @UseRule = 1
            Set @RuleAction = 'Use'
            Set @RuleActionReason = 'Pass filters'
            Set @RuleEvalNotes = ''

            ---------------------------------------------------
            -- Validate that @DatasetType is appropriate for this analysis tool
            ---------------------------------------------------
            --
            If Not Exists (
                SELECT *
                FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
                     INNER JOIN T_Analysis_Tool Tool
                     ON ADT.Analysis_Tool_ID = Tool.AJT_toolID
                WHERE Tool.AJT_toolName = @analysisToolName AND
                      ADT.Dataset_Type = @DatasetType
                )
            Begin
                -- Dataset type is not allowed for this tool
                Set @UseRule = 0
                Set @RuleAction = 'Skip'
                Set @RuleActionReason = 'Dataset type "' + @DatasetType + '" is not allowed for analysis tool'
            End

            If @UseRule = 1
            Begin
                If @Rating = -10 And @TriggerBeforeDisposition = 0
                Begin
                    Set @RuleAction = 'Skip'
                    Set @RuleActionReason = 'Dataset is unreviewed'
                    Set @UseRule = 0
                End

            End

            If @UseRule = 1
            Begin -- <c>

                ---------------------------------------------------
                -- Evaluate rule precedence
                ---------------------------------------------------

                -- If there is a next level value for rule,
                -- Set minimum level to it
                --
                If @RuleNextLevel IS NOT NULL
                Begin
                    Set @minLevel = @RuleNextLevel
                    If Len(@RuleEvalNotes) > 0
                        Set @RuleEvalNotes = @RuleEvalNotes + '; '
                    Set @RuleEvalNotes = @RuleEvalNotes + 'Next rule must have level >= ' + Convert(varchar(12), @RuleNextLevel)
                End

                ---------------------------------------------------
                -- Override priority and/or assigned processor
                -- according to first scheduling rule in the evaluation
                -- sequence that applies to job being created
                ---------------------------------------------------

                Set @SchedulingRulesID = 0
                SELECT TOP 1
                    @tmpPriority = SR_priority,
                    @tmpProcessorGroupID = SR_processorGroupID,
                    @SchedulingRulesID = ID
                FROM T_Predefined_Analysis_Scheduling_Rules
                WHERE
                    (SR_enabled > 0) AND
                    (@InstrumentClass LIKE SR_instrumentClass   OR SR_instrumentClass = '') AND
                    (@InstrumentName LIKE SR_instrument_Name    OR SR_instrument_Name = '') AND
                    (@datasetName LIKE SR_dataset_Name          OR SR_dataset_Name = '') AND
                    (@analysisToolName LIKE SR_analysisToolName OR SR_analysisToolName = '')
                ORDER BY SR_evaluationOrder
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    Set @message = 'Unable to look up scheduling rule'
                    goto done
                End
                --
                If @myRowCount = 1
                Begin -- <d>
                    Set @priority = @tmpPriority
                    If IsNull(@tmpProcessorGroupID, 0) > 0
                    Begin
                        SELECT @associatedProcessorGroup = Group_Name
                        FROM dbo.T_Analysis_Job_Processor_Group
                        WHERE (ID = @tmpProcessorGroupID)

                        Set @associatedProcessorGroup = IsNull(@associatedProcessorGroup, '')
                    End
                    Else
                        Set @associatedProcessorGroup = ''

                    If Len(@RuleEvalNotes) > 0
                        Set @RuleEvalNotes = @RuleEvalNotes + '; '
                    Set @RuleEvalNotes = @RuleEvalNotes + 'Priority Set to ' + Convert(varchar(12), @priority)

                    If Len(@associatedProcessorGroup) > 0
                        Set @RuleEvalNotes = @RuleEvalNotes + ' and processor group Set to "' + @associatedProcessorGroup + '"'

                    Set @RuleEvalNotes = @RuleEvalNotes + ' due to ID ' + Convert(varchar(12), @SchedulingRulesID) + ' in T_Predefined_Analysis_Scheduling_Rules'
                End -- </d>


                ---------------------------------------------------
                -- Define the comment and job owner
                ---------------------------------------------------
                --
                Set @comment = 'Auto predefined ' + convert(varchar(10), @predefineRuleID)
                Set @ownerUsername = 'H09090911' -- autouser

                ---------------------------------------------------
                -- Possibly auto-add the Mini Proteome or Enzyme-related protein collections to @proteinCollectionList
                ---------------------------------------------------
                --
                Set @proteinCollectionListValidated = LTrim(RTrim(IsNull(@proteinCollectionList, '')))
                If Len(@proteinCollectionListValidated) > 0 And dbo.validate_na_parameter(@proteinCollectionListValidated, 1) <> 'na'
                Begin
                    exec @result = validate_protein_collection_list_for_datasets
                                        @datasetName,
                                        @protCollNameList=@proteinCollectionListValidated output,
                                        @ShowMessages=@RaiseErrorMessages,
                                        @message=@message output

                    If @result <> 0
                    Begin
                        Set @message = 'Protein Collection list validation error: ' + @message

                        If @RaiseErrorMessages <> 0
                        Begin
                            Set @msg = Replace(@message, '%', '%%')
                            RAISERROR (@msg, 10, 1)
                            Return @result
                        End
                        Else
                        Begin
                            -- Error occurred; just use @proteinCollectionList as-is, but update the comment
                            Set @proteinCollectionListValidated = LTrim(RTrim(IsNull(@proteinCollectionList, '')))
                            Set @comment = @comment + '; ' + @message
                        End
                    End

                    Set @message = ''
                End


                ---------------------------------------------------
                -- Insert job in job holding table
                ---------------------------------------------------
                --
                -- Note that add_update_analysis_job will call validate_analysis_job_parameters to validate this data
                --
                Set @jobsCreated = @jobsCreated + 1
                --
                INSERT INTO #JB (
                    dataset,
                    priority,
                    analysisToolName,
                    paramFileName,
                    settingsFileName,
                    organismName,
                    proteinCollectionList,
                    proteinOptionsList,
                    organismDBName,
                    ownerUsername,
                    comment,
                    associatedProcessorGroup,
                    numJobs,
                    propagationMode,
                    specialProcessing,
                    predefineID
                ) VALUES (
                    @datasetName,
                    @priority,
                    @analysisToolName,
                    @paramFileName,
                    @settingsFileName,
                    @organismName,
                    @proteinCollectionListValidated,
                    @proteinOptionsList,
                    @organismDBName,
                    @ownerUsername,
                    @comment,
                    @associatedProcessorGroup,
                    @numJobs,
                    @PropagationMode,
                    @SpecialProcessing,
                    @predefineRuleID
                )
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    Set @message = 'Could not insert job'
                    goto done
                End
            End -- </c>

            If @outputType = 'Show Rules'
            Begin
                UPDATE #RuleEval
                SET [Action] = @RuleAction,
                    [Reason] = @RuleActionReason,
                    [Notes] = @RuleEvalNotes,
                    Priority = @priority,
                    [Processor Group] = @associatedProcessorGroup
                WHERE Predefine_ID  = @predefineRuleID
            End
        End -- </b>

    End -- </a>

    If @myError = 0 and @jobsCreated = 0
    Begin
        ---------------------------------------------------
        -- We didn't schedule any jobs, but didn't have any errors;
        -- this is OK
        ---------------------------------------------------

        Set @myError = 0
    End

    ---------------------------------------------------
    -- If mode is show rules, return list of rules and exit
    ---------------------------------------------------
    If @outputType = 'Show Rules'
    Begin
        SELECT [Step] AS step,
               [Level] AS [level],
               [Seq.] AS seq,
               Predefine_ID AS predefine_id,
               [Next Lvl.] AS next_lvl,
               [Trigger Mode] AS trigger_mode,
               [Export Mode] AS export_mode,
               [Action] AS [action],
               [Reason] AS reason,
               [Notes] AS notes,
               [Analysis Tool] AS analysis_tool,
               [Instrument Class Crit.] AS instrument_class_criteria,
               [Instrument Crit.] AS instrument_criteria,
               [Instrument Exclusion] AS instrument_exclusion,
               [Campaign Crit.] AS campaign_criteria,
               [Campaign Exclusion] AS campaign_exclusion,
               [Experiment Crit.] AS experiment_criteria,
               [Experiment Exclusion] AS experiment_exclusion,
               [Organism Crit.] AS organism_criteria,
               [Dataset Crit.] AS dataset_criteria,
               [Dataset Exclusion] AS dataset_exclusion,
               [Dataset Type] AS dataset_type,
               [Scan Type Crit.] AS scan_type_criteria,
               [Scan Type Exclusion] AS scan_type_exclusion,
               [Exp. Comment Crit.] AS exp_comment_criteria,
               [Labelling Incl.] AS labelling_inclusion,
               [Labelling Excl.] AS labelling_exclusion,
               [Separation Type Crit.] AS separation_type_criteria,
               [ScanCount Min] AS scan_count_min,
               [ScanCount Max] AS scan_count_max,
               [Param File] AS param_file,
               [Settings File] AS settings_file,
               Organism AS organism,
               [Prot. Coll.] AS protein_collections,
               [Prot. Opts.] AS protein_options,
               [Organism DB] AS organism_db,
               [Special Proc.] AS special_processing,
               Priority AS priority,
               [Processor Group] AS processor_group
        FROM #RuleEval
        ORDER BY [Step]

        --
        goto Done
    End

    ---------------------------------------------------
    -- If mode is 'Show Jobs', return list of jobs
    -- in holding table and exit
    ---------------------------------------------------
    If @outputType = 'Show Jobs'
    Begin
        SELECT
            'Entry' AS job,
            predefineID AS predefine_id,
            dataset,
            numJobs AS jobs,
            analysisToolName AS tool,
            priority AS pri,
            comment AS comment,
            paramFileName AS param_file,
            settingsFileName AS settings_file,
            organismName AS organism,
            proteinCollectionList AS protein_collections,
            proteinOptionsList AS protein_options,
            organismDBName AS organism_db_name,
            specialProcessing AS special_processing,
            ownerUsername AS owner,
            CASE propagationMode WHEN 0 THEN 'Export' ELSE 'No Export' END AS export_mode
        FROM #JB
        --
        goto Done
    End

    ---------------------------------------------------
    -- If mode is 'Export Jobs', copy jobs to
    -- caller's job table
    ---------------------------------------------------

    If @outputType = 'Export Jobs'
    Begin
        INSERT INTO #JX (
            predefine_id,
            dataset,
            priority,
            analysisToolName,
            paramFileName,
            settingsFileName,
            organismName,
            proteinCollectionList,
            proteinOptionsList,
            organismDBName,
            ownerUsername,
            comment,
            associatedProcessorGroup,
            numJobs,
            propagationMode,
            specialProcessing
        )
        SELECT
            predefineID,
            dataset,
            priority,
            analysisToolName,
            paramFileName,
            settingsFileName,
            organismName,
            proteinCollectionList,
            proteinOptionsList,
            organismDBName,
            ownerUsername,
            comment,
            associatedProcessorGroup,
            numJobs,
            propagationMode,
            specialProcessing
         FROM #JB
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[evaluate_predefined_analysis_rules] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[evaluate_predefined_analysis_rules] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[evaluate_predefined_analysis_rules] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[evaluate_predefined_analysis_rules] TO [Limited_Table_Write] AS [dbo]
GO

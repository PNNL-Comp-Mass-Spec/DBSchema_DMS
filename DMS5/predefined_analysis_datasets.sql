/****** Object:  StoredProcedure [dbo].[predefined_analysis_datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[predefined_analysis_datasets]
/****************************************************
**
**  Desc:   Shows datasets that satisfy a given predefined analysis rule
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   06/22/2005
**          03/03/2006 mem - Fixed bug involving evaluation of @datasetNameCriteria
**          08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**          09/04/2009 mem - Added DatasetType filter
**                         - Added parameters @InfoOnly and @previewSql
**          05/03/2012 mem - Added parameter @PopulateTempTable
**          07/26/2016 mem - Now include Dataset Rating
**          08/04/2016 mem - Fix column name for dataset Rating ID
**          03/17/2017 mem - Include job, parameter file, settings file, etc. for the predefines that would run for the matching datasets
**          04/21/2017 mem - Add AD_instrumentNameCriteria
**          06/30/2022 mem - Rename parameter file argument
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/25/2023 bcg - Update output table column names to lower-case
**
*****************************************************/
(
    @ruleID int,
    @message varchar(512)='' output,
    @infoOnly tinyint = 0,              -- When 1, then returns the count of the number of datasets, not the actual datasets
    @previewSql tinyint = 0,
    @populateTempTable tinyint = 0      -- When 1, then populates table T_Tmp_PredefinedAnalysisDatasets with the results
)
AS
    set nocount on

    Declare @myError int
    set @myError = 0

    Declare @myRowCount int
    set @myRowCount = 0

    Declare @instrumentClassCriteria varchar(1024)
    Declare @campaignNameCriteria varchar(1024)
    Declare @experimentNameCriteria varchar(1024)

    Declare @instrumentNameCriteria varchar(1024)
    Declare @instrumentExclCriteria varchar(1024)

    Declare @organismNameCriteria varchar(1024)
    Declare @labellingInclCriteria varchar(1024)
    Declare @labellingExclCriteria varchar(1024)
    Declare @datasetNameCriteria varchar(1024)
    Declare @datasetTypeCriteria varchar(64)
    Declare @experimentCommentCriteria varchar(1024)

    Declare @separationTypeCriteria varchar(64)
    Declare @campaignExclCriteria varchar(128)
    Declare @experimentExclCriteria varchar(128)
    Declare @datasetExclCriteria varchar(128)

    Declare @analysisToolName varchar(64)
    Declare @paramFileName varchar(255)
    Declare @settingsFileName varchar(255)
    Declare @proteinCollectionList varchar(512)
    Declare @organismDBName varchar(128)

    Declare @S varchar(max)
    Declare @SqlWhere varchar(max)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @ruleID = IsNull(@ruleID, 0)
    Set @InfoOnly = IsNull(@InfoOnly, 0)
    Set @previewSql = IsNull(@previewSql, 0)
    set @PopulateTempTable = IsNull(@PopulateTempTable, 0)
    set @message = ''


    If @PopulateTempTable <> 0
    Begin
        If Exists (Select * from sys.tables where name = 'T_Tmp_PredefinedAnalysisDatasets')
            Drop Table T_Tmp_PredefinedAnalysisDatasets
    End


    SELECT
        @instrumentClassCriteria = AD_instrumentClassCriteria,
        @campaignNameCriteria = AD_campaignNameCriteria,
        @experimentNameCriteria = AD_experimentNameCriteria,
        @instrumentNameCriteria = AD_instrumentNameCriteria,
        @instrumentExclCriteria = AD_instrumentExclCriteria,
        @organismNameCriteria = AD_organismNameCriteria,
        @labellingInclCriteria = AD_labellingInclCriteria,
        @labellingExclCriteria = AD_labellingExclCriteria,
        @datasetNameCriteria = AD_datasetNameCriteria,
        @datasetTypeCriteria = AD_datasetTypeCriteria,
        @experimentCommentCriteria = AD_expCommentCriteria,
        @separationTypeCriteria = AD_separationTypeCriteria,
        @campaignExclCriteria = AD_campaignExclCriteria,
        @experimentExclCriteria = AD_experimentExclCriteria,
        @datasetExclCriteria = AD_datasetExclCriteria,
        @analysisToolName = AD_analysisToolName,
        @paramFileName = AD_parmFileName,
        @settingsFileName = AD_settingsFileName,
        @proteinCollectionList = AD_proteinCollectionList,
        @organismDBName = AD_organismDBName
    FROM T_Predefined_Analysis
    WHERE (AD_ID = @ruleID )

/*
    print 'InstrumentClass: ' + @instrumentClassCriteria
    print 'CampaignName: ' + @campaignNameCriteria
    print 'Experiment: ' + @experimentNameCriteria
    print 'InstrumentName: ' + @instrumentNameCriteria
    print 'InstrumentExcl: ' + @instrumentExclCriteria
    print 'OrganismName: ' + @organismNameCriteria
    print 'LabellingIncl: ' + @labellingInclCriteria
    print 'LabellingExcl: ' + @labellingExclCriteria
    print 'DatasetName: ' + @datasetNameCriteria
    print 'DatasetType: ' + @datasetTypeCriteria
    print 'ExperimentComment: ' + @experimentCommentCriteria
    print 'SeparationType: ' + @separationTypeCriteria
    print 'CampaignExcl: ' + @campaignExclCriteria
    print 'ExperimentExcl: ' + @experimentExclCriteria
    print 'DatasetExcl: ' + @datasetExclCriteria
*/

    Set @S = ''

    Set @SqlWhere = 'WHERE 1=1'

    If @instrumentClassCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (InstrumentClass LIKE ''' + @instrumentClassCriteria + ''')'

    If @instrumentNameCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Instrument LIKE ''' + @instrumentNameCriteria + ''')'

    If @instrumentExclCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (NOT Instrument LIKE ''' + @instrumentExclCriteria + ''')'

    If @campaignNameCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Campaign LIKE ''' + @campaignNameCriteria + ''')'

    If @experimentNameCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Experiment LIKE ''' + @experimentNameCriteria + ''')'

    If @labellingInclCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Experiment_Labelling LIKE ''' + @labellingInclCriteria + ''')'

    If @labellingExclCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (NOT Experiment_Labelling LIKE ''' + @labellingExclCriteria + ''')'

    If @separationTypeCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Separation_Type LIKE ''' + @separationTypeCriteria + ''')'

    If @campaignExclCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (NOT Campaign LIKE ''' + @campaignExclCriteria + ''')'

    If @experimentExclCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (NOT Experiment LIKE ''' + @experimentExclCriteria + ''')'

    If @datasetExclCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (NOT Dataset LIKE ''' + @datasetExclCriteria + ''')'

    If @organismNameCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Organism LIKE ''' + @organismNameCriteria + ''')'

    If @datasetNameCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Dataset LIKE ''' + @datasetNameCriteria + ''')'

    If @datasetTypeCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Dataset_Type LIKE ''' + @datasetTypeCriteria + ''')'

    If @experimentCommentCriteria <> ''
        Set @SqlWhere = @SqlWhere + ' AND (Experiment_Comment LIKE ''' + @experimentCommentCriteria + ''')'


    If @InfoOnly = 0
    Begin
        Set @S = @S + ' SELECT Dataset AS dataset, ID AS id,'
        Set @S = @S +        ' InstrumentClass AS instrument_class, Instrument AS instrument,'
        Set @S = @S +        ' Campaign AS campaign, Experiment AS experiment, Organism AS organism,'
        Set @S = @S +        ' Experiment_Labelling As exp_labelling, Experiment_Comment As exp_comment,'
        Set @S = @S +        ' Dataset_Comment As ds_comment, Dataset_Type As ds_type,'
        Set @S = @S +        ' Rating As ds_rating, Rating_Name AS rating,'
        Set @S = @S +        ' Separation_Type As sep_type,'
        Set @S = @S +        ' ''' + @analysisToolName + ''' AS tool,'
        Set @S = @S +        ' ''' + @paramFileName + ''' AS parameter_file,'
        Set @S = @S +        ' ''' + @settingsFileName + ''' AS settings_file,'
        Set @S = @S +        ' ''' + @proteinCollectionList + ''' AS protein_collections,'
        Set @S = @S +        ' ''' + @organismDBName + ''' AS legacy_fasta'
        If @PopulateTempTable <> 0
            Set @S = @S + ' INTO T_Tmp_PredefinedAnalysisDatasets'
        Set @S = @S + ' FROM V_Predefined_Analysis_Dataset_Info'
        Set @S = @S + ' ' + @SqlWhere
        Set @S = @S + ' ORDER BY ID DESC'
    End
    Else
    Begin
        Set @S = @S + ' SELECT ' + Convert(varchar(12), @ruleID) + ' AS RuleID,'
        Set @S = @S +          ' COUNT(*) AS DatasetCount,'
        Set @S = @S +          ' MIN(DS_Date) AS Dataset_Date_Min, MAX(DS_Date) AS Dataset_Date_Max, '

        Set @S = @S +          ' ''' + @instrumentClassCriteria +   ''' AS InstrumentClassCriteria,'
        Set @S = @S +          ' ''' + @instrumentNameCriteria +    ''' AS InstrumentNameCriteria,'
        Set @S = @S +          ' ''' + @instrumentExclCriteria +    ''' AS InstrumentExclCriteria,'

        Set @S = @S +          ' ''' + @campaignNameCriteria +      ''' AS CampaignNameCriteria,'
        Set @S = @S +          ' ''' + @campaignExclCriteria +      ''' AS CampaignExclCriteria,'

        Set @S = @S +          ' ''' + @experimentNameCriteria +    ''' AS ExperimentNameCriteria,'
        Set @S = @S +          ' ''' + @experimentExclCriteria +    ''' AS ExperimentExclCriteria,'

        Set @S = @S +          ' ''' + @organismNameCriteria +      ''' AS OrganismNameCriteria,'

        Set @S = @S +          ' ''' + @datasetNameCriteria +       ''' AS DatasetNameCriteria,'
        Set @S = @S +          ' ''' + @datasetExclCriteria +       ''' AS DatasetExclCriteria,'
        Set @S = @S +          ' ''' + @datasetTypeCriteria +       ''' AS DatasetTypeCriteria,'

        Set @S = @S +          ' ''' + @experimentCommentCriteria + ''' AS ExpCommentCriteria,'
        Set @S = @S +          ' ''' + @labellingInclCriteria +     ''' AS LabellingInclCriteria,'
        Set @S = @S +          ' ''' + @labellingExclCriteria +     ''' AS LabellingExclCriteria,'
        Set @S = @S +          ' ''' + @separationTypeCriteria +    ''' AS SeparationTypeCriteria'

        Set @S = @S + ' FROM V_Predefined_Analysis_Dataset_Info'
        Set @S = @S + ' ' + @SqlWhere
    End

    If @PopulateTempTable <> 0 And @previewSql = 0
        Select 'Populating table T_Tmp_PredefinedAnalysisDatasets' as Message

    If @previewSql = 0
        Exec (@S)
    Else
        Print @S

    If @PopulateTempTable <> 0 And @previewSql = 0
    Begin
        CREATE INDEX IX_T_Tmp_PredefinedAnalysisDatasets_Dataset_ID ON T_Tmp_PredefinedAnalysisDatasets (ID)
        Set @S = 'SELECT * FROM T_Tmp_PredefinedAnalysisDatasets'
        Exec (@S)
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[predefined_analysis_datasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[predefined_analysis_datasets] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[predefined_analysis_datasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[predefined_analysis_datasets] TO [Limited_Table_Write] AS [dbo]
GO

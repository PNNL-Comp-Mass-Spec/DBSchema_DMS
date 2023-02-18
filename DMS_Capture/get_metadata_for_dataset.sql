/****** Object:  StoredProcedure [dbo].[get_metadata_for_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_metadata_for_dataset]
/****************************************************
**
**  Desc:   Populate a temporary table with metadata for the given dataset
**
**  The calling procedure must create this temporary table:
**
**      CREATE TABLE #ParamTab
**      (
**          [Section] varchar(128),
**          [Name] varchar(128),
**          [Value] varchar(MAX)
**      )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/29/2009 grk - Initial release
**          11/03/2009 dac - Corrected name of dataset number column in global metadata
**          06/12/2018 mem - Now including Experiment_Labelling, Reporter_MZ_Min, and Reporter_MZ_Max
**          05/04/2020 mem - Add fields LC_Cart_Name, LC_Cart_Config, and LC_Column
**                         - Store dates in ODBC canonical style: yyyy-MM-dd hh:mm:ss
**          07/28/2020 mem - Add Dataset_ID
**          03/31/2021 mem - Expand @organismName to varchar(128)
**          02/03/2023 bcg - Use synonym S_DMS_V_DatasetFullDetails instead of view wrapping it
**          02/03/2023 bcg - Update column name for V_DMS_Get_Experiment_Metadata
**          02/09/2023 bcg - Update column name for S_DMS_V_DatasetFullDetails
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**                         - Rename/update several entries in the output XML (Cell_Culture to Biomaterial, PRN to Username, Num to Name)
**
*****************************************************/
(
    @datasetName varchar(128)
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Insert "global" metadata
    ---------------------------------------------------

    Declare @stepParmSectionName varchar(32) = 'Meta'

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Investigation', 'Proteomics')
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Instrument_Type', 'Mass spectrometer')

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_Name', @datasetName)

    ---------------------------------------------------
    -- Insert primary metadata for the dataset
    ---------------------------------------------------

    Declare @datasetCreated datetime
    Declare @datasetId int
    Declare @instrumentName varchar(50)
    Declare @datasetComment varchar(500)
    Declare @datasetSecSep varchar(64)

    Declare @lcCartName varchar(128)
    Declare @lcCartConfig varchar(128)
    Declare @lcColumn varchar(128)

    Declare @datasetWellNumber varchar(64)
    Declare @experimentName varchar(64)
    Declare @experimentResearcherUsername varchar(64)
    Declare @organismName varchar(128)
    Declare @experimentComment varchar(500)
    Declare @experimentSampleConc varchar(64)
    Declare @experimentLabelling varchar(64)
    Declare @labellingReporterMzMin float
    Declare @labellingReporterMzMax float
    Declare @labNotebook varchar(64)
    Declare @campaignName varchar(64)
    Declare @campaignProject varchar(64)
    Declare @campaignComment varchar(500)
    Declare @campaignCreated datetime
    Declare @experimentReason varchar(500)
    Declare @cellCultureList varchar(500)

    --
    SELECT @datasetCreated = DS_created,
           @datasetId = Dataset_ID,
           @instrumentName = IN_name,
           @datasetComment = DS_comment,
           @datasetSecSep = DS_sec_sep,
           @lcCartName = LC_Cart_Name,
           @lcCartConfig = LC_Cart_Config,
           @lcColumn = LC_Column,
           @datasetWellNumber = DS_well_num,
           @experimentName = Experiment_Num,
           @experimentResearcherUsername = EX_researcher_Username,
           @organismName = EX_organism_name,
           @experimentComment = EX_comment,
           @experimentSampleConc = EX_sample_concentration,
           @experimentLabelling = EX_Labelling,
           @labellingReporterMzMin = IsNull(Reporter_Mz_Min, 0),
           @labellingReporterMzMax = IsNull(Reporter_Mz_Max, 0),
           @labNotebook = EX_lab_notebook_ref,
           @campaignName = Campaign_Num,
           @campaignProject = CM_Project_Num,
           @campaignComment = CM_comment,
           @campaignCreated = CM_created,
           @experimentReason = EX_Reason,
           @cellCultureList = EX_cell_culture_list
    FROM S_DMS_V_DatasetFullDetails
    WHERE Dataset_Num = @datasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        -- Dataset not found
        Return 20000
    End

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_created', CONVERT(varchar(32), @datasetCreated, 120))
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_ID', CAST(@datasetId AS varchar(12)))

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Instrument_name', @instrumentName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_comment', @datasetComment)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_sec_sep', @datasetSecSep)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_LC_Cart_Name', @lcCartName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_LC_Cart_Config', @lcCartConfig)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_LC_Column', @lcColumn)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_well_number', @datasetWellNumber)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Name', @experimentName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_researcher_username', @experimentResearcherUsername)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Reason', @experimentReason)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Biomaterial', @cellCultureList)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_organism_name', @organismName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_comment', @experimentComment)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_sample_concentration', @experimentSampleConc)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_sample_labelling', @experimentLabelling)

    If @labellingReporterMzMin > 0
    Begin
        INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_labelling_reporter_mz_min', Cast(@labellingReporterMzMin As varchar(19)))
        INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_labelling_reporter_mz_max', Cast(@labellingReporterMzMax As varchar(19)))
    End

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_lab_notebook_ref', @labNotebook)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_Name', @campaignName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_Project_Name', @campaignProject)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_comment', @campaignComment)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_created', CONVERT(VARCHAR(32), @campaignCreated, 120))

    ---------------------------------------------------
    -- Insert auxiliary metadata for the dataset's experiment
    ---------------------------------------------------

    INSERT INTO #ParamTab ([Section], [Name], Value)
    SELECT @stepParmSectionName AS [Section], 'Meta_Aux_Info:' + Target + ':' + Category + '.' + Subcategory + '.' + Item AS [Name], [Value]
    FROM V_DMS_Get_Experiment_Metadata
    WHERE Experiment = @experimentName
    ORDER BY [Name]

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[get_metadata_for_dataset] TO [DDL_Viewer] AS [dbo]
GO

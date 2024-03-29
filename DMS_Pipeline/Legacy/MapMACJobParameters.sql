/****** Object:  StoredProcedure [dbo].[MapMACJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MapMACJobParameters]
/****************************************************
**
**  Desc:
**      Verify configuration and contents of a data package suitable for running a given MAC job from job template
**
**      Uses temp table #MACJobParams created by caller
**
**      Deprecated in December 2022 when procedure AddMACJob was deprecated (since the mac_jobs page family was deprecated)
**      
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/29/2012 grk - Initial release
**          11/01/2012 grk - eliminated job template
**          11/30/2012 jds - added support for Global Label-Free AMT Tag using MultiAlign
**          01/03/2013 mem - Updated spelling of Isobaric_Labeling
**          01/11/2013 mem - Now informing the user if the data package does not have any DeconTools jobs
**                         - Added support for data packages with a mix of DeconTools and other jobs
**          01/11/2013 jds - added support for using isos or LCMSfeatures for Global Label-Free AMT Tag
**          01/31/2013 mem - Renamed msgfplus to MSGF+
**                         - Now auto-defining AScoreSearchType
**          02/18/2013 mem - Now raising an error if @experimentLabelling is an empty string
**          08/13/2013 mem - Added support for the MAC_iTRAQ script using the Experiment_Labelling parameter
**                         - Fixed misspelled ApeWorflowStepList, changing to ApeWorkflowStepList
**                         - Now validating that 'Mass_Tag_Db' is defined and is valid
**                         - Added support for the Ape_Workflow_FDR parameter
**          08/30/2013 mem - Now using Ape_Workflow_FDR to update ApeWorkflowStepList (previously updated ApeWorkflowName)
**          01/11/2013 mem - Add TMT10Plex and mention MasterWorkflowSyn.xml
**          01/22/2021 mem - Add support for script MAC_TMT10Plex
**          07/01/2022 mem - Use new parameter name for parameter file when querying #MACJobParams
**          08/16/2022 mem - Deprecate scripts Global_Label-Free_AMT_Tag and Isobaric_Labeling
**
*****************************************************/
(
    @scriptName varchar(64) ,
    @jobParam VARCHAR(8000),
    @tool VARCHAR(64),            -- PSM analysis tool used by jobs in the data package; only used by scripts 'Isobaric_Labeling' and 'MAC_iTRAQ'
    @DataPackageID INT,
    @mode VARCHAR(12) = 'map',
    @message VARCHAR(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @debugMode tinyint = 0
    Declare @msg varchar(256)

    ---------------------------------------------------
    -- Map entry fields to table
    --
    -- @jobParam should be of the form:
    -- <Param Name="Experiment_Labelling" Value="8plex" /><Param Name="Ape_Workflow_FDR" Value="default" />
    ---------------------------------------------------

    Declare @entryValuesXML XML = CONVERT(XML, @jobParam)

    Declare @entryValues table (
        [Name] varchar(128),
        [Value] varchar(4000)
    )

    INSERT INTO @entryValues
        ([Name], Value)
    SELECT
        xmlNode.value('@Name', 'varchar(64)') as [Name],
        xmlNode.value('@Value', 'varchar(4000)') as [Value]
    FROM
        @entryValuesXML.nodes('//Param') AS R(xmlNode)

    ---------------------------------------------------
    -- set parameter values according to entry field values
    -- and mapping for template
    ---------------------------------------------------

    IF @scriptName LIKE 'MAC_iTRAQ%' OR
       @scriptName LIKE 'MAC_TMT%Plex'
       -- Deprecated: @scriptName LIKE 'Isobaric_Labeling%'
    BEGIN
        -- The user will have defined @experimentLabelling using the drop-down box at http://dms2.pnl.gov/mac_jobs/create
        -- The options are: 4plex (4-Plex Itraq), 6plex (6-Plex TMT), 8plex (8-plex Itraq), and TMT10Plex (10-plex TMT)
        -- The default option and the chooser to use is defined in the pipeline script itself
        --   See for example http://dms2.pnl.gov/pipeline_script/show/MAC_iTRAQ which uses chooser experimentLabellingPickList
        --   See chooser contents at http://dms2.pnl.gov/chooser/get_chooser_list

        --   Edit items using http://dmsdev.pnl.gov/config_db/edit_table/dms_chooser.db/chooser_definitions
        --   Chooser definition is {"4plex":"4-plex iTRAQ", "6plex":"6-plex TMT", "8plex":"8-plex iTRAQ", "TMT10Plex":"10-plex TMT"}

        -- The experiment labelling type is used to define which workflow steps will be executed in the Master Workflow file
        -- See \\gigasax\DMS_Workflows\Ape\Itraq\MasterWorkflowSyn.xml

        Declare @experimentLabelling VARCHAR(128) = ''
        SELECT @experimentLabelling = Value FROM @entryValues WHERE [Name]='Experiment_Labelling'

        Set @experimentLabelling = LTrim(RTrim(IsNull(@experimentLabelling, '')))
        If @experimentLabelling = ''
            RAISERROR('Experiment_Labelling parameter was not defined in the job parameters (typically 4plex, 6plex, 8plex, or TMT10Plex)', 11, 30)

        Declare @extractionType VARCHAR(128)

        -- Note that the tool names in this case statement are defined in stored procedure ValidateDataPackageForMACJob
        -- Even if DTARefinery was used, the tool name will be simply "sequest" or "msgfplus"
        --
        SELECT @extractionType = CASE
                                     WHEN @tool = 'sequest' THEN 'Sequest First Hits'
                                     WHEN @tool = 'msgfplus' THEN 'MSGF+ Synopsis All Proteins'
                                     ELSE '??'
                                 END

        IF @extractionType = '??'
        Begin
            Set @tool = IsNull(@tool, '')
            RAISERROR('Search tool "%s" not recognized', 11, 30, @tool)
        End

        Declare @AScoreSearchType VARCHAR(128)
        SELECT @AScoreSearchType = CASE
                                       WHEN @tool = 'sequest' THEN 'sequest'
                                       WHEN @tool = 'msgfplus' THEN 'msgfplus'
                                       ELSE '??'
                                   END

        Declare @apeWorkflowFDR VARCHAR(128) = ''
        SELECT @apeWorkflowFDR = Value FROM @entryValues WHERE [Name]='Ape_Workflow_FDR'

        Set @apeWorkflowFDR = LTrim(RTrim(IsNull(@apeWorkflowFDR, '')))
        If @apeWorkflowFDR = ''
            RAISERROR('Ape_Workflow_FDR parameter was not defined in the job parameters (typically default or 5percent)', 11, 30)

        Declare @FDRLevel varchar(16)
        SELECT @FDRLevel = CASE
                               WHEN @apeWorkflowFDR = '5percent' THEN '5pctFDR'
                               ELSE '1pctFDR'
                           END

        Declare @apeWorkflowStepList VARCHAR(256) = @tool + ', ' + @experimentLabelling + ', ' + @FDRLevel + ', default, no_ascore, no_precursor_filter, keep_nonquant'

        UPDATE #MACJobParams
        SET [Value] = @apeWorkflowStepList
        WHERE [Name] = 'ApeWorkflowStepList'

        UPDATE #MACJobParams
        SET [Value] = @extractionType
        WHERE [Name] = 'ExtractionType'

        UPDATE #MACJobParams
        SET [Value] = @AScoreSearchType
        WHERE [Name] = 'AScoreSearchType'

    END

    /*
     * Deprecated

    IF @scriptName IN ('Global_Label-Free_AMT_Tag')
    BEGIN
        -- The user will have defined 'Mass_Tag_Db' using the drop-down box at http://dms2.pnl.gov/mac_jobs/create
        -- The default option and the chooser to use is defined in the pipeline script itself
        --   See for example http://dms2.pnl.gov/pipeline_script/show/Global_Label-Free_AMT_Tag which uses chooser amtDBPicklist
        --   See chooser contents at http://dms2.pnl.gov/chooser/get_chooser_list
        --   Chooser definition is "SELECT DISTINCT MT_DB_Name AS val, MT_DB_Name AS ex FROM V_MTS_MT_DBs WHERE State_ID < 10"

        Declare @massTagDatabase VARCHAR(128) = ''
        SELECT @massTagDatabase = Value FROM @entryValues WHERE [Name]='Mass_Tag_Db'

        Set @massTagDatabase = LTrim(RTrim(IsNull(@massTagDatabase, '')))
        If @massTagDatabase = ''
            RAISERROR('Mass_Tag_Db parameter was not defined in the job parameters (choose a Mass Tag Database using the chooser when creating the job)', 11, 30)

        Declare @datasetType VARCHAR(128) = ''

        -- Lookup the most-commonly used dataset type for DeconTools jobs defined for this data package
        SELECT TOP 1 @datasetType = [Dataset Type]
        FROM ( SELECT DLR.[Dataset Type],
                      COUNT(*) AS Usage
               FROM S_Data_Package_Analysis_Jobs PkgJobs
                    INNER JOIN S_Data_Package_Datasets PkgDatasets
                      ON PkgJobs.Dataset = PkgDatasets.Dataset
                    INNER JOIN dbo.S_DMS_V_Dataset_List_Report_2 DLR
                      ON PkgDatasets.Dataset_ID = DLR.ID
               WHERE PkgJobs.Tool = 'Decon2LS_V2' AND
                     PkgJobs.Data_Package_ID = @DataPackageID
               GROUP BY DLR.[Dataset Type]
             ) LookupQ
        ORDER BY Usage DESC

        If @datasetType = ''
        Begin
            Set @msg = 'Data package ' + convert(varchar(12), @DataPackageID) + ' does not have any Decon2LS_V2 jobs associated with it. Add using http://dms2.pnl.gov/data_package/show/' + convert(varchar(12), @DataPackageID) + ' '
            RAISERROR(@msg, 11, 31)
        End

        Declare @paramFileName VARCHAR(128) = '??'
        SELECT @paramFileName = CASE
                                   WHEN @datasetType LIKE 'IMS%' THEN 'parametersHMS-IMS.xml'
          WHEN @datasetType LIKE 'HMS%' THEN 'parametersHMS-MS.xml'
                                   ELSE '??'
                               END

        IF @paramFileName = '??'
            RAISERROR('Dataset Type "%s" is not supported for %s analysis', 11, 32, @datasetType, @scriptName)

        Declare @multiAlignSearchType VARCHAR(128) = '??'
        SELECT @multiAlignSearchType = CASE
                                           WHEN @datasetType LIKE 'IMS%' THEN '_LCMSFeatures.txt'
                                           WHEN @datasetType LIKE 'HMS%' THEN '_isos.csv'
                                           ELSE '??'
                                       END

        IF @multiAlignSearchType = '??'
            RAISERROR('Dataset Type "%s" is not supported for %s analysis', 11, 32, @datasetType, @scriptName)

        UPDATE #MACJobParams
        SET [Value] = @paramFileName
        WHERE [Name] = 'ParamFileName'

        UPDATE #MACJobParams
        SET [Value] = @multiAlignSearchType
        WHERE [Name] = 'MultiAlignSearchType'

        Declare @amtDbServer VARCHAR(128)

        SELECT TOP 1 @amtDbServer = Server_Name
        FROM S_DMS_V_MTS_MT_DBs
        WHERE MT_DB_Name = @massTagDatabase
        ORDER BY MT_DB_ID Desc

        Set @amtDbServer = IsNull(@amtDbServer, '')
        If @amtDbServer = ''
        Begin
            Set @msg = 'Invalid Mass Tag database: ' + @massTagDatabase + '; unable to determine server hosting the database'
            RAISERROR(@msg, 11, 30)
        End

        UPDATE #MACJobParams
        SET [Value] = @massTagDatabase
        WHERE [Name] = 'AMTDB'

        UPDATE #MACJobParams
        SET [Value] = @amtDbServer
        WHERE [Name] = 'AMTDBServer'

    END

    */

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[MapMACJobParameters] TO [DDL_Viewer] AS [dbo]
GO

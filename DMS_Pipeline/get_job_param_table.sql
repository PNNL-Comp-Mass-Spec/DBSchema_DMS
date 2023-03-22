/****** Object:  StoredProcedure [dbo].[get_job_param_table] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_job_param_table]
/****************************************************
**
**  Desc:   Returns a table filled with the parameters for the
**          given job in Section/Name/Value rows.
**
**  Note:   This table of parameters comes from the DMS5 database, and
**          not from the T_Job_Parameters table local to this DB
**
**  Auth:   grk
**  Date:   08/21/2008 grk - Initial release
**          01/14/2009 mem - Increased maximum parameter length to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          04/10/2009 grk - Added DTA folder name override (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          06/02/2009 mem - Updated to run within the DMS_Pipeline DB and to use view V_DMS_PipelineJobParameters (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          07/29/2009 mem - Updated to look in T_Jobs.Comment for the 'DTA:' tag when 'ExternalDTAFolderName' is defined in the script
**          01/05/2010 mem - Added parameter @settingsFileOverride
**          02/23/2010 mem - Updated to not return any debug info using SELECT statements; required since create_parameters_for_job calls this SP using the notation: INSERT INTO ... exec get_job_param_table ...
**          04/04/2011 mem - Updated to support V_DMS_SettingsFiles returning true XML for the Contents column (using S_DMS_V_Get_Pipeline_Settings_Files)
**                         - Added support for field Special_Processing
**          04/20/2011 mem - Now calling check_add_special_processing_param to look for an AMTDB entry in the Special_Processing parameter
**                         - Additionally, adding parameter AMTDBServer if the AMTDB entry is present
**          08/01/2011 mem - Now filtering on Analysis_Tool when querying V_DMS_SettingsFiles
**          05/07/2012 mem - Now including DatasetType
**          05/07/2012 mem - Now including Experiment
**          08/23/2012 mem - Now calling check_add_special_processing_param to look for a DataImportFolder entry
**          04/23/2013 mem - Now including Instrument and InstrumentGroup
**          01/30/2014 mem - Now using S_DMS_V_Settings_File_Lookup when a match is not found in V_DMS_SettingsFiles for the given settings file and analysis tool
**          03/14/2014 mem - Added InstrumentDataPurged
**          12/12/2018 mem - Update comments and capitalization
**          04/11/2022 mem - Expand Section and Name to varchar(128)
**                         - Cast ProteinCollectionList to varchar(4000)
**          07/01/2022 mem - Rename job parameters to ParamFileName and ParamFileStoragePath
**          08/17/2022 mem - Remove reference to MTS view
**                           (previously looked for tag AMTDB in the Special_Processing field for MultiAlign jobs;
**                            given the AMT tag DB name, the code used a view to determine the server on which the MT DB resides)
**                         - Remove check for DataImportFolder in the Special_Processing field
**          02/01/2023 mem - Use new column names
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/21/2023 mem - Add job parameter DatasetName
**                         - Capitalize parameter LegacyFastaFileName
**
*****************************************************/
(
    @job int,
    @settingsFileOverride varchar(256) = '',    -- When defined, use this settings file name instead of the one obtained with V_DMS_PipelineJobParameters
    @debugMode tinyint = 0                        -- When non-zero, prints debug statements
)
AS
    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(512) = ''

    Set @settingsFileOverride = IsNull(@settingsFileOverride, '')
    Set @debugMode = IsNull(@debugMode, 0)

    ---------------------------------------------------
    -- Table variable to hold job parameters
    ---------------------------------------------------
    --
    CREATE TABLE #T_Tmp_ParamTab
    (
        [Step_Number] varchar(24),
        [Section] varchar(128),
        [Name] varchar(128),
        [Value] varchar(4000)
    )

    ---------------------------------------------------
    -- Get job parameters that are table columns
    -- Note that V_DMS_PipelineJobParameters uses S_DMS_V_Get_Pipeline_Job_Parameters which uses V_Get_Pipeline_Job_Parameters in DMS5
    ---------------------------------------------------
    --
    INSERT INTO #T_Tmp_ParamTab ([Step_Number], [Section], [Name], [Value])
    SELECT NULL as Step_Number, 'JobParameters' as [Section], TP.Name, TP.Value
    FROM
    (
        Select
          CAST(Dataset As varchar(4000))                        AS DatasetName,
          CAST(Dataset As varchar(4000))                        AS DatasetNum,              -- ToDo: Remove this after all analysis managers support DatasetName
          CAST(Dataset_ID As varchar(4000))                     AS DatasetID,
          CAST(Dataset_Folder_Name As varchar(4000))            AS DatasetFolderName,
          CAST(Archive_Folder_Path As varchar(4000))            AS DatasetArchivePath,
          CAST(Dataset_Storage_Path As varchar(4000))           AS DatasetStoragePath,
          CAST(Transfer_Folder_Path As varchar(4000))           AS transferFolderPath,
          CAST(Instrument_Data_Purged As varchar(4000))         AS InstrumentDataPurged,
          CAST(Param_File_Name As varchar(4000))                AS ParamFileName,
          CAST(Settings_File_Name As varchar(4000))             AS SettingsFileName,
          CAST(Special_Processing As varchar(4000))             AS Special_Processing,
          CAST(Param_File_Storage_Path As varchar(4000))        AS ParamFileStoragePath,     -- Storage path for the primary tool of the script
          CAST(Organism_DB_Name As varchar(4000))               AS LegacyFastaFileName,
          CAST(Protein_Collection_List As varchar(4000))        AS ProteinCollectionList,
          CAST(Protein_Options_List As varchar(4000))           AS ProteinOptions,
          CAST(Instrument_Class As varchar(4000))               AS InstClass,
          CAST(Instrument_Group As varchar(4000))               AS InstrumentGroup,
          CAST(Instrument As varchar(4000))                     AS Instrument,
          CAST(Raw_Data_Type As varchar(4000))                  AS RawDataType,
          CAST(Dataset_Type As varchar(4000))                   AS DatasetType,
          CAST(Experiment As varchar(4000))                     AS Experiment,
          CAST(Search_Engine_Input_File_Formats As varchar(4000))   AS SearchEngineInputFileFormats,
          CAST(Organism As varchar(4000))                       AS OrganismName,
          CAST(Org_DB_Required As varchar(4000))                AS OrgDbReqd,
          CAST(Tool_Name As varchar(4000))                      AS ToolName,
          CAST(Result_Type As varchar(4000))                    AS ResultType
        FROM V_DMS_PipelineJobParameters
        WHERE Job = @job
    ) TD
    UNPIVOT (Value For [Name] In (
        DatasetName,
        DatasetNum,             -- ToDo: Remove this after all analysis managers support DatasetName
        DatasetID,
        DatasetFolderName,
        DatasetStoragePath,
        DatasetArchivePath,
        transferFolderPath,
        InstrumentDataPurged,
        ParamFileName,
        SettingsFileName,
        Special_Processing,
        ParamFileStoragePath,
        LegacyFastaFileName,
        ProteinCollectionList,
        ProteinOptions,
        InstClass,
        InstrumentGroup,
        Instrument,
        RawDataType,
        DatasetType,
        Experiment,
        SearchEngineInputFileFormats,
        OrganismName,
        OrgDbReqd,
        ToolName,
        ResultType
    )) as TP
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Simulate section association for step tool
    ---------------------------------------------------
    --
    UPDATE #T_Tmp_ParamTab
    SET [Section] = 'PeptideSearch'
    WHERE [Name] in ('ParamFileName', 'ParamFileStoragePath', 'OrganismName',  'LegacyFastaFileName',  'ProteinCollectionList',  'ProteinOptions')

    ---------------------------------------------------
    -- Possibly override the settings file name
    ---------------------------------------------------
    --
    If @settingsFileOverride <> ''
    Begin
        UPDATE #T_Tmp_ParamTab
        SET [Value] = @settingsFileOverride
        WHERE [Name] = 'SettingsFileName'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount >= 1
        Begin
            If @debugMode <> 0
                Print 'Updated settings file to be "' + @settingsFileOverride
        End
        Else
        Begin
            INSERT INTO #T_Tmp_ParamTab ([Step_Number], [Section], [Name], [Value])
            SELECT    NULL as Step_Number,
                    'JobParameters' AS [Section],
                    'SettingsFileName' AS Name,
                    @settingsFileOverride AS Value

            If @debugMode <> 0
                Print 'Settings file was not defined; defined it to be "' + @settingsFileOverride
        End
    End

    ---------------------------------------------------
    -- Get settings file parameters from DMS
    ---------------------------------------------------
    --
    Declare @paramXML xml
    Declare @settingsFileName varchar(128)
    Declare @AnalysisToolName varchar(128)

    -- Lookup the settings file name
    --
    Set @settingsFileName = ''

    SELECT @settingsFileName = [Value]
    FROM #T_Tmp_ParamTab
    WHERE [Name] = 'SettingsFileName'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 Or @settingsFileName Is Null
    Begin
        Set @settingsFileName = 'na'

        If @debugMode <> 0
            Print 'Warning: Settings file was not defined in the job parameters; assuming "na"'
    End

    -- Lookup the analysis tool name
    --
    Set @AnalysisToolName = ''

    SELECT @AnalysisToolName = [Value]
    FROM #T_Tmp_ParamTab
    WHERE [Name] = 'ToolName'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 Or @AnalysisToolName Is Null
    Begin
        Set @AnalysisToolName = ''

        If @debugMode <> 0
            Print 'Warning: Analysis tool was not defined in the job parameters; may choose the wrong settings file (if files for different tools have the same name)'
    End

    -- Retrieve the settings file contents (as XML)
    --
    SELECT @paramXML = Contents
    FROM V_DMS_SettingsFiles
    WHERE File_Name = @settingsFileName AND
          (Analysis_Tool = @AnalysisToolName OR @AnalysisToolName = '')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        -- Settings file not found for tool @AnalysisToolName
        -- Try relaxing the tool name specification

        Declare @settingsFileNameMappedTool varchar(128)
        Declare @AnalysisToolNameMappedTool varchar(128)

        SELECT Top 1 @settingsFileNameMappedTool = File_Name,
                     @AnalysisToolNameMappedTool = Mapped_Tool
        FROM dbo.S_DMS_V_Settings_File_Lookup
        WHERE File_Name = @settingsFileName AND
              Analysis_Tool = @AnalysisToolName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If IsNull(@settingsFileNameMappedTool, '') = ''
        Begin
            Set @myRowCount = 0
        End
        Else
        Begin
            SELECT @paramXML = Contents
            FROM V_DMS_SettingsFiles
            WHERE File_Name = @settingsFileNameMappedTool AND
                  Analysis_Tool = @AnalysisToolNameMappedTool
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
    End

    If @myRowCount = 0
    Begin
        If @debugMode <> 0
            Print 'Warning: Settings file "' + @settingsFileName + '" not defined in V_DMS_SettingsFiles'
    End
    Else
    Begin
        If @debugMode <> 0
            Print 'XML for settings file "' + @settingsFileName + '": ' + Convert(varchar(max), @paramXML)

        INSERT INTO #T_Tmp_ParamTab
        SELECT
            xmlNode.value('../@id', 'varchar(50)') [Step_Number],
            xmlNode.value('../@name', 'varchar(128)') [Section],
            xmlNode.value('@key', 'varchar(128)') [Name],
            xmlNode.value('@value', 'varchar(4000)') [Value]
        From @paramXML.nodes('//item') AS R(xmlNode)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @debugMode <> 0
            Print 'Added ' + Convert(varchar(12), @myRowCount) + ' new entries using settings file "' + @settingsFileName + '"'
    End

/* -- alternate way to extract XML into rowset
   -- However, this method does not handle special characters, like é so don't use it
    DECLARE @hDoc int
    --
    --
    EXEC sp_xml_preparedocument @hDoc OUTPUT, @paramXML
    --
    INSERT INTO #T_Tmp_ParamTab
    SELECT * FROM OPENXML(@hDoc, N'//item', 2)
    with (
        [Step_Number] varchar(22) '../@id',
        [Section] varchar(128) '../@name',
        [Name] varchar(128) '@key' ,
        [Value] varchar(4000) '@value'
    )
    --
    EXEC sp_xml_removedocument @hDoc
*/


    ---------------------------------------------------
    -- Check whether the settings file has an
    -- External DTA folder defined
    ---------------------------------------------------
    --
    if exists (SELECT * FROM #T_Tmp_ParamTab WHERE [Name] = 'ExternalDTAFolderName')
    begin
        ---------------------------------------------------
        -- Look for a Special_Processing entry in the job parameters
        -- If one exists, look for the DTA: tag
        -- Otherwise, look in the job's comment for the DTA: tag
        -- If the DTA: tag is found, the name after the column represents an external DTA folder name
        --  to override the external DTA folder name defined in the settings file
        ---------------------------------------------------
        --
        Declare @extDTA varchar(128) = ''

        SELECT @extDTA = dbo.extract_tagged_name('DTA:', Value)
        FROM #T_Tmp_ParamTab
        WHERE [Name] = 'Special_Processing'
        --
        If @extDTA = ''
            SELECT @extDTA = dbo.extract_tagged_name('DTA:', Comment)
            FROM T_Jobs
            WHERE Job = @job
        --
        If @extDTA <> ''
        Begin
            UPDATE #T_Tmp_ParamTab
            SET [Value] = @extDTA
            WHERE [Name] = 'ExternalDTAFolderName'

            If @debugMode <> 0
                Print 'External DTA Folder Name parameter has been overridden to "' + @extDTA + '" using the DTA: tag in the job comment'
        End
        Else
        Begin
            SELECT @extDTA = Value
            FROM #T_Tmp_ParamTab
            WHERE [Name] = 'ExternalDTAFolderName'

            If @debugMode <> 0
                Print 'Note: ExternalDTAFolderName is  "' + @extDTA + '", as defined in the settings file'
        End
    End

    ---------------------------------------------------
    -- Output the table of parameters
    ---------------------------------------------------

    SELECT @job AS Job,
           [Step_Number],
           [Section],
           [Name],
           [Value]
    FROM #T_Tmp_ParamTab
    ORDER BY [Section], [Name]

    RETURN

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_param_table] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_job_param_table] TO [Limited_Table_Write] AS [dbo]
GO

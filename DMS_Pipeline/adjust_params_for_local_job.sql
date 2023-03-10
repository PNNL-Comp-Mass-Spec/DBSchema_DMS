/****** Object:  StoredProcedure [dbo].[adjust_params_for_local_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[adjust_params_for_local_job]
/****************************************************
**
**  Desc:   Adjust the job parameters for special cases, for example
**          local jobs that target other jobs (typically as defined by a data package)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          10/16/2010 grk - Initial release
**          01/19/2012 mem - Added parameter @DataPackageID
**          01/03/2014 grk - Added logic for CacheFolderRootPath
**          03/14/2014 mem - Added job parameter InstrumentDataPurged
**          06/16/2016 mem - Move data package transfer folder path logic to add_update_transfer_paths_in_params_using_data_pkg
**          04/11/2022 mem - Use varchar(4000) when populating temp table #PARAMS using @jobParamXML
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in temporary tables
**
*****************************************************/
(
    @scriptName varchar(64),
    @datasetName varchar(128) = 'na',
    @DataPackageID int,
    @jobParamXML xml output,            -- Input / Output parameter
    @message varchar(512) OUTPUT
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @paramsUpdated tinyint = 0

    Set @DataPackageID = IsNull(@DataPackageID, 0)

    ---------------------------------------------------
    -- Convert job params from XML to temp table
    ---------------------------------------------------

    CREATE TABLE #PARAMS (
        [Section] varchar(128),
        [Name] varchar(128),
        [Value] varchar(4000)
    )

    INSERT INTO #PARAMS
            (Section, Name, Value)
    SELECT
            xmlNode.value('@Section', 'varchar(128)') [Section],
            xmlNode.value('@Name', 'varchar(128)') [Name],
            xmlNode.value('@Value', 'varchar(4000)') [Value]
    FROM @jobParamXML.nodes('//Param') AS R(xmlNode)


    ---------------------------------------------------
    -- If this job has a 'DataPackageID' defined, update parameters
    --     'CacheFolderPath'
    --   'transferFolderPath'
    --   'DataPackagePath'
    ---------------------------------------------------

    exec add_update_transfer_paths_in_params_using_data_pkg @dataPackageID, @paramsUpdated output, @message output


    ---------------------------------------------------
    -- If this job has a 'SourceJob' parameter, update parameters
    --     'DatasetArchivePath'
    --     'DatasetNum'
    --     'RawDataType'
    --     'DatasetStoragePath'
    --     'transferFolderPath'
    --     'DatasetFolderName'
    --     'InstrumentDataPurged'
    --
    -- Also update Input_Folder_Name in #Job_Steps for steps that are not 'Results_Transfer' steps
    ---------------------------------------------------
    --
    Declare @sourceJob int = 0
    --
    SELECT @sourceJob = Value FROM #PARAMS WHERE Name = 'sourceJob'
    --
    IF @sourceJob <> 0
    BEGIN
        -- PRINT 'sourceJob:' + CONVERT(varchar(12), @sourceJob)
        -- look up path to results folder for job given by @sourceJob and add it to temp parameters table

        Declare @archiveFolderPath varchar(260) = ''
        Declare @dataset varchar(128) = ''
        Declare @rawDataType varchar(128) = ''
        Declare @sourceResultsFolder varchar(128) = ''
        Declare @datasetStoragePath varchar(260) = ''
        Declare @transferFolderPath varchar(260) = ''
        Declare @instrumentDataPurged tinyint = 0
        --
        SELECT @archiveFolderPath = [Archive Folder Path],
               @dataset = Dataset,
               @datasetStoragePath = [Dataset Storage Path],
               @rawDataType = RawDataType,
               @sourceResultsFolder = [Results Folder],
               @transferFolderPath = transferFolderPath,
               @instrumentDataPurged = InstrumentDataPurged
        FROM S_DMS_V_Analysis_Job_Info
        WHERE Job = @sourceJob

        IF @dataset <> ''
        BEGIN
            -- UPDATE Input_Folder_Name for job steps
            -- (in the future, we may want to be more selective about which steps are not updated)
            UPDATE #Job_Steps
            SET Input_Folder_Name = @sourceResultsFolder
            WHERE NOT Tool IN ('Results_Transfer')
        END

        IF @dataset <> ''
        BEGIN
            DELETE FROM #PARAMS
            WHERE Name IN ('DatasetArchivePath',
                           'DatasetNum',
                           'RawDataType',
                           'DatasetStoragePath',
                           'transferFolderPath',
                           'DatasetFolderName',
                           'InstrumentDataPurged')
            --

            INSERT INTO #PARAMS ( Section, Name, Value )
            SELECT 'JobParameters', 'DatasetArchivePath', @archiveFolderPath
            UNION
            SELECT 'JobParameters', 'DatasetNum', @dataset
            UNION
            SELECT 'JobParameters', 'RawDataType', @rawDataType
            UNION
            SELECT 'JobParameters', 'DatasetStoragePath', @datasetStoragePath
            UNION
            SELECT 'JobParameters', 'transferFolderPath', @transferFolderPath
            UNION
            SELECT 'JobParameters', 'DatasetFolderName', @dataset
            UNION
            SELECT 'JobParameters', 'InstrumentDataPurged', @instrumentDataPurged

            SET @paramsUpdated = 1
        END
    END

    ---------------------------------------------------
    -- Update @jobParamXML if changes were made
    ---------------------------------------------------
    --
    IF @paramsUpdated <> 0
    BEGIN
        SET @jobParamXML = ( SELECT * FROM #PARAMS AS Param FOR XML AUTO, TYPE)
    END

GO
GRANT VIEW DEFINITION ON [dbo].[adjust_params_for_local_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[adjust_params_for_local_job] TO [Limited_Table_Write] AS [dbo]
GO

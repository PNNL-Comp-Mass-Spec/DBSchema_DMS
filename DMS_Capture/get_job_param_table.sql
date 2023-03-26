/****** Object:  StoredProcedure [dbo].[get_job_param_table] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_job_param_table]
/****************************************************
**
**  Desc:
**      Returns a table filled with the parameters for the
**      given job (from #Jobs) in Section/Name/Value rows
**
**  The calling procedure must create table #Jobs
**
**      CREATE TABLE #Jobs (
**          [Job] int NOT NULL,
**          [Priority] int NULL,
**          [Script] varchar(64) NULL,
**          [State] int NOT NULL,
**          [Dataset] varchar(128) NULL,
**          [Dataset_ID] int NULL,
**          [Results_Directory_Name] varchar(128) NULL,
**          Storage_Server varchar(64) NULL,
**          Instrument varchar(24) NULL,
**          Instrument_Class VARCHAR(32),
**          Max_Simultaneous_Captures int NULL,
**          Capture_Subdirectory varchar(255) NULL
**      )
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/04/2010 grk - Added instrument class params
**          03/23/2012 mem - Now including EUS_Instrument_ID
**          04/09/2013 mem - Now looking up Perform_Calibration from S_DMS_T_Instrument_Name
**          08/20/2013 mem - Now looking up EUS_Proposal_ID
**          09/04/2013 mem - Now including TransferFolderPath (later renamed to TransferDirectoryPath)
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          11/16/2015 mem - Now including EUS_Operator_ID and Operator_PRN
**          05/17/2019 mem - Switch from folder to directory in temp tables
**                         - Rename job parameter to TransferDirectoryPath
**                         - Add parameter SHA1_Hash
**          08/31/2022 mem - Rename view V_DMS_Capture_Job_Parameters to V_DMS_Dataset_Metadata
**          02/01/2023 mem - Use new synonym name
**          02/03/2023 bcg - Use synonym name S_DMS_T_Instrument_Class instead of the view that wraps it
**          02/03/2023 bcg - Update column names for V_DMS_Dataset_Metadata
**          02/03/2023 bcg - Replace Operator_PRN with Operator_Username
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @datasetID int
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(512) = ''

    ---------------------------------------------------
    -- Table variable to hold job parameters
    ---------------------------------------------------
    --
    Declare @paramTab TABLE
    (
      [Step_Number] varchar(24),
      [Section] varchar(128),
      [Name] varchar(128),
      [Value] varchar(2000)
    )

    ---------------------------------------------------
    -- locally cached params
    ---------------------------------------------------
    --
    Declare
        @dataset varchar(255),
        @storage_server_name varchar(255),
        @instrument_name varchar(255),
        @instrument_class varchar(255),
        @max_simultaneous_captures varchar(255),
        @capture_subdirectory varchar(255)
    --

    SELECT
        @dataset = Dataset,
        @storage_server_name = Storage_Server,
        @instrument_name = Instrument,
        @instrument_class = Instrument_Class,
        @max_simultaneous_captures = Max_Simultaneous_Captures,
        @capture_subdirectory = Capture_Subdirectory
    FROM
        #Jobs
    WHERE
        Dataset_ID = @datasetID AND
        Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    INSERT INTO @paramTab ([Step_Number], [Section], [Name], [Value]) VALUES (NULL, 'JobParameters', 'Dataset_ID', @datasetID)
    INSERT INTO @paramTab ([Step_Number], [Section], [Name], [Value]) VALUES (NULL, 'JobParameters', 'Dataset', @dataset)
    INSERT INTO @paramTab ([Step_Number], [Section], [Name], [Value]) VALUES (NULL, 'JobParameters', 'Storage_Server_Name', @storage_server_name)
    INSERT INTO @paramTab ([Step_Number], [Section], [Name], [Value]) VALUES (NULL, 'JobParameters', 'Instrument_Name', @instrument_name)
    INSERT INTO @paramTab ([Step_Number], [Section], [Name], [Value]) VALUES (NULL, 'JobParameters', 'Instrument_Class', @instrument_class)
    INSERT INTO @paramTab ([Step_Number], [Section], [Name], [Value]) VALUES (NULL, 'JobParameters', 'Max_Simultaneous_Captures', @max_simultaneous_captures)
    INSERT INTO @paramTab ([Step_Number], [Section], [Name], [Value]) VALUES (NULL, 'JobParameters', 'Capture_Subdirectory', @capture_subdirectory)

    ---------------------------------------------------
    -- Dataset Parameters
    --
    -- Convert columns of data from V_DMS_Dataset_Metadata into rows added to @paramTab
    --
    -- Note that by using Unpivot, any columns from V_DMS_Dataset_Metadata that are null
    -- will not be entered into@paramTab
    ---------------------------------------------------
    --
    INSERT INTO @paramTab
    SELECT
      NULL AS Step_Number,
      'JobParameters' AS [Section],
      TP.Name,
      TP.Value
    FROM
      ( SELECT
          CONVERT(varchar(2000), Type) AS Dataset_Type,
          CONVERT(varchar(2000), Folder) AS Directory,
          CONVERT(varchar(2000), Method) AS Method,
          CONVERT(varchar(2000), Capture_Exclusion_Window) AS Capture_Exclusion_Window,
          CONVERT(varchar(2000), Created) AS Created ,
          CONVERT(varchar(2000), Source_Vol) AS Source_Vol,
          CONVERT(varchar(2000), Source_Path) AS Source_Path,
          CONVERT(varchar(2000), Storage_Vol) AS Storage_Vol,
          CONVERT(varchar(2000), Storage_Path) AS Storage_Path,
          CONVERT(varchar(2000), Storage_Vol_External) AS Storage_Vol_External,
          CONVERT(varchar(2000), Archive_Server) AS Archive_Server,
          CONVERT(varchar(2000), Archive_Path) AS Archive_Path,
          CONVERT(varchar(2000), Archive_Network_Share_Path) AS Archive_Network_Share_Path,
          CONVERT(varchar(2000), EUS_Instrument_ID) AS EUS_Instrument_ID,
          CONVERT(varchar(2000), EUS_Proposal_ID) AS EUS_Proposal_ID,
          CONVERT(varchar(2000), EUS_Operator_ID) AS EUS_Operator_ID,
          CONVERT(varchar(2000), Operator_Username) AS Operator_Username

        FROM
          V_DMS_Dataset_Metadata
        WHERE
          Dataset_ID = @datasetID
      ) TD UNPIVOT ( Value FOR [Name] IN ( Dataset_Type, Directory, Method, Capture_Exclusion_Window, Created ,
                                           Source_Vol, Source_Path, Storage_Vol, Storage_Path, Storage_Vol_External,
                                           Archive_Server, Archive_Path, Archive_Network_Share_Path,
                                           EUS_Instrument_ID, EUS_Proposal_ID, EUS_Operator_ID, Operator_Username
                   ) ) as TP
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Instrument class params from DMS5.T_Instrument_Class
    --
    -- This includes all of the DatasetQC parameters, typically including:
    --
    --   SaveTICAndBPIPlots, default True
    --   SaveLCMS2DPlots, default True
    --   ComputeOverallQualityScores, default True
    --   CreateDatasetInfoFile, default True
    --   LCMS2DPlotMZResolution, default 0.4
    --   LCMS2DPlotMaxPointsToPlot, default 200000
    --   LCMS2DPlotMinPointsPerSpectrum, default 2
    --   LCMS2DPlotMinIntensity, default 0
    --   LCMS2DOverviewPlotDivisor, default 10
    --
    ---------------------------------------------------
    --
    Declare @paramXML XML
    Declare @rawDataType varchar(32)
    --
    SELECT
        @rawDataType = raw_data_type,
        @paramXML = Params
    FROM
        S_DMS_T_Instrument_Class
    WHERE
        IN_class = @instrument_class

    INSERT INTO @paramTab
    (Step_Number, [Section], [Name], Value )
    SELECT
        NULL AS  [Step_Number],
        xmlNode.value('../@name', 'nvarchar(256)') [Section],
        xmlNode.value('@key', 'nvarchar(256)') [Name],
        xmlNode.value('@value', 'nvarchar(4000)') [Value]
    FROM   @paramXML.nodes('//item') AS R(xmlNode)

    INSERT INTO @paramTab
        ( Step_Number, [Section], [Name], Value )
    VALUES
        (NULL, 'JobParameters', 'RawDataType', @rawDataType)


    ---------------------------------------------------
    -- Determine whether calibration should be performed
    -- (as of April 2013, only applies to IMS instruments)
    ---------------------------------------------------

    Declare @PerformCalibration tinyint
    Declare @PerformCalibrationText varchar(12)

    SELECT @PerformCalibration = Perform_Calibration
    FROM S_DMS_T_Instrument_Name
    WHERE IN_Name = @instrument_name

    If IsNull(@PerformCalibration, 0) = 0
        Set @PerformCalibrationText = 'False'
    Else
        Set @PerformCalibrationText = 'True'

    INSERT INTO @paramTab
        ( Step_Number, [Section], [Name], Value )
    VALUES
        (NULL, 'JobParameters', 'PerformCalibration', @PerformCalibrationText)


    ---------------------------------------------------
    -- Lookup the Analysis Transfer directory (e.g. \\proto-6\DMS3_Xfer)
    -- This directory is used to store metadata.txt files for dataset archive and archive update jobs
    -- Those files are used by the ArchiveVerify tool to confirm that files were successfully imported into MyEMSL
    ---------------------------------------------------
    --
    Declare @StorageVolExternal varchar(128)
    Declare @TransferDirectoryPath varchar(128)

    SELECT @StorageVolExternal = Value
    FROM @paramTab
    WHERE [Name] = 'Storage_Vol_External'

    SELECT @TransferDirectoryPath = Transfer_Directory_Path
    FROM ( SELECT DISTINCT TStor.SP_vol_name_client AS Storage_Vol_External,
                           dbo.combine_paths(TStor.SP_vol_name_client, Xfer.Client) AS Transfer_Directory_Path
           FROM S_DMS_t_storage_path AS TStor
                CROSS JOIN ( SELECT TOP 1 Client
                             FROM S_DMS_V_Misc_Paths
                             WHERE [Function] = 'AnalysisXfer' ) AS Xfer
           WHERE ISNULL(TStor.SP_vol_name_client, '') <> '' AND
                 TStor.SP_vol_name_client <> '(na)'
         ) DirectoryQ
    WHERE Storage_Vol_External = @StorageVolExternal

    Set @TransferDirectoryPath = IsNull(@TransferDirectoryPath, '')

    INSERT INTO @paramTab
        ( Step_Number, [Section], [Name], Value )
    VALUES
        (NULL, 'JobParameters', 'TransferDirectoryPath', @TransferDirectoryPath)

    ---------------------------------------------------
    -- Add the SHA-1 hash for the first instrument file, if defined
    ---------------------------------------------------
    Declare @fileHash Varchar(64) = ''

    SELECT @fileHash = file_hash
    FROM S_DMS_T_Dataset_Files
    WHERE Dataset_ID = @datasetID AND
          Deleted = 0 AND
          File_Size_Rank = 1
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        INSERT INTO @paramTab
            ( Step_Number, [Section], [Name], Value )
        VALUES
            (NULL, 'JobParameters', 'Instrument_File_Hash', @fileHash)
    End

    ---------------------------------------------------
    -- output the table of parameters
    ---------------------------------------------------

    SELECT @job AS Job,
           [Step_Number],
           [Section],
           [Name],
           [Value]
    FROM @paramTab
    ORDER BY [Section], [Name]

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_param_table] TO [DDL_Viewer] AS [dbo]
GO

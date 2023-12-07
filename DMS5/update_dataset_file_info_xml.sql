/****** Object:  StoredProcedure [dbo].[update_dataset_file_info_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dataset_file_info_xml]
/****************************************************
**
**  Desc:   Updates the information for the dataset specified by @datasetID
**
**          If @datasetID is 0, will use the dataset name defined in @datasetInfoXML
**          If @datasetID is non-zero, will validate that the Dataset Name in the XML corresponds
**          to the dataset ID specified by @datasetID
**
**      Typical XML file contents:
**
**      <DatasetInfo>
**        <Dataset>QC_Shew_17_01_Run_2_7Jun18_Oak_18-03-08</Dataset>
**        <ScanTypes>
**          <ScanType ScanCount="10574" ScanFilterText="FTMS + p NSI Full ms">HMS</ScanType>
**          <ScanType ScanCount="42861" ScanFilterText="FTMS + p NSI d Full ms2 0@hcd32.00">HCD-HMSn</ScanType>
**        </ScanTypes>
**        <AcquisitionInfo>
**          <ScanCount>53435</ScanCount>
**          <ScanCountMS>10574</ScanCountMS>
**          <ScanCountMSn>42861</ScanCountMSn>
**          <ScanCountDIA>0</ScanCountDIA>
**          <Elution_Time_Max>120.00</Elution_Time_Max>
**          <AcqTimeMinutes>120.00</AcqTimeMinutes>
**          <StartTime>2018-06-07 07:19:59 PM</StartTime>
**          <EndTime>2018-06-07 09:19:58 PM</EndTime>
**          <FileSizeBytes>1623020913</FileSizeBytes>
**          <InstrumentFiles>
**            <InstrumentFile Hash="cc7b7c917a7eedf82dbea7382d01a67a9ccd7908" HashType="SHA1" Size="1623020913">
**              QC_Shew_17_01_Run_2_7Jun18_Oak_18-03-08.raw
**            </InstrumentFile>
**          </InstrumentFiles>
**          <DeviceList>
**            <Device Type="MS" Number="1" Name="Q Exactive Plus Orbitrap" Model="Q Exactive Plus"
**                    SerialNumber="Exactive Series slot #300" SoftwareVersion="2.8-280502/2.8.1.2806">
**              Mass Spectrometer
**            </Device>
**          </DeviceList>
**          <ProfileScanCountMS1>10573</ProfileScanCountMS1>
**          <ProfileScanCountMS2>42658</ProfileScanCountMS2>
**          <CentroidScanCountMS1>1</CentroidScanCountMS1>
**          <CentroidScanCountMS2>203</CentroidScanCountMS2>
**        </AcquisitionInfo>
**        <TICInfo>
**          <TIC_Max_MS>5.4277E+09</TIC_Max_MS>
**          <TIC_Max_MSn>3.6099E+08</TIC_Max_MSn>
**          <BPI_Max_MS>6.2221E+08</BPI_Max_MS>
**          <BPI_Max_MSn>4.5959E+07</BPI_Max_MSn>
**          <TIC_Median_MS>9.1757E+07</TIC_Median_MS>
**          <TIC_Median_MSn>1.8929E+06</TIC_Median_MSn>
**          <BPI_Median_MS>3.881E+06</BPI_Median_MS>
**          <BPI_Median_MSn>103457</BPI_Median_MSn>
**        </TICInfo>
**      </DatasetInfo>
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/03/2010 mem - Initial version
**          05/13/2010 mem - Added parameter @validateDatasetType
**          05/14/2010 mem - Now updating T_Dataset_Info.Scan_Types
**          08/03/2010 mem - Removed unneeded fields from the T_Dataset_Info MERGE Source
**          09/01/2010 mem - Now checking for invalid dates and storing Null in Acq_Time_Start and Acq_Time_End If invalid
**          09/09/2010 mem - Fixed bug extracting StartTime and EndTime values
**          09/02/2011 mem - Now calling post_usage_log_entry
**          08/21/2012 mem - Now including DatasetID in the error message
**          04/18/2014 mem - Added support for ProfileScanCountMS1, ProfileScanCountMS2, CentroidScanCountMS1, and CentroidScanCountMS2
**          02/24/2015 mem - Now validating that @datasetID exists in T_Dataset
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW If not authorized
**          06/13/2018 mem - Store instrument files info in T_Dataset_Files
**          06/25/2018 mem - Populate the File_Size_Rank column
**          08/08/2018 mem - Fix null value where clause bug in @DuplicateDatasetsTable
**          08/09/2018 mem - Use @duplicateEntryHoldoffHours when logging the duplicate dataset error
**          08/10/2018 mem - Update duplicate dataset message and use post_email_alert to add to T_Email_Alerts
**          11/09/2018 mem - Set deleted to 0 when updating existing entries
**                           No longer removed deleted files and sort them last when updating File_Size_Rank
**          02/11/2020 mem - Ignore zero-byte files when checking for duplicates
**          02/29/2020 mem - Refactor code into get_dataset_details_from_dataset_info_xml
**          03/01/2020 mem - Add call to update_dataset_device_info_xml
**          10/10/2020 mem - Use auto_update_separation_type to auto-update the dataset separation type, based on the acquisition length
**          02/14/2022 mem - Log an error if the acquisition length is overly long
**          06/13/2022 mem - Update call to get_dataset_scan_type_list since now a scalar-valued function
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Add support for datasets with multiple instrument files with the same name (e.g. 20220105_JL_kpmp_3504 with ser files in eight .d directories)
**          04/01/2023 mem - Use new DMS_Capture procedures and function names
**          04/24/2023 mem - Store DIA scan count values
**          12/06/2023 mem - Log an error if a scan type is not present in T_Dataset_ScanType_Glossary
**
*****************************************************/
(
    @datasetID int = 0,                     -- If this value is 0, will determine the dataset name using the contents of @datasetInfoXML
    @datasetInfoXML xml,                    -- XML describing the properties of a single dataset
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0,
    @validateDatasetType tinyint = 1        -- If non-zero, will call validate_dataset_type after updating T_Dataset_ScanTypes
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetName varchar(128)
    Declare @datasetIDCheck int

    Declare @startTime varchar(32)
    Declare @endTime varchar(32)

    Declare @acqTimeStart datetime
    Declare @acqTimeEnd datetime
    Declare @acqLengthMinutes int

    Declare @separationType varchar(64)
    Declare @optimalSeparationType varchar(64) = ''

    Declare @msg varchar(1024)
    Declare @duplicateDatasetInfoSuffix varchar(512)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_dataset_file_info_xml', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -----------------------------------------------------------
    -- Create temp tables to hold the data
    -----------------------------------------------------------

    Declare @DSInfoTable table (
        Dataset_ID int NULL,
        Dataset_Name varchar (128) NOT NULL,
        ScanCount int NULL,
        ScanCountMS int NULL,
        ScanCountMSn int NULL,
        Scan_Count_DIA Int Null,
        Elution_Time_Max real NULL,
        AcqTimeMinutes real NULL,
        Acq_Time_Start datetime NULL,
        Acq_Time_End datetime NULL,
        FileSizeBytes bigint NULL,
        TIC_Max_MS real NULL,
        TIC_Max_MSn real NULL,
        BPI_Max_MS real NULL,
        BPI_Max_MSn real NULL,
        TIC_Median_MS real NULL,
        TIC_Median_MSn real NULL,
        BPI_Median_MS real NULL,
        BPI_Median_MSn real NULL,
        ProfileScanCount_MS int NULL,
        ProfileScanCount_MSn int NULL,
        CentroidScanCount_MS int NULL,
        CentroidScanCount_MSn int NULL
    )

    Declare @ScanTypesTable table (
        ScanType varchar(64) NOT NULL,
        ScanCount int NULL,
        ScanFilter varchar(256) NULL
    )

    CREATE TABLE #Tmp_InstrumentFilesTable (
        Entry_ID Int Identity(1,1) Not Null,
        InstFilePath varchar(512) NOT NULL,     -- Relative file path of the instrument file
        InstFileHash varchar(64) NULL,
        InstFileHashType varchar(32) NULL,      -- Should always be SHA1
        InstFileSize bigint Null,
        FileSizeRank Smallint Null              -- File size rank, across all instrument files for this dataset
    )

    Declare @DuplicateDatasetsTable Table (
        Dataset_ID int NOT NULL,
        MatchingFileCount int NOT NULL,
        Allow_Duplicates tinyint NOT NULL
    )

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @datasetID           = Coalesce(@datasetID, 0)
    Set @message             = ''
    Set @infoOnly            = Coalesce(@infoOnly, 0)
    Set @validateDatasetType = Coalesce(@validateDatasetType, 1)

    Declare @datasetIdText varchar(12) = Cast(@datasetID as varchar(12))

    ---------------------------------------------------
    -- Examine the XML to determine the dataset name and update or validate @datasetID
    ---------------------------------------------------
    --
    Exec get_dataset_details_from_dataset_info_xml
        @datasetInfoXML,
        @datasetID   = @datasetID Output,
        @datasetName = @datasetName Output,
        @message     = @message Output,
        @returnCode  = @myError Output

    If @myError <> 0
    Begin
        Goto Done
    End

    ---------------------------------------------------
    -- Parse the contents of @datasetInfoXML to populate @DSInfoTable
    -- Skip the StartTime and EndTime values for now since they might have invalid dates
    ---------------------------------------------------
    --
    INSERT INTO @DSInfoTable (
        Dataset_ID,
        Dataset_Name,
        ScanCount,
        ScanCountMS,
        ScanCountMSn,
        Scan_Count_DIA,
        Elution_Time_Max,
        AcqTimeMinutes,
        FileSizeBytes,
        TIC_Max_MS,
        TIC_Max_MSn,
        BPI_Max_MS,
        BPI_Max_MSn,
        TIC_Median_MS,
        TIC_Median_MSn,
        BPI_Median_MS,
        BPI_Median_MSn,
        ProfileScanCount_MS,
        ProfileScanCount_MSn,
        CentroidScanCount_MS,
        CentroidScanCount_MSn
    )
    SELECT @datasetID AS DatasetID,
           @datasetName AS Dataset,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ScanCount)[1]', 'int') AS ScanCount,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ScanCountMS)[1]', 'int') AS ScanCountMS,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ScanCountMSn)[1]', 'int') AS ScanCountMSn,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ScanCountDIA)[1]', 'int') AS Scan_Count_DIA,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/Elution_Time_Max)[1]', 'real') AS Elution_Time_Max,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/AcqTimeMinutes)[1]', 'real') AS AcqTimeMinutes,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/FileSizeBytes)[1]', 'bigint') AS FileSizeBytes,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Max_MS)[1]', 'real') AS TIC_Max_MS,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Max_MSn)[1]', 'real') AS TIC_Max_MSn,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Max_MS)[1]', 'real') AS BPI_Max_MS,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Max_MSn)[1]', 'real') AS BPI_Max_MSn,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Median_MS)[1]', 'real') AS TIC_Median_MS,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Median_MSn)[1]', 'real') AS TIC_Median_MSn,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Median_MS)[1]', 'real') AS BPI_Median_MS,
           @datasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Median_MSn)[1]', 'real') AS BPI_Median_MSn,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ProfileScanCountMS1)[1]', 'int') AS ProfileScanCountMS1,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ProfileScanCountMS2)[1]', 'int') AS ProfileScanCountMS2,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/CentroidScanCountMS1)[1]', 'int') AS CentroidScanCountMS1,
           @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/CentroidScanCountMS2)[1]', 'int') AS CentroidScanCountMS2
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error extracting data from @datasetInfoXML for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure Dataset_ID is up-to-date in @DSInfoTable
    ---------------------------------------------------
    --
    UPDATE @DSInfoTable
    SET Dataset_ID = @datasetID

    ---------------------------------------------------
    -- Parse out the start and End times
    -- Initially extract as strings in case they're out of range for the datetime date type
    ---------------------------------------------------
    --
    SELECT @startTime = @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/StartTime)[1]', 'varchar(32)'),
           @endTime = @datasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/EndTime)[1]', 'varchar(32)')

    If IsDate(@startTime) <> 0
    Begin
        Set @acqTimeStart = Convert(datetime, @startTime)
    End

    If IsDate(@endTime) <> 0
    Begin
        Set @acqTimeEnd = Convert(datetime, @endTime)
    End
    Else
    Begin
        -- End Time is invalid
        -- If the start time is valid, add the acquisition time length to the End time
        -- (though, typically, If one is invalid the other will be invalid too)
        -- IMS .UIMF files acquired in summer 2010 had StartTime values of 0410-08-29 (year 410) due to a bug

        If Not @acqTimeStart Is Null
        Begin
            SELECT @acqTimeEnd = DateAdd(minute, AcqTimeMinutes, @acqTimeStart)
            FROM @DSInfoTable
        End
    End

    UPDATE @DSInfoTable
    Set Acq_Time_Start = @acqTimeStart,
        Acq_Time_End = @acqTimeEnd

    ---------------------------------------------------
    -- Extract out the ScanType information
    -- There could be multiple scan types defined in the XML
    ---------------------------------------------------
    --
    INSERT INTO @ScanTypesTable (ScanType, ScanCount, ScanFilter)
    SELECT ScanType, ScanCount, ScanFilter
    FROM ( SELECT xmlNode.value('.', 'varchar(64)') AS ScanType,
                  xmlNode.value('@ScanCount', 'int') AS ScanCount,
                  xmlNode.value('@ScanFilterText', 'varchar(256)') AS ScanFilter
           FROM @datasetInfoXML.nodes('/DatasetInfo/ScanTypes/ScanType') AS R(xmlNode)
    ) LookupQ
    WHERE Not ScanType IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error parsing ScanType nodes in @datasetInfoXML for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
        Goto Done
    End

    ---------------------------------------------------
    -- Now extract out the instrument files
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_InstrumentFilesTable ( InstFilePath, InstFileHash, InstFileHashType, InstFileSize)
    SELECT instFiles.InstrumentFile.value('(.)[1]','varchar(512)') As InstFilePath,
           instFiles.InstrumentFile.value('(./@Hash)[1]','varchar(64)') As InstFileHash,
           instFiles.InstrumentFile.value('(./@HashType)[1]','varchar(32)') As InstFileHashType,
           instFiles.InstrumentFile.value('(./@Size)[1]','bigint') As InstFileSize
    FROM @datasetInfoXML.nodes('/DatasetInfo/AcquisitionInfo/InstrumentFiles/InstrumentFile') As instFiles(InstrumentFile)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error parsing InstrumentFile nodes in @datasetInfoXML for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
        Goto Done
    End

    ---------------------------------------------------
    -- Update FileSizeRank in #Tmp_InstrumentFilesTable
    ---------------------------------------------------

    UPDATE #Tmp_InstrumentFilesTable
    SET FileSizeRank = RankQ.FileSizeRank
    FROM #Tmp_InstrumentFilesTable Inner Join (
        SELECT Entry_ID, Row_Number() Over (Order By InstFileSize Desc) As FileSizeRank
        FROM #Tmp_InstrumentFilesTable
        ) As RankQ On #Tmp_InstrumentFilesTable.Entry_ID = RankQ.Entry_ID

    ---------------------------------------------------
    -- Validate the hash type
    ---------------------------------------------------
    --
    Declare @unrecognizedHashType varchar(32) = ''

    SELECT @unrecognizedHashType = InstFileHashType
    FROM #Tmp_InstrumentFilesTable
    WHERE Not InstFileHashType In ('SHA1')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 1
    Begin
        Set @msg = 'Unrecognized file hash type: ' + @unrecognizedHashType + '; all rows in T_Dataset_File are assumed to be SHA1. ' +
                   'Will add the file info anyway, but this hashtype could be problematic elsewhere'

        Exec post_log_entry 'Error', @msg, 'update_dataset_file_info_xml'
    End

    ---------------------------------------------------
    -- Check whether this is a duplicate dataset
    -- Look for an existing dataset with the same file hash values but a different dataset ID
    ---------------------------------------------------

    Declare @instrumentFileCount int = 0

    SELECT @instrumentFileCount = Count(*)
    FROM #Tmp_InstrumentFilesTable

    If @instrumentFileCount > 0
    Begin
        INSERT INTO @DuplicateDatasetsTable( Dataset_ID,
                                             MatchingFileCount,
                                             Allow_Duplicates)
        SELECT DSFiles.Dataset_ID,
               Count(*) AS MatchingFiles,
               0 As Allow_Duplicates
        FROM T_Dataset_Files DSFiles
             INNER JOIN #Tmp_InstrumentFilesTable NewDSFiles
               ON DSFiles.File_Hash = NewDSFiles.InstFileHash
        WHERE DSFiles.Dataset_ID <> @datasetID And DSFiles.Deleted = 0 And DSFiles.File_Size_Bytes > 0
        GROUP BY DSFiles.Dataset_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error looking for matching instrument files in T_Dataset_Files for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
            Goto Done
        End

        Declare @duplicateDatasetID int = 0

        If Exists (SELECT * FROM @DuplicateDatasetsTable WHERE MatchingFileCount >= @instrumentFileCount)
        Begin
            UPDATE @DuplicateDatasetsTable
            SET Allow_Duplicates = 1
            FROM @DuplicateDatasetsTable Target
                 INNER JOIN T_Dataset_Files Src
                   ON Target.Dataset_ID = Src.Dataset_ID
            WHERE Src.Allow_Duplicates = 1
        End

        If Exists (SELECT * FROM @DuplicateDatasetsTable WHERE MatchingFileCount >= @instrumentFileCount And Allow_Duplicates = 0)
        Begin
            SELECT TOP 1 @duplicateDatasetID = Dataset_ID
            FROM @DuplicateDatasetsTable
            WHERE MatchingFileCount >= @instrumentFileCount And Allow_Duplicates = 0
            ORDER BY Dataset_ID Desc
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            -- Duplicate dataset found: DatasetID 693058 has the same instrument file as DatasetID 692115; see table T_Dataset_Files
            Set @duplicateDatasetInfoSuffix = ' has the same instrument file as DatasetID ' +
                                              Cast(@duplicateDatasetID As varchar(12)) + '; ' +
                                              'to allow this duplicate, set Allow_Duplicates to true for DatasetID ' +
                                              Cast(@duplicateDatasetID As varchar(12)) + ' in table T_Dataset_Files'

            -- The message "Duplicate dataset found" is used by a SQL Server Agent job that notifies admins hourly if a duplicate dataset is uploaded
            Set @message = 'Duplicate dataset found: DatasetID ' + @datasetIdText + @duplicateDatasetInfoSuffix

            Exec post_email_alert 'Error', @message, 'update_dataset_file_info_xml', @recipients='admins', @postMessageToLogEntries=1, @duplicateEntryHoldoffHours=6

            -- Error code 53600 is used by stored procedure update_dms_dataset_state in the DMS_Capture database
            -- Call stack: update_task_context->update_task_state->update_dms_dataset_state->update_dms_file_info_xml->update_dataset_file_info_xml
            Set @myError = 53600
            Goto Done

        End

        If Exists (SELECT * FROM @DuplicateDatasetsTable WHERE MatchingFileCount >= @instrumentFileCount And Allow_Duplicates = 1)
        Begin
            SELECT TOP 1 @duplicateDatasetID = Dataset_ID
            FROM @DuplicateDatasetsTable
            WHERE MatchingFileCount >= @instrumentFileCount And Allow_Duplicates = 1
            ORDER BY Dataset_ID Desc
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @duplicateDatasetInfoSuffix = ' has the same instrument file as DatasetID ' +
                                              Cast(@duplicateDatasetID As varchar(12)) + '; see table T_Dataset_Files'

            Set @msg = 'Allowing duplicate dataset to be added since Allow_Duplicates is 1: ' +
                       'DatasetID ' + @datasetIdText + @duplicateDatasetInfoSuffix

            Exec post_log_entry 'Warning', @msg, 'update_dataset_file_info_xml'
        End
    End

    -----------------------------------------------
    -- Possibly update the separation type for the dataset
    -----------------------------------------------

    SELECT @separationType = DS_sec_sep
    FROM T_Dataset
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Select @acqLengthMinutes = AcqTimeMinutes
    From @DSInfoTable

    If @acqLengthMinutes > 1 AND ISNULL(@separationType, '') <> ''
    Begin
        -- Possibly update the separation type
        -- Note that update_dataset_file_info_xml will also call update_dataset_file_info_xml when the MSFileInfoScanner tool runs
        EXEC auto_update_separation_type @separationType, @acqLengthMinutes, @optimalSeparationType = @optimalSeparationType output

        If @optimalSeparationType <> @separationType AND @infoOnly = 0
        Begin
            UPDATE T_Dataset
            SET DS_sec_sep = @optimalSeparationType
            WHERE Dataset_ID = @datasetID

            If NOT Exists (SELECT * FROM T_Log_Entries WHERE Message Like 'Auto-updated separation type%' And Entered >= DateAdd(hour, -2, getdate()))
            Begin
                Set @msg = 'Auto-updated separation type from ' + @separationType + ' to ' + @optimalSeparationType + ' for dataset ' + @datasetName
                Exec post_log_entry 'Normal', @msg, 'update_dataset_file_info_xml'
            End

        End
    End

    If @infoOnly <> 0
    Begin
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT *, @separationType As Separation_Type, @optimalSeparationType as Optimal_Separation_Type
        FROM @DSInfoTable

        SELECT *
        FROM @ScanTypesTable

        SELECT *
        FROM #Tmp_InstrumentFilesTable

        Exec update_dataset_device_info_xml @datasetID=@datasetID, @datasetInfoXML=@datasetInfoXML, @infoOnly=1, @skipValidation=1

        Goto Done
    End

    -----------------------------------------------
    -- Validate/fix the Acq_Time entries
    -----------------------------------------------

    -- First look for any entries in the temporary table
    -- where Acq_Time_Start is Null while Acq_Time_End is defined
    --
    UPDATE @DSInfoTable
    SET Acq_Time_Start = Acq_Time_End
    WHERE Acq_Time_Start IS NULL AND NOT Acq_Time_End IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -- Now look for the reverse case
    --
    UPDATE @DSInfoTable
    SET Acq_Time_End = Acq_Time_Start
    WHERE Acq_Time_End IS NULL AND NOT Acq_Time_Start IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------
    -- Check for Acq_Time_End being more than 7 days after Acq_Time_Start
    -----------------------------------------------

    SELECT @acqLengthMinutes = DateDiff(minute, Acq_Time_Start, Acq_Time_End),
           @acqTimeStart = Acq_Time_Start,
           @acqTimeEnd = Acq_Time_End
    FROM @DSInfoTable

    If @acqLengthMinutes > 10080
    Begin
        Update @DSInfoTable
        Set Acq_Time_End = DateAdd(Hour, 1, Acq_Time_Start)

        Set @message =
            'Acquisition length for dataset ' + @datasetName + ' is over 7 days; ' +
            'the Acq_Time_End value (' + Convert(varchar(24), @acqTimeEnd, 121) + ') is likely invalid, ' +
            'relative to Acq_Time_Start (' + Convert(varchar(24), @acqTimeStart, 121) + '); ' +
            'setting Acq_Time_End to be 60 minutes after Acq_Time_Start'

        exec post_log_entry 'Error', @message, 'update_dataset_file_info_xml'
    End

    -----------------------------------------------
    -- Update T_Dataset with any new or changed values
    -- If Acq_Time_Start Is Null or is <= 1/1/1900 then
    --  the DS_Created time is used for both
    --  Acq_Time_Start and Acq_Time_End
    -----------------------------------------------

    UPDATE T_Dataset
    SET Acq_Time_Start= CASE WHEN IsNull(NewInfo.Acq_Time_Start, '1/1/1900') <= '1/1/1900'
                        THEN DS.DS_Created
                        ELSE NewInfo.Acq_Time_Start END,
        Acq_Time_End =  CASE WHEN IsNull(NewInfo.Acq_Time_Start, '1/1/1900') <= '1/1/1900'
                        THEN DS.DS_Created
                        ELSE NewInfo.Acq_Time_End END,
        Scan_Count = NewInfo.ScanCount,
        File_Size_Bytes = NewInfo.FileSizeBytes,
        File_Info_Last_Modified = GetDate()
    FROM @DSInfoTable NewInfo INNER JOIN
         T_Dataset DS ON
          NewInfo.Dataset_Name = DS.Dataset_Num
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error updating T_Dataset for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
        Goto Done
    End

    -----------------------------------------------
    -- Add/Update T_Dataset_Info using a MERGE statement
    -----------------------------------------------
    --
    MERGE T_Dataset_Info AS target
    USING
        (Select Dataset_ID, ScanCountMS, ScanCountMSn,
                Scan_Count_DIA, Elution_Time_Max,
                TIC_Max_MS, TIC_Max_MSn,
                BPI_Max_MS, BPI_Max_MSn,
                TIC_Median_MS, TIC_Median_MSn,
                BPI_Median_MS, BPI_Median_MSn,
                ProfileScanCount_MS, ProfileScanCount_MSn,
                CentroidScanCount_MS, CentroidScanCount_MSn
         FROM @DSInfoTable
        ) AS Source (Dataset_ID, ScanCountMS, ScanCountMSn,
                     Scan_Count_DIA, Elution_Time_Max,
                     TIC_Max_MS, TIC_Max_MSn,
                     BPI_Max_MS, BPI_Max_MSn,
                     TIC_Median_MS, TIC_Median_MSn,
                     BPI_Median_MS, BPI_Median_MSn,
                     ProfileScanCount_MS, ProfileScanCount_MSn,
                     CentroidScanCount_MS, CentroidScanCount_MSn)
    ON (target.Dataset_ID = Source.Dataset_ID)
    WHEN Matched
        THEN UPDATE
            SET ScanCountMS = Source.ScanCountMS,
                ScanCountMSn = Source.ScanCountMSn,
                Scan_Count_DIA = Source.Scan_Count_DIA,
                Elution_Time_Max = Source.Elution_Time_Max,
                TIC_Max_MS = Source.TIC_Max_MS,
                TIC_Max_MSn = Source.TIC_Max_MSn,
                BPI_Max_MS = Source.BPI_Max_MS,
                BPI_Max_MSn = Source.BPI_Max_MSn,
                TIC_Median_MS = Source.TIC_Median_MS,
                TIC_Median_MSn = Source.TIC_Median_MSn,
                BPI_Median_MS = Source.BPI_Median_MS,
                BPI_Median_MSn = Source.BPI_Median_MSn,
                ProfileScanCount_MS = Source.ProfileScanCount_MS,
                ProfileScanCount_MSn = Source.ProfileScanCount_MSn,
                CentroidScanCount_MS = Source.CentroidScanCount_MS,
                CentroidScanCount_MSn = Source.CentroidScanCount_MSn,
                Last_Affected = GetDate()
    WHEN Not Matched THEN
        INSERT (Dataset_ID, ScanCountMS, ScanCountMSn,
                Scan_Count_DIA, Elution_Time_Max,
                TIC_Max_MS, TIC_Max_MSn,
                BPI_Max_MS, BPI_Max_MSn,
                TIC_Median_MS, TIC_Median_MSn,
                BPI_Median_MS, BPI_Median_MSn,
                ProfileScanCount_MS, ProfileScanCount_MSn,
                CentroidScanCount_MS, CentroidScanCount_MSn,
                Last_Affected )
        VALUES (Source.Dataset_ID, Source.ScanCountMS, Source.ScanCountMSn,
                Source.Scan_Count_DIA,Source.Elution_Time_Max,
                Source.TIC_Max_MS, Source.TIC_Max_MSn,
                Source.BPI_Max_MS, Source.BPI_Max_MSn,
                Source.TIC_Median_MS, Source.TIC_Median_MSn,
                Source.BPI_Median_MS, Source.BPI_Median_MSn,
                Source.ProfileScanCount_MS , Source.ProfileScanCount_MSn,
                Source.CentroidScanCount_MS, Source.CentroidScanCount_MSn,
                GetDate())
    ;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error updating T_Dataset_Info for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
        Goto Done
    End

    -----------------------------------------------
    -- Cannot use a Merge statement on T_Dataset_ScanTypes
    --  since some datasets (e.g. MRM) will have multiple entries
    --  of the same scan type but different ScanFilter values
    -- Instead, delete existing rows then add new ones
    -----------------------------------------------
    --
    DELETE FROM T_Dataset_ScanTypes
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    INSERT INTO T_Dataset_ScanTypes ( Dataset_ID, ScanType, ScanCount, ScanFilter )
    SELECT @datasetID AS Dataset_ID, ScanType, ScanCount, ScanFilter
    FROM @ScanTypesTable
    ORDER BY Dataset_ID, ScanType
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error updating T_Dataset_ScanTypes for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
        Goto Done
    End

    -----------------------------------------------
    -- Update the Scan_Types field in T_Dataset_Info for this dataset
    -----------------------------------------------
    --
    UPDATE T_Dataset_Info
    SET Scan_Types = dbo.get_dataset_scan_type_list(@datasetID)
    FROM T_Dataset DS
         INNER JOIN T_Dataset_Info DSInfo
           ON DSInfo.Dataset_ID = DS.Dataset_ID
    WHERE DS.Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------
    -- Look for new scan types not present in T_Dataset_ScanType_Glossary
    -----------------------------------------------

    DECLARE @missingScanTypes varchar(256) = null

    SELECT @missingScanTypes = CASE WHEN @missingScanTypes Is Null THEN T.ScanType ELSE @missingScanTypes + ', ' + T.ScanType END
    FROM T_Dataset_ScanTypes T 
         LEFT OUTER JOIN T_Dataset_ScanType_Glossary G
           ON G.ScanType = T.ScanType
    WHERE Dataset_ID = @datasetID AND G.ScanType Is Null

    If Coalesce(@missingScanTypes, '') <> ''
    Begin
        If @missingScanTypes Like '%,%'
            Set @msg = 'Scan types "' + @missingScanTypes + '" need to be added to table T_Dataset_ScanType_Glossary'
        Else
            Set @msg = 'Scan type "' + @missingScanTypes + '" needs to be added to table T_Dataset_ScanType_Glossary'

        exec post_log_entry 'Error', @msg, 'update_dataset_file_info_xml', @duplicateEntryHoldoffHours = 1;
    End

    -----------------------------------------------
    -- Add/Update T_Dataset_Files using a Merge statement
    -----------------------------------------------
    --
    MERGE T_Dataset_Files As target
    USING
        (SELECT @datasetID, InstFilePath, InstFileSize, InstFileHash, FileSizeRank
         FROM #Tmp_InstrumentFilesTable
        ) AS Source (Dataset_ID, InstFilePath, InstFileSize, InstFileHash, FileSizeRank)
    ON (target.Dataset_ID = Source.Dataset_ID And Target.File_Path = Source.InstFilePath And Target.File_Size_Rank = Source.FileSizeRank)
    WHEN Matched
        THEN UPDATE
            SET File_Size_Bytes = Source.InstFileSize,
                File_Hash = Source.InstFileHash,
                File_Size_Rank = Source.FileSizeRank,
                Deleted = 0
    WHEN Not Matched THEN
        INSERT (Dataset_ID, File_Path,
                File_Size_Bytes, File_Hash, File_Size_Rank)
        VALUES (Source.Dataset_ID, Source.InstFilePath, Source.InstFileSize, Source.InstFileHash, Source.FileSizeRank)
    ;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error updating T_Dataset_Files for DatasetID ' + @datasetIdText + ' in SP update_dataset_file_info_xml'
        Goto Done
    End

    -- Look for extra files that need to be deleted
    --
    DELETE T_Dataset_Files
    FROM T_Dataset_Files Target
         LEFT OUTER JOIN #Tmp_InstrumentFilesTable Source
           ON Target.Dataset_ID = @datasetID AND
              Target.File_Path = Source.InstFilePath And
              Target.File_Size_Rank = Source.FileSizeRank
    WHERE Target.Dataset_ID = @datasetID AND
          Target.Deleted = 0 AND
          Source.InstFilePath IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------
    -- Possibly validate the dataset type defined for this dataset
    -----------------------------------------------
    --
    If @validateDatasetType <> 0
    Begin
        exec dbo.validate_dataset_type @datasetID, @message=@message output, @infoonly=@infoOnly
    End

    -----------------------------------------------
    -- Add/update T_Dataset_Device_Map
    -----------------------------------------------
    --
    Exec update_dataset_device_info_xml @datasetID=@datasetID, @datasetInfoXML=@datasetInfoXML, @infoOnly=0, @skipValidation=1

    Set @message = 'Dataset info update successful'

Done:

    -- Note: ignore error code 53600; a log message has already been made
    If @myError Not In (0, 53600)
    Begin
        If @message = ''
            Set @message = 'Error in update_dataset_file_info_xml'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        If @InfoOnly = 0
            Exec post_log_entry 'Error', @message, 'update_dataset_file_info_xml'
    End

    If Len(@message) > 0 AND @InfoOnly <> 0
        Print @message

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512)
    If IsNull(@datasetName, '') = ''
        Set @usageMessage = 'Dataset ID: ' + @datasetIdText
    Else
        Set @usageMessage = 'Dataset: ' + @datasetName

    If @InfoOnly = 0
        Exec post_usage_log_entry 'update_dataset_file_info_xml', @usageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_dataset_file_info_xml] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_dataset_file_info_xml] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[UpdateDatasetFileInfoXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[UpdateDatasetFileInfoXML]
/****************************************************
** 
**  Desc:   Updates the information for the dataset specified by @DatasetID
**          If @DatasetID is 0, then will use the dataset name defined in @DatasetInfoXML
**          If @DatasetID is non-zero, then will validate that the Dataset Name in the XML corresponds
**          to the dataset ID specified by @DatasetID
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
**          05/13/2010 mem - Added parameter @ValidateDatasetType
**          05/14/2010 mem - Now updating T_Dataset_Info.Scan_Types
**          08/03/2010 mem - Removed unneeded fields from the T_Dataset_Info MERGE Source
**          09/01/2010 mem - Now checking for invalid dates and storing Null in Acq_Time_Start and Acq_Time_End If invalid
**          09/09/2010 mem - Fixed bug extracting StartTime and EndTime values
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          08/21/2012 mem - Now including DatasetID in the error message
**          04/18/2014 mem - Added support for ProfileScanCountMS1, ProfileScanCountMS2, CentroidScanCountMS1, and CentroidScanCountMS2
**          02/24/2015 mem - Now validating that @DatasetID exists in T_Dataset
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW If not authorized
**          06/13/2018 mem - Store instrument files info in T_Dataset_Files
**          06/25/2018 mem - Populate the File_Size_Rank column
**    
*****************************************************/
(
    @DatasetID int = 0,                     -- If this value is 0, will determine the dataset name using the contents of @DatasetInfoXML
    @DatasetInfoXML xml,                    -- XML describing the properties of a single dataset
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0,
    @ValidateDatasetType tinyint = 1        -- If non-zero, will call ValidateDatasetType after updating T_Dataset_ScanTypes
)
As
    set nocount on
    
    declare @myError int = 0
    declare @myRowCount int = 0

    Declare @DatasetName varchar(128)
    Declare @DatasetIDCheck int

    Declare @StartTime varchar(32)
    Declare @EndTime varchar(32)
    
    Declare @AcqTimeStart datetime
    Declare @AcqTimeEnd datetime

    Declare @msg varchar(1024)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'UpdateDatasetFileInfoXML', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End
    
    -----------------------------------------------------------
    -- Create temp tables to hold the data
    -----------------------------------------------------------

    Declare @DSInfoTable table (
        Dataset_ID int NULL,
        Dataset_Name varchar (128) NOT NULL,
        ScanCount int NULL,
        ScanCountMS int NULL,
        ScanCountMSn int NULL,
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
    
    Declare @InstrumentFilesTable table (
        InstFilePath varchar(512) NOT NULL,     -- Relative file path of the instrument ifle
        InstFileHash varchar(64) NULL,
        InstFileHashType varchar(32) NULL,      -- Should always be SHA1
        InstFileSize bigint NULL
    )
    
    Declare @DuplicateDatasetsTable Table (
        Dataset_ID int NOT NULL,
        MatchingFileCount int NOT NULL,
        Allow_Duplicates tinyint NULL
    )

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    
    Set @DatasetID = IsNull(@DatasetID, 0)
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @ValidateDatasetType = IsNull(@ValidateDatasetType, 1)
    
    ---------------------------------------------------
    -- Parse out the dataset name from @DatasetInfoXML
    -- If this parse fails, there is no point in continuing
    ---------------------------------------------------
    
    SELECT @DatasetName = DSName
    FROM (SELECT @DatasetInfoXML.value('(/DatasetInfo/Dataset)[1]', 'varchar(128)') AS DSName
         ) LookupQ
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error extracting the dataset name from @DatasetInfoXML for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End
        
    If @myRowCount = 0 or IsNull(@DatasetName, '') = ''
    Begin
        set @message = 'XML in @DatasetInfoXML is not in the expected form for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML; Could not match /DatasetInfo/Dataset'
        Set @myError = 50000
        goto Done
    End
    
    ---------------------------------------------------
    -- Parse the contents of @DatasetInfoXML to populate @DSInfoTable
    -- Skip the StartTime and EndTime values for now since they might have invalid dates
    ---------------------------------------------------
    --
    INSERT INTO @DSInfoTable (
        Dataset_ID,
        Dataset_Name,
        ScanCount,
        ScanCountMS,
        ScanCountMSn,
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
    SELECT  @DatasetID AS DatasetID,
            @DatasetName AS Dataset,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ScanCount)[1]', 'int') AS ScanCount,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ScanCountMS)[1]', 'int') AS ScanCountMS,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ScanCountMSn)[1]', 'int') AS ScanCountMSn,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/Elution_Time_Max)[1]', 'real') AS Elution_Time_Max,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/AcqTimeMinutes)[1]', 'real') AS AcqTimeMinutes,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/FileSizeBytes)[1]', 'bigint') AS FileSizeBytes,       
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Max_MS)[1]', 'real') AS TIC_Max_MS,
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Max_MSn)[1]', 'real') AS TIC_Max_MSn,
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Max_MS)[1]', 'real') AS BPI_Max_MS,
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Max_MSn)[1]', 'real') AS BPI_Max_MSn,
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Median_MS)[1]', 'real') AS TIC_Median_MS,
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/TIC_Median_MSn)[1]', 'real') AS TIC_Median_MSn,
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Median_MS)[1]', 'real') AS BPI_Median_MS,
            @DatasetInfoXML.value('(/DatasetInfo/TICInfo/BPI_Median_MSn)[1]', 'real') AS BPI_Median_MSn,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ProfileScanCountMS1)[1]', 'int') AS ProfileScanCountMS1,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/ProfileScanCountMS2)[1]', 'int') AS ProfileScanCountMS2,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/CentroidScanCountMS1)[1]', 'int') AS CentroidScanCountMS1,
            @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/CentroidScanCountMS2)[1]', 'int') AS CentroidScanCountMS2
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error extracting data from @DatasetInfoXML for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End

    ---------------------------------------------------
    -- Update or Validate Dataset_ID in @DSInfoTable
    ---------------------------------------------------
    --
    If @DatasetID = 0
    Begin
        UPDATE @DSInfoTable
        SET Dataset_ID = DS.Dataset_ID
        FROM @DSInfoTable Target
             INNER JOIN T_Dataset DS
               ON Target.Dataset_Name = DS.Dataset_Num
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        If @myRowCount = 0
        Begin
            Set @message = 'Warning: dataset "' + @DatasetName + '" not found in table T_Dataset by SP UpdateDatasetFileInfoXML'
            Set @myError = 50001
            Goto Done
        End
        
        -- Update @DatasetID
        SELECT @DatasetID = Dataset_ID
        FROM @DSInfoTable
        
    End
    Else
    Begin
    
        -- @DatasetID was non-zero
        
        -- Validate that @DatasetID exists in T_Dataset
        If Not Exists (SELECT * FROM T_Dataset WHERE Dataset_ID = @DatasetID)
        Begin
            Set @message = 'Warning: dataset ID "' + Cast(@DatasetID as varchar(12)) + '" not found in table T_Dataset by SP UpdateDatasetFileInfoXML'
            Set @myError = 50002
            Goto Done
        End
        
        UPDATE @DSInfoTable
        SET Dataset_ID = DS.Dataset_ID
        FROM @DSInfoTable Target
             INNER JOIN T_Dataset DS
               ON Target.Dataset_Name = DS.Dataset_Num
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        If @myRowCount = 0
        Begin
            Set @message = 'Warning: dataset "' + @DatasetName + '" not found in table T_Dataset by SP UpdateDatasetFileInfoXML'
            Set @myError = 50003
            Goto Done
        End
        
        -- Validate the dataset name in @DSInfoTable against T_Dataset
    
        SELECT @DatasetIDCheck = DS.Dataset_ID
        FROM @DSInfoTable Target
             INNER JOIN T_Dataset DS
             ON Target.Dataset_Name = DS.Dataset_Num
               
        If @DatasetIDCheck <> @DatasetID
        Begin
            Set @message = 'Error: dataset ID values for ' + @DatasetName + ' do not match; expecting ' + Convert(varchar(12), @DatasetIDCheck) + ' but stored procedure param @DatasetID is ' + Convert(varchar(12), @DatasetID)
            Set @myError = 50004
            Goto Done
        End
    End
    
    ---------------------------------------------------
    -- Now parse out the start and End times
    -- Initially extract as strings in case they're out of range for the datetime date type
    ---------------------------------------------------
    --
    SELECT @StartTime = @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/StartTime)[1]', 'varchar(32)'),
           @EndTime = @DatasetInfoXML.value('(/DatasetInfo/AcquisitionInfo/EndTime)[1]', 'varchar(32)')

    If IsDate(@StartTime) <> 0
        Set @AcqTimeStart = Convert(datetime, @StartTime)

    If IsDate(@EndTime) <> 0
        Set @AcqTimeEnd = Convert(datetime, @EndTime)
    Else
    Begin
        -- End Time is invalid
        -- If the start time is valid, add the acquisition time length to the End time 
        -- (though, typically, If one is invalid the other will be invalid too)
        -- IMS .UIMF files acquired in summer 2010 had StartTime values of 0410-08-29 (year 410) due to a bug
                
        If Not @AcqTimeStart Is Null
            SELECT @AcqTimeEnd = DateAdd(minute, AcqTimeMinutes, @AcqTimeStart)
            FROM @DSInfoTable
    End
        
    UPDATE @DSInfoTable
    Set Acq_Time_Start = @AcqTimeStart,
        Acq_Time_End = @AcqTimeEnd

    ---------------------------------------------------
    -- Now extract out the ScanType information
    ---------------------------------------------------
    --
    INSERT INTO @ScanTypesTable (ScanType, ScanCount, ScanFilter)
    SELECT ScanType, ScanCount, ScanFilter
    FROM (    SELECT  xmlNode.value('.', 'varchar(64)') AS ScanType,
                    xmlNode.value('@ScanCount', 'int') AS ScanCount,
                    xmlNode.value('@ScanFilterText', 'varchar(256)') AS ScanFilter        
            FROM   @DatasetInfoXML.nodes('/DatasetInfo/ScanTypes/ScanType') AS R(xmlNode)
    ) LookupQ
    WHERE Not ScanType IS NULL     
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error parsing ScanType nodes in @DatasetInfoXML for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End

    ---------------------------------------------------
    -- Now extract out the instrument files
    ---------------------------------------------------
    --
    INSERT INTO @InstrumentFilesTable ( InstFilePath, InstFileHash, InstFileHashType, InstFileSize)
    SELECT instFiles.InstrumentFile.value('(.)[1]','varchar(512)') As InstFilePath,
           instFiles.InstrumentFile.value('(./@Hash)[1]','varchar(64)') As InstFileHash,
           instFiles.InstrumentFile.value('(./@HashType)[1]','varchar(32)') As InstFileHashType,
           instFiles.InstrumentFile.value('(./@Size)[1]','bigint') As InstFileSize
    FROM @DatasetInfoXML.nodes('/DatasetInfo/AcquisitionInfo/InstrumentFiles/InstrumentFile') As instFiles(InstrumentFile)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error parsing InstrumentFile nodes in @DatasetInfoXML for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End    

    ---------------------------------------------------
    -- Validate the hash type
    ---------------------------------------------------
    --
    Declare @unrecognizedHashType varchar(32) = ''

    SELECT @unrecognizedHashType = InstFileHashType
    FROM @InstrumentFilesTable
    WHERE Not InstFileHashType In ('SHA1')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    
    If @myRowCount > 1
    Begin
        set @msg = 'Unrecognized file hash type: ' + @unrecognizedHashType + '; all rows in T_Dataset_File are assumed to be SHA1. ' + 
                   'Will add the file info anyway, but this hashtype could be problematic elsewhere'

        Exec PostLogEntry 'Error', @msg, 'UpdateDatasetFileInfoXML'
    End    

    ---------------------------------------------------
    -- Check whether this is a duplicate dataset
    -- Look for an existing dataset with the same file has values but a different dataset ID
    ---------------------------------------------------
    
    Declare @instrumentFileCount int = 0

    SELECT @instrumentFileCount = Count(*)
    FROM @InstrumentFilesTable

    If @instrumentFileCount > 0
    Begin
        INSERT INTO @DuplicateDatasetsTable( Dataset_ID,
                                             MatchingFileCount)
        SELECT DSFiles.Dataset_ID,
               Count(*) AS MatchingFiles
        FROM T_Dataset_Files DSFiles
             INNER JOIN @InstrumentFilesTable NewDSFiles
               ON DSFiles.File_Hash = NewDSFiles.InstFileHash
        WHERE DSFiles.Dataset_ID <> @DatasetID And DSFiles.Deleted = 0
        GROUP BY DSFiles.Dataset_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Error looking for matching instrument files in T_Dataset_Files for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
            goto Done
        End

        Declare @fileOrFiles varchar(10) = 'file'
        If @instrumentFileCount > 1
            Set @fileOrFiles = 'files'

        Declare @duplicateDatasetID int = 0
        Declare @duplicateDatasetInfo varchar(512) = 
            ' DatasetID ' + Convert(varchar(12), @duplicateDatasetID) + 
            ' has the same instrument ' + @fileOrFiles + ' as DatasetID ' + Convert(varchar(12), @DatasetID) +                     
            '; see table T_Dataset_Files'

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

            -- The message "Duplicate dataset found" is used by a SQL Server Agent job that notifies admins hourly if a duplicate dataset is uploaded
            Set @message = 'Duplicate dataset found:' + @duplicateDatasetInfo

            Exec PostLogEntry 'Error', @message, 'UpdateDatasetFileInfoXML'

            -- This error code is used by stored procedure UpdateContext in the DMS_Capture database
            Set @myError = 53600
            goto Done

        End

        If Exists (SELECT * FROM @DuplicateDatasetsTable WHERE MatchingFileCount >= @instrumentFileCount And Allow_Duplicates = 1)
        Begin
            SELECT TOP 1 @duplicateDatasetID = Dataset_ID
            FROM @DuplicateDatasetsTable 
            WHERE MatchingFileCount >= @instrumentFileCount And Allow_Duplicates = 1
            ORDER BY Dataset_ID Desc
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            Set @msg = 'Allowing duplicate dataset to be added since Allow_Duplicates is 1: ' + @duplicateDatasetInfo

            Exec PostLogEntry 'Warning', @msg, 'UpdateDatasetFileInfoXML'
        End
    End

    If @infoOnly <> 0
    Begin
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------
        
        SELECT *
        FROM @DSInfoTable

        SELECT *
        FROM @ScanTypesTable
        
        SELECT *
        FROM @InstrumentFilesTable
        
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
        set @message = 'Error updating T_Dataset for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End    

    -----------------------------------------------
    -- Add/Update T_Dataset_Info using a MERGE statement
    -----------------------------------------------
    --
    MERGE T_Dataset_Info AS target
    USING 
        (Select Dataset_ID, ScanCountMS, ScanCountMSn,
                Elution_Time_Max, AcqTimeMinutes, 
                TIC_Max_MS, TIC_Max_MSn,
                BPI_Max_MS, BPI_Max_MSn,
                TIC_Median_MS, TIC_Median_MSn,
                BPI_Median_MS, BPI_Median_MSn,
                ProfileScanCount_MS, ProfileScanCount_MSn,
                CentroidScanCount_MS, CentroidScanCount_MSn
         FROM @DSInfoTable
        ) AS Source (Dataset_ID, ScanCountMS, ScanCountMSn,
                     Elution_Time_Max, AcqTimeMinutes, 
                     TIC_Max_MS, TIC_Max_MSn,
                     BPI_Max_MS, BPI_Max_MSn,
                     TIC_Median_MS, TIC_Median_MSn,
                     BPI_Median_MS, BPI_Median_MSn,
                     ProfileScanCount_MS, ProfileScanCount_MSn,
                     CentroidScanCount_MS, CentroidScanCount_MSn)
    ON (target.Dataset_ID = Source.Dataset_ID)
    WHEN Matched 
        THEN UPDATE 
            Set ScanCountMS = Source.ScanCountMS,
                ScanCountMSn = Source.ScanCountMSn,
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
        INSERT (Dataset_ID, ScanCountMS, 
                ScanCountMSn, Elution_Time_Max, 
                TIC_Max_MS, TIC_Max_MSn, 
                BPI_Max_MS, BPI_Max_MSn, 
                TIC_Median_MS, TIC_Median_MSn, 
                BPI_Median_MS, BPI_Median_MSn, 
                ProfileScanCount_MS, ProfileScanCount_MSn,
                CentroidScanCount_MS, CentroidScanCount_MSn,
                Last_Affected )
        VALUES (Source.Dataset_ID, Source.ScanCountMS, Source.ScanCountMSn, Source.Elution_Time_Max,
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
        set @message = 'Error updating T_Dataset_Info for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End    

    -----------------------------------------------
    -- Cannot use a Merge statement on T_Dataset_ScanTypes
    --  since some datasets (e.g. MRM) will have multiple entries 
    --  of the same scan type but different ScanFilter values
    -- Thus, simply delete existing rows then add new ones
    -----------------------------------------------
    --
    DELETE FROM T_Dataset_ScanTypes
    WHERE Dataset_ID = @DatasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    INSERT INTO T_Dataset_ScanTypes ( Dataset_ID, ScanType, ScanCount, ScanFilter )
    SELECT @DatasetID AS Dataset_ID, ScanType, ScanCount, ScanFilter
    FROM @ScanTypesTable
    ORDER BY Dataset_ID, ScanType
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error updating T_Dataset_ScanTypes for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End    

    -----------------------------------------------
    -- Update the Scan_Types field in T_Dataset_Info for this dataset
    -----------------------------------------------
    --
    UPDATE T_Dataset_Info
    SET Scan_Types = DSTypes.ScanTypeList
    FROM T_Dataset DS
         INNER JOIN T_Dataset_Info DSInfo
           ON DSInfo.Dataset_ID = DS.Dataset_ID
         CROSS APPLY GetDatasetScanTypeList ( DS.Dataset_ID ) DSTypes
    WHERE DS.Dataset_ID = @DatasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------
    -- Add/Update T_Dataset_Files using a Merge statement
    -----------------------------------------------
    --
    MERGE T_Dataset_Files As target
    USING 
        (SELECT @DatasetID, InstFilePath, InstFileSize, InstFileHash
         FROM @InstrumentFilesTable
        ) AS Source (Dataset_ID, InstFilePath, InstFileSize, InstFileHash)
    ON (target.Dataset_ID = Source.Dataset_ID And Target.File_Path = Source.InstFilePath)
    WHEN Matched 
        THEN UPDATE 
            Set File_Size_Bytes = Source.InstFileSize,
                File_Hash = Source.InstFileHash
    WHEN Not Matched THEN
        INSERT (Dataset_ID, File_Path, 
                File_Size_Bytes, File_Hash)
        VALUES (Source.Dataset_ID, Source.InstFilePath, Source.InstFileSize, Source.InstFileHash)
    ;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error updating T_Dataset_Files for DatasetID ' + Convert(varchar(12), @DatasetID) + ' in SP UpdateDatasetFileInfoXML'
        goto Done
    End

    -- Look for extra files that need to be deleted
    --
    DELETE T_Dataset_Files
    FROM T_Dataset_Files Target
         LEFT OUTER JOIN @InstrumentFilesTable Source
           ON Target.Dataset_ID = @DatasetID AND
              Target.File_Path = Source.InstFilePath
    WHERE Target.Dataset_ID = @DatasetID AND
          Source.InstFilePath IS NULL     
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------
    -- Update the File_Size_Rank column for this dataset
    -----------------------------------------------
    --
    UPDATE T_Dataset_Files
    SET File_Size_Rank = SrcQ.Size_Rank
    FROM T_Dataset_Files Target
         INNER JOIN ( SELECT Dataset_ID,
                             File_Path,
                             File_Size_Bytes,
                             File_Hash,
                             Dataset_File_ID,
                             Row_Number() OVER ( 
                                PARTITION BY Dataset_ID 
                                ORDER BY Deleted DESC, File_Size_Bytes DESC 
                                ) AS Size_Rank
                      FROM T_Dataset_Files
                      WHERE Dataset_ID = @DatasetID 
                    ) SrcQ
           ON Target.Dataset_File_ID = SrcQ.Dataset_File_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------
    -- Possibly validate the dataset type defined for this dataset
    -----------------------------------------------
    --
    If @ValidateDatasetType <> 0
        exec dbo.ValidateDatasetType @DatasetID, @message=@message output, @infoonly=@infoOnly

    Set @message = 'Dataset info update successful'
    
Done:

    -- Note: ignore error code 53600; a log message has already ben made
    If @myError Not In (0, 53600)
    Begin
        If @message = ''
            Set @message = 'Error in UpdateDatasetFileInfoXML'
        
        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
        
        If @InfoOnly = 0
            Exec PostLogEntry 'Error', @message, 'UpdateDatasetFileInfoXML'
    End
    
    If Len(@message) > 0 AND @InfoOnly <> 0
        Print @message

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    If IsNull(@DatasetName, '') = ''
        Set @UsageMessage = 'Dataset ID: ' + Convert(varchar(12), @DatasetID)
    Else
        Set @UsageMessage = 'Dataset: ' + @DatasetName

    If @InfoOnly = 0
        Exec PostUsageLogEntry 'UpdateDatasetFileInfoXML', @UsageMessage

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetFileInfoXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetFileInfoXML] TO [Limited_Table_Write] AS [dbo]
GO

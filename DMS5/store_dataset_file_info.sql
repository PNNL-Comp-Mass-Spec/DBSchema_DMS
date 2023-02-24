/****** Object:  StoredProcedure [dbo].[store_dataset_file_info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[store_dataset_file_info]
/****************************************************
**
**  Desc:   Stores SHA-1 hash info or file size info for dataset files
**
**          By default, only adds new data to T_Dataset_Files; will not replace existing values.
**          Set @updateExisting to 'Force' to forcibly replace existing hash values or change existing file sizes
**
**          Filenames cannot contain spaces
**
**          Assumes data is formatted as a SHA-1 hash (40 characters) followed by the relative file path, with one file per line
**          Alternatively, can have file size followed by relative file path
**
**          Hash values (or file sizes) and file paths can be space or tab-separated
**          Determines dataset name by removing the extension from the filename (e.g. .raw)
**
**          Alternatively, the input can be three columns, formatted as SHA-1 hash (or file size), relative path, and dataset name or dataset ID
**
**  Example 2 column input (will auto replace ' *' with ' '):
**
**    b1edc1310d7989f2107d7d2be903ae756698608d *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw
**    9f1576f73c290ffa763cf45ffa497af370036719 *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f02_19Mar17_Bane_Rep-16-12-04.raw
**    3101f1e3b2c548ba6b881739a3682f4971d1ea8a *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f03_20Mar17_Bane_Rep-16-12-04.raw
**
**  Example 2 column input with file size and relative file path (which is simply the filename if the file is in the dataset directory)
**
**    1,729,715,419 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw
**    1,679,089,387 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f02_19Mar17_Bane_Rep-16-12-04.raw
**    1,708,057,145 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f03_20Mar17_Bane_Rep-16-12-04.raw
**
**  Example 3 column input (Dataset Name):
**
**    2c6f81f3b421ac9780bc3dc61133e13c9add9097  DATA.MS Bet_Se_Pel_M
**    f3bba221c7d794826eadda5d8bd8ebffd1c7fe15  DATA.MS Bet_Se_CoC_Med_M
**    2ce8bafc5506c76ef99343e882f1ed3e55e528f4  DATA.MS Bet_Rg_Pel_M
**
**  Example 3 column input (Dataset ID):
**
**    800076cfee2f23efa076394676db9a46c317ed0a  ser 739716
**    6f4959e18d1ddc0ed0a11fc1ba7028a369ba4c25  ser 739715
**    16ba36087f53684be77e3512ea131331044dda63  ser 739714
**
**  Example 3 column input with file size, file name, and Dataset Name
**    4609024   DATA.MS Bet_Rg_Pel_M
**    2072576   DATA.MS Bet_Se_CoC_Med_M
**    4979200   DATA.MS Bet_Se_Pel_M
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/02/2019 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetFileInfo varchar(max),          -- hash codes and file names
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0,
    @updateExisting Varchar(12) = ''
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    -- The following will have the current dataset name and ID when stepping through rows of data in @datasetFileInfo
    Declare @datasetName varchar(128) = ''
    Declare @datasetID Int = 0
    Declare @datasetIdText varchar(12) = '0'

    Declare @msg varchar(1024)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'StoreDatasetFileHashInfo', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -----------------------------------------------------------
    -- Create temp tables to hold the data
    -----------------------------------------------------------

    CREATE TABLE #Tmp_FileData (
        EntryID int NOT NULL identity(1,1),
        Value varchar(2048) Null
    )

    CREATE UNIQUE INDEX #IX_#mp_FileData_EntryID ON #Tmp_FileData (EntryID)

    CREATE TABLE #Tmp_DataColumns (
        EntryID int NOT NULL,
        Value varchar(2048) NULL
    )

    CREATE UNIQUE INDEX #IX_Tmp_DataColumns_EntryID ON #Tmp_DataColumns (EntryID)

    CREATE TABLE #Tmp_HashUpdates (
        Dataset_ID int NOT NULL,
        InstFilePath varchar(512) NOT NULL,     -- Relative file path of the instrument ifle
        InstFileHash varchar(64) NOT NULL
    )

    CREATE UNIQUE INDEX #IX_Tmp_HashUpdates ON #Tmp_HashUpdates (Dataset_ID, InstFilePath)

    CREATE TABLE #Tmp_SizeUpdates (
        Dataset_ID int NOT NULL,
        InstFilePath varchar(512) NOT NULL,     -- Relative file path of the instrument ifle
        InstFileSize bigint NOT NULL
    )

    CREATE UNIQUE INDEX #IX_Tmp_SizeUpdates ON #Tmp_SizeUpdates (Dataset_ID, InstFilePath)

    CREATE TABLE #Tmp_Warnings (
        EntryID int NOT NULL identity(1,1),
        Warning varchar(2048) Null,
        RowText Varchar(2048) Null
    )

    CREATE TABLE #Tmp_SummaryOfChanges (
        Dataset_ID Int Not Null,
        Update_Target varchar(128),
        Update_Action varchar(20),
        FileSize Bigint Null,
        FileHash Varchar(64) Null
    )

    CREATE TABLE #Tmp_UpdatedDatasets (
        Dataset_ID Int Not Null
    )

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @updateExisting= IsNull(@updateExisting, '')

    -----------------------------------------
    -- Split @datasetFileInfo on carriage returns
    -- Store the data in #Tmp_FileData
    -----------------------------------------

    Declare @delimiter varchar(1) = ''

    If CHARINDEX(CHAR(10), @datasetFileInfo) > 0
        Set @delimiter = CHAR(10)
    Else
        Set @delimiter = CHAR(13)

    INSERT INTO #Tmp_FileData (Value)
    Select Value
    FROM dbo.parse_delimited_list(@datasetFileInfo, @delimiter, 'store_dataset_file_info')
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error

    If Not Exists (SELECT * FROM #Tmp_FileData)
    Begin
        Set @message = 'Nothing returned when splitting the Dataset File List on CR or LF'
        Set @myError = 53004
        Goto Done
    End

    Declare @Continue tinyint = 1
    Declare @EntryID int = 0
    Declare @EntryIDEnd int = 0

    Declare @charIndex int
    Declare @colCount Int
    Declare @lastPeriodLoc int
    Declare @skipRow Tinyint

    Declare @Row varchar(2048)

    Declare @fileHashOrSize varchar(128)
    Declare @datasetNameOrId varchar(255)

    Declare @fileHash varchar(128)
    Declare @fileSizeText varchar(128)
    Declare @fileSizeBytes Bigint

    -- Relative file path (simply filename if the file is in the dataset directory)
    Declare @filePath varchar(225)

    Declare @existingSize Bigint
    Declare @existingHash Varchar(64)

    SELECT @EntryIDEnd = MAX(EntryID)
    FROM #Tmp_FileData

    -----------------------------------------
    -- Parse the host list
    -----------------------------------------
    --
    While @EntryID < @EntryIDEnd
    Begin -- <a>
        SELECT TOP 1 @EntryID = EntryID, @Row = Value
        FROM #Tmp_FileData
        WHERE EntryID > @EntryID
        ORDER BY EntryID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        -- @Row should now be empty, or contain something like the following:

        -- Hash and Filename
        -- b1edc1310d7989f2107d7d2be903ae756698608d *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw

        -- FileSize and Filename
        -- 1,729,715,419 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw

        -- Hash, Filename, DatasetName
        -- 2c6f81f3b421ac9780bc3dc61133e13c9add9097 DATA.MS Bet_Se_Pel_M

        -- Hash, Filename, DatasetId
        -- 800076cfee2f23efa076394676db9a46c317ed0a ser 739716

        -- FileSize, Filename, DatasetName
        -- 4609024  DATA.MS Bet_Rg_Pel_M

        Set @Row = Replace (@Row, CHAR(10), '')
        Set @Row = Replace (@Row, CHAR(13), '')
        Set @Row = LTrim(RTrim(IsNull(@Row, '')))

        -- Replace tabs with spaces
        Set @Row = Replace (@Row, CHAR(9), ' ')

        If @Row <> ''
        Begin -- <b>

            -- Split the row on spaces
            TRUNCATE TABLE #Tmp_DataColumns
            Set @delimiter = ' '

            INSERT INTO #Tmp_DataColumns (EntryID, Value)
            SELECT EntryID, Value
            FROM dbo.parse_delimited_list_ordered(@Row, @delimiter, 0)
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error

            Set @colCount = @myRowCount

            If @colCount < 2
            Begin
                Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since less than 2 column', @Row)
            End
            Else
            Begin -- <c>
                Set @fileHash = ''
                Set @fileSizeText = ''
                Set @fileSizeBytes = 0
                Set @filePath = ''

                Set @datasetNameOrID= ''
                Set @datasetName = 'EntryID_' + Cast(@EntryID As Varchar(12))
                Set @datasetID = 0
                Set @datasetIdText = '0'
                Set @skipRow = 0

                SELECT @fileHashOrSize = Value FROM #Tmp_DataColumns WHERE EntryID = 1
                SELECT @filePath = Value FROM #Tmp_DataColumns WHERE EntryID = 2

                -- SHA1Sum prepends filenames with *; remove the * if present
                Set @filePath = Replace (@filePath, '*', '')

                If @colCount = 2
                Begin -- <d1>
                    -- Determine the dataset name from the file name
                    If @filePath Like '%.%'
                    Begin
                        Set @lastPeriodLoc = Len(@filePath) - CharIndex('.', Reverse(@filePath))
                        Set @datasetName = Substring(@filePath, 1, @lastPeriodLoc)
                    End
                    Else
                    Begin
                        Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since Filename "' + @filePath + '" does not contain a period', @Row)
                        Set @skipRow= 1
                    End
                End -- </d1>
                Else
                Begin -- <d2>
                    SELECT @datasetNameOrId = Value FROM #Tmp_DataColumns WHERE EntryID = 3

                    Set @datasetId = Try_Cast(@datasetNameOrID As Int)
                    If Not @datasetId Is Null
                    Begin
                        Set @datasetIdText = Cast(@datasetId As Varchar(12))

                        -- Lookup the dataset name
                        Select @datasetName = Dataset_Num
                        From T_Dataset
                        Where Dataset_ID = @datasetId
                        --
                        SELECT @myRowCount = @@rowcount, @myError = @@error

                        If @myRowCount < 1
                        Begin
                            Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since Dataset ID not found in T_Dataset: ' + @datasetIdText, @Row)
                            Set @skipRow= 1
                        End
                    End
                    Else
                    Begin
                        Set @datasetName = @datasetNameOrId
                    End

                End -- </d2>

                If @skipRow = 0
                Begin
                    -- Validate the dataset name
                    Select @datasetId = Dataset_ID
                    From T_Dataset
                    Where Dataset_Num = @datasetName
                    --
                    SELECT @myRowCount = @@rowcount, @myError = @@error

                    If @myRowCount < 1
                    Begin
                        Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since Dataset Name not found in T_Dataset: ' + @datasetName, @Row)
                        Set @skipRow= 1
                    End

                    Set @datasetIdText = Cast(@datasetId As Varchar(12))
                End

                If @skipRow = 0 And (@fileHashOrSize = '')
                Begin
                    Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since file hash or size is blank', @Row)
                    Set @skipRow= 1
                End

                If @skipRow = 0 And (@filePath = '')
                Begin
                    Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since file path (typically filename) is blank', @Row)
                    Set @skipRow= 1
                End

                If @skipRow = 0
                Begin
                    -- Determine whether we're entering hash values or file sizes

                    If Len(@fileHashOrSize) < 40
                    Begin
                        Set @fileSizeBytes = try_cast(Replace(@fileHashOrSize, ',', '') As Bigint)

                        If @fileSizeBytes Is Null
                        Begin
                            Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since file size is not a number (and is less than 40 characters, so is not a hash): ' + @fileHashOrSize, @Row)
                            Set @skipRow= 1
                        End
                    End
                    Else
                    Begin
                        If Len(@fileHashOrSize) > 40
                        Begin
                            Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since file hash is not 40 characters long: ' + @fileHashOrSize, @Row)
                            Set @skipRow= 1
                        End
                        Else
                        Begin
                            Set @fileHash = @fileHashOrSize
                        End
                    End
                End

                If @skipRow = 0
                Begin -- <e>
                    -- Validate that the update is allowed, then cache it

                    If @fileHash = '' And @fileSizeBytes > 0
                    Begin -- <f>
                        -- Updating file size
                        If @updateExisting <> 'Force'
                        Begin
                            -- Assure that we're not updating an existing file size
                            Set @existingSize = 0

                            Select @existingSize = File_Size_Bytes
                            From T_Dataset_Files
                            Where Dataset_ID = @datasetID And File_Path = @filePath
                            --
                            SELECT @myRowCount = @@rowcount, @myError = @@error

                            If @myRowCount = 1 And IsNull(@existingSize, 0) > 0
                            Begin
                                Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since file size is already defined for ' + @filePath + ', Dataset ID ' + @datasetIdText, @Row)
                                Set @skipRow= 1
                            End
                        End

                        If @skipRow = 0
                        Begin
                            Insert Into #Tmp_SizeUpdates (Dataset_ID, InstFilePath, InstFileSize)
                            Values (@datasetID, @filePath, @fileSizeBytes)
                        End
                    End -- </f>

                    If @fileHash <> ''
                    Begin -- <g>
                        If @updateExisting <> 'Force'
                        Begin
                            -- Assure that we're not updating an existing file size
                            Set @existingHash = ''

                            Select @existingHash = File_Hash
                            From T_Dataset_Files
                            Where Dataset_ID = @datasetID And File_Path = @filePath
                            --
                            SELECT @myRowCount = @@rowcount, @myError = @@error

                            If @myRowCount = 1 And Len(IsNull(@existingHash, '')) > 0
                            Begin
                                Insert Into #Tmp_Warnings (Warning, RowText) Values('Skipping row since file hash is already defined for ' + @filePath + ', Dataset ID ' + @datasetIdText, @Row)
                                Set @skipRow= 1
                            End
                        End

                        If @skipRow = 0
                        Begin
                            Insert Into #Tmp_HashUpdates (Dataset_ID, InstFilePath, InstFileHash)
                            Values (@datasetID, @filePath, @fileHash)
                        End
                    End -- </g>

                End -- </e>
            End -- </c>
        End -- </b>
    End -- </a>

    If @infoOnly <> 0
    Begin
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        Declare @itemsToUpdate Int = 0

        If Exists (Select * From #Tmp_HashUpdates)
        Begin
            SELECT *
            FROM #Tmp_HashUpdates
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error
            Set @itemsToUpdate = @itemsToUpdate + @myRowCount
        end

        If Exists (Select * From #Tmp_SizeUpdates)
        Begin
            SELECT *
            FROM #Tmp_SizeUpdates
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error
            Set @itemsToUpdate = @itemsToUpdate + @myRowCount
        End

        If @itemsToUpdate = 0
        Begin
            Select 'No valid data was found in @datasetFileInfo' As Warning
        End
        Goto Done
    End

    -----------------------------------------------
    -- Add/Update hash info in T_Dataset_Files using a Merge statement
    -----------------------------------------------
    --
    MERGE T_Dataset_Files As target
    USING
        (SELECT Dataset_ID, InstFilePath, InstFileHash
         FROM #Tmp_HashUpdates
        ) AS Source (Dataset_ID, InstFilePath, InstFileHash)
    ON (target.Dataset_ID = Source.Dataset_ID And Target.File_Path = Source.InstFilePath)
    WHEN Matched
        THEN UPDATE
            Set File_Hash = Source.InstFileHash,
                Deleted = 0
    WHEN Not Matched THEN
        INSERT (Dataset_ID, File_Path, File_Hash)
        VALUES (Source.Dataset_ID, Source.InstFilePath, Source.InstFileHash)
    OUTPUT Inserted.Dataset_ID,
           'File Hash', $action,
           Null, Inserted.File_Hash
    INTO #Tmp_SummaryOfChanges;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error updating file hashes in T_Dataset_Files for DatasetID ' + @datasetIdText + ' in SP store_dataset_file_info'
        Goto Done
    End

    -----------------------------------------------
    -- Add/Update file size info in T_Dataset_Files using a Merge statement
    -----------------------------------------------
    --
    MERGE T_Dataset_Files As target
    USING
        (SELECT Dataset_ID, InstFilePath, InstFileSize
         FROM #Tmp_SizeUpdates
        ) AS Source (Dataset_ID, InstFilePath, InstFileSize)
    ON (target.Dataset_ID = Source.Dataset_ID And Target.File_Path = Source.InstFilePath)
    WHEN Matched
        THEN UPDATE
            Set File_Size_Bytes = Source.InstFileSize,
                Deleted = 0
    WHEN Not Matched THEN
        INSERT (Dataset_ID, File_Path, File_Size_Bytes)
        VALUES (Source.Dataset_ID, Source.InstFilePath, Source.InstFileSize)
    OUTPUT Inserted.Dataset_ID,
           'File Size', $action,
           Inserted.File_Size_Bytes, Null
    INTO #Tmp_SummaryOfChanges;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error updating file sizes in T_Dataset_Files for DatasetID ' + @datasetIdText + ' in SP store_dataset_file_info'
        Goto Done
    End

    Insert Into #Tmp_UpdatedDatasets (Dataset_ID)
    SELECT Dataset_ID FROM #Tmp_HashUpdates
    UNION
    SELECT Dataset_ID FROM #Tmp_SizeUpdates

    -----------------------------------------------
    -- Update the File_Size_Rank column for the datasets
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
                                ORDER BY Deleted ASC, File_Size_Bytes DESC
                                ) AS Size_Rank
                      FROM T_Dataset_Files
                      WHERE Dataset_ID In (SELECT Dataset_ID FROM #Tmp_UpdatedDatasets)
                    ) SrcQ
           ON Target.Dataset_File_ID = SrcQ.Dataset_File_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @message = 'Dataset info update successful'

    -----------------------------------------------
    -- Show the updated files
    -----------------------------------------------
    If Exists (SELECT Dataset_ID FROM #Tmp_UpdatedDatasets)
    Begin
        SELECT *
        FROM V_Dataset_Files_List_Report
        WHERE Dataset_ID In (SELECT Dataset_ID FROM #Tmp_UpdatedDatasets)
        Order By Dataset
    End

    -----------------------------------------------
    -- Show details of the update
    -----------------------------------------------
    --
    If Exists (Select * From #Tmp_SummaryOfChanges)
    Begin
        SELECT Dataset_ID,
               Update_Target,
               Update_Action,
               FileSize,
               FileHash
        FROM #Tmp_SummaryOfChanges
        ORDER BY Dataset_ID, Update_Target, Update_Action
    End

Done:
    If Exists (Select * From #Tmp_Warnings)
    Begin
        Select Warning, RowText
        From #Tmp_Warnings
        Order By EntryID
    End

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in store_dataset_file_info'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
    End

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512)
    If IsNull(@datasetName, '') = ''
        Set @usageMessage = 'Dataset ID: ' + @datasetIdText
    Else
        Set @usageMessage = 'Dataset: ' + @datasetName

    If @InfoOnly = 0
        Exec post_usage_log_entry 'store_dataset_file_info', @usageMessage

    If Len(@message) > 0
        SELECT @message As Message

    --
    Return @myError

GO

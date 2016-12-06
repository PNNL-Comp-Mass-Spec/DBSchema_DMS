/****** Object:  StoredProcedure [dbo].[UpdateMissedDMSFileInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateMissedDMSFileInfo
/****************************************************
**
**  Desc:
**		Calls UpdateDatasetFileInfoXML for datasets
**		that have info defined in T_Dataset_Info_XML
**		yet the dataset has a null value for File_Info_Last_Modified in DMS
**
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	mem
**  Date:	12/19/2011 mem - Initial version
**			02/24/2015 mem - Now skipping deleted datasets
**			05/05/2015 mem - Added parameter @ReplaceExistingData
**		  	08/02/2016 mem - Continue processing on errors (but log the error)
**
*****************************************************/
(
	@DeleteFromTableOnSuccess tinyint = 1,
	@ReplaceExistingData tinyint = 0,
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
		
	Declare @continue tinyint
	Declare @DatasetID int
	Declare @logMsg varchar(512)
	
	--------------------------------------------
	-- Validate the inputs
	--------------------------------------------
	--
	set @DeleteFromTableOnSuccess = IsNull(@DeleteFromTableOnSuccess, 1)
	set @ReplaceExistingData = IsNull(@ReplaceExistingData, 0)
	set @message = ''
	set @infoOnly = IsNull(@infoOnly, 0)
	
	--------------------------------------------
	-- Create a table to hold datasets to process
	--------------------------------------------
	--
	CREATE TABLE #TmpDatasetsToProcess (
		Dataset_ID int not null
	)
	
	CREATE CLUSTERED INDEX #Ix_TmpDatasetsToProcess ON #TmpDatasetsToProcess (Dataset_ID)
	
	--------------------------------------------
	-- Look for Datasets with entries in T_Dataset_Info_XML but null values for File_Info_Last_Modified in DMS
	--------------------------------------------
	--
	INSERT INTO #TmpDatasetsToProcess (Dataset_ID)
	SELECT DI.Dataset_ID
	FROM T_Dataset_Info_XML DI
	     LEFT OUTER JOIN S_DMS_T_Dataset
	       ON DI.Dataset_ID = S_DMS_T_Dataset.Dataset_ID
	WHERE (S_DMS_T_Dataset.File_Info_Last_Modified IS NULL Or @ReplaceExistingData <> 0)
	--
	SELECT @myRowCount = @@RowCount

	--------------------------------------------
	-- Delete any entries that don't exist in S_DMS_T_Dataset
	--------------------------------------------
	--
	DELETE #TmpDatasetsToProcess
	FROM #TmpDatasetsToProcess DP
	     LEFT OUTER JOIN S_DMS_T_Dataset DS
	       ON DP.Dataset_ID = DS.Dataset_ID
	WHERE DS.Dataset_ID Is Null
	--
	SELECT @myRowCount = @@RowCount


	If @myRowCount > 0
	Begin
		set @message = 'Ignoring ' + Cast(@myRowCount as varchar(12)) + ' dataset(s) in T_Dataset_Info_XML because they do not exist in DMS5.T_Dataset'
		exec PostLogEntry 'Info', @message, 'UpdateMissedDMSFileInfo'
		
		--------------------------------------------
		-- Delete any entries in T_Dataset_Info_XML that were cached over 7 days ago and do not exist in S_DMS_T_Dataset
		--------------------------------------------
		--
		DELETE T_Dataset_Info_XML
		FROM T_Dataset_Info_XML DI
		     LEFT OUTER JOIN S_DMS_T_Dataset DS
		       ON DI.Dataset_ID = DS.Dataset_ID
		WHERE DI.Cache_Date < DATEADD(day, -7, GETDATE()) AND
		      DS.Dataset_ID IS NULL

	End

	--------------------------------------------
	-- Look for datasets with conflicting values for scan count or file size
	-- Will only update if the Cache_Date in T_Dataset_Info_XML is newer than
	-- the File_Info_Last_Modified date in T_Dataset
	--------------------------------------------
	--
	INSERT INTO #TmpDatasetsToProcess (Dataset_ID)
	SELECT Dataset_ID
	       -- , Scan_Count_Old, ScanCountNew
	       -- , File_Size_Bytes_Old, FileSizeBytesNew
	FROM ( SELECT Dataset_ID,
	              Scan_Count_Old,
	              File_Size_Bytes_Old,
	              DS_Info_Xml.query('/DatasetInfo/AcquisitionInfo/ScanCount').value('(/ScanCount)[1]', 'int') AS ScanCountNew,
	              DS_Info_Xml.query('/DatasetInfo/AcquisitionInfo/FileSizeBytes').value('(/FileSizeBytes)[1]', 'bigint') AS FileSizeBytesNew
	 FROM ( SELECT DI.Dataset_ID,
	                     DI.Cache_Date,
	                     S_DMS_T_Dataset.File_Info_Last_Modified,
	                     Dataset_Num,
	        DI.DS_Info_XML,
	                     S_DMS_T_Dataset.Scan_Count AS Scan_Count_Old,
	                     S_DMS_T_Dataset.File_Size_Bytes AS File_Size_Bytes_Old
	              FROM T_Dataset_Info_XML DI
	              INNER JOIN S_DMS_T_Dataset
	                     ON DI.Dataset_ID = S_DMS_T_Dataset.Dataset_ID 
	                        AND
	                        DI.Cache_Date > S_DMS_T_Dataset.File_Info_Last_Modified ) InnerQ ) FilterQ
	WHERE (ScanCountNew <> ISNULL(Scan_Count_Old, 0)) OR
	      (FileSizeBytesNew <> ISNULL(File_Size_Bytes_Old, 0) AND FileSizeBytesNew > 0)
	--
	SELECT @myRowCount = @@RowCount

	
	--------------------------------------------
	-- Process each of the datasets in #TmpDatasetsToProcess
	--------------------------------------------
	
	Set @continue = 1
	Set @DatasetID = -1
	
	While @continue = 1
	Begin
		SELECT TOP 1 @DatasetID = Dataset_ID
		FROM #TmpDatasetsToProcess
		WHERE Dataset_ID > @DatasetID
		ORDER BY Dataset_ID
		--
		SELECT @myRowCount = @@RowCount
		
		If @myRowCount = 0
			Set @continue = 0
		Else
		Begin
			Exec @myError = UpdateDMSFileInfoXML @DatasetID, @DeleteFromTableOnSuccess, @message output, @infoOnly
			
			If @myError <> 0
			Begin

				If IsNull(@message, '') = ''
					Set @logMsg = 'UpdateDMSFileInfoXML returned error code ' + Cast(@myError as varchar(9)) + ' for DatasetID ' + Cast(@DatasetID as varchar(9))
				Else
					Set @logMsg = 'UpdateDMSFileInfoXML error: ' + @message
				
				If @infoOnly = 0
					Exec PostLogEntry 'Error', @logMsg, 'UpdateMissedDMSFileInfo', 22
				Else
					Print @logMsg
			End
		End
		
	End
	
	return @myError
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMissedDMSFileInfo] TO [DDL_Viewer] AS [dbo]
GO

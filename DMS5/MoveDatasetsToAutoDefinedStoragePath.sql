/****** Object:  StoredProcedure [dbo].[MoveDatasetsToAutoDefinedStoragePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure MoveDatasetsToAutoDefinedStoragePath
/****************************************************
**
**	Desc:	Updates the storage and archive locations for one or more datasets to use the
**			auto-defined storage and archive paths instead of the current storage path
**
**			Only valid for Instruments that have Auto_Define_Storage_Path 
**			enabled in T_Instrument_Name
**
**	Returns: The storage path ID; 0 if an error
**
**	Auth:	mem
**	Date:	05/12/2011 mem - Initial version
**			05/14/2011 mem - Updated the content of MoveCmd
**			06/18/2014 mem - Now passing default to udfParseDelimitedIntegerList
**			02/23/2016 mem - Add set XACT_ABORT on
**			08/19/2016 mem - CallUpdateCachedDatasetFolderPaths
**    
*****************************************************/
(
	@DatasetIDList varchar(max),	
	@infoOnly tinyint = 1,
	@message varchar(256) = ''
)
AS
	Set XACT_ABORT, nocount on

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @DatasetID int
	Declare @InstrumentID int
	Declare @Dataset varchar(128)
	Declare @RefDate datetime
	
	Declare @continue tinyint

	Declare @StoragePathID int
	Declare @StoragePathIDNew int
	
	Declare @ArchivePathID int
	Declare @ArchivePathIDNew int
	
	Declare @MoveCmd varchar(1024)
	
	Declare @CallingProcName varchar(128)
	Declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try

		-----------------------------------------
		-- Validate the inputs
		-----------------------------------------
		--
		Set @DatasetIDList = IsNull(@DatasetIDList, '')
		Set @infoOnly = IsNull(@infoOnly, 1)
		Set @message = ''	

		-----------------------------------------
		-- Parse the values in @DatasetIDList
		-----------------------------------------
		--
		
		CREATE Table #TmpDatasets (
			DatasetID int not null,
			InstrumentID int null
		)
		
		CREATE CLUSTERED INDEX #IX_TmpDatasets ON #TmpDatasets
		(
			DatasetID
		)
	
		INSERT INTO #TmpDatasets (DatasetID)
		SELECT DISTINCT Value
		FROM dbo.udfParseDelimitedIntegerList(@DatasetIDList, default)		
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		If @myRowCount = 0
		Begin
			Set @message = 'No values found in @DatasetIDList; unable to continue'
			SELECT @message AS ErrorMessage
			Return 50000
		End
		
		DELETE #TmpDatasets
		FROM #TmpDatasets
		     LEFT OUTER JOIN T_Dataset
		       ON #TmpDatasets.DatasetID = T_Dataset.Dataset_ID
		WHERE T_Dataset.Dataset_ID Is Null
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
			
		If @myRowCount > 0
		Begin
			Set @message = 'Removed ' + Convert(varchar(12), @myRowCount) + ' entries from @DatasetIDList since not present in T_Dataset'
			SELECT @message AS ErrorMessage
			Return 50001
		End
		
		-----------------------------------------
		-- Determine the instrument IDs
		-----------------------------------------
		
		UPDATE #TmpDatasets
		SET InstrumentID = T_Dataset.DS_instrument_name_ID
		FROM #TmpDatasets
		     INNER JOIN T_Dataset
		       ON #TmpDatasets.DatasetID = T_Dataset.Dataset_ID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		If @myRowCount = 0
		Begin
			Set @message = '#TmpDatasets is now empty; unable to continue'
			SELECT @message AS ErrorMessage
			Return 50002
		End
		
		-----------------------------------------
		-- Remove any instruments that don't have Auto_Define_Storage_Path defined
		-----------------------------------------
		
		IF Exists (SELECT *
				   FROM #TmpDatasets DS INNER JOIN T_Instrument_Name Inst ON Inst.Instrument_ID = DS.InstrumentID
				   WHERE Inst.Auto_Define_Storage_Path = 0)
		Begin
			SELECT DISTINCT Inst.IN_Name AS Instrument,
			                Auto_Define_Storage_Path,
			                'Skipping since does not have Auto_Define_Storage_Path defined' AS WarningMessage
			FROM #TmpDatasets DS
			     INNER JOIN T_Instrument_Name Inst
			       ON Inst.Instrument_ID = DS.InstrumentID
			WHERE Inst.Auto_Define_Storage_Path = 0
			
			DELETE #TmpDatasets
			FROM #TmpDatasets DS
			     INNER JOIN T_Instrument_Name Inst
			       ON Inst.Instrument_ID = DS.InstrumentID
			WHERE Inst.Auto_Define_Storage_Path = 0
			
		End
		
		-----------------------------------------
		-- Parse each dataset in @DatasetIDList
		-----------------------------------------
		--
		Set @continue = 1
		Set @DatasetID = 0
		
		While @continue = 1
		Begin -- <a>
		
			SELECT TOP 1 @DatasetID = #TmpDatasets.DatasetID,
			             @InstrumentID = #TmpDatasets.InstrumentID,
			             @Dataset = DS.Dataset_Num,
			             @RefDate = DS.DS_Created,
			             @StoragePathID = DS.DS_storage_path_ID
			FROM #TmpDatasets
			     INNER JOIN T_Dataset DS
			       ON #TmpDatasets.DatasetID = DS.Dataset_ID
			WHERE #TmpDatasets.DatasetID > @DatasetID
			ORDER BY #TmpDatasets.DatasetID
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
			
			If @myRowCount = 0
				Set @Continue = 0
			Else
			Begin -- <b>
				Print 'Processing ' + @Dataset
				
				-----------------------------------------
				-- Lookup the auto-defined storage path
				-----------------------------------------
				--				
				Exec @StoragePathIDNew = GetInstrumentStoragePathForNewDatasets @InstrumentID, @RefDate, @AutoSwitchActiveStorage=0, @infoOnly=0

				If @StoragePathIDNew <> 0 And @StoragePathID <> @StoragePathIDNew
				Begin -- <c1>

					SELECT @MoveCmd = OldStorage.Path + ' ' + NewStorage.Path
					FROM ( SELECT '\\' + SP_machine_name + '\' + SUBSTRING(SP_vol_name_server, 1, 1) + '$\' + SP_path + @Dataset AS Path
						   FROM T_Storage_Path
						   WHERE (SP_path_ID = @StoragePathID) 
						 ) OldStorage
						 CROSS JOIN 
						 ( SELECT '\\' + SP_machine_name + '\' + SUBSTRING(SP_vol_name_server, 1, 1) + '$\' + SP_path + @Dataset AS Path
						   FROM T_Storage_Path
						   WHERE (SP_path_ID = @StoragePathIDNew) 
						 ) NewStorage
					--
					SELECT @myRowCount = @@rowcount, @myError = @@error

					If @infoOnly = 0
					Begin -- <d1>

						UPDATE T_Dataset
						SET DS_storage_path_ID = @StoragePathIDNew
						WHERE Dataset_ID = @DatasetID
						--
						SELECT @myRowCount = @@rowcount, @myError = @@error

						
						INSERT INTO T_Dataset_Storage_Move_Log (DatasetID, StoragePathOld, StoragePathNew, MoveCmd)
						VALUES (@DatasetID, @StoragePathID, @StoragePathIDNew, @MoveCmd)
						--
						SELECT @myRowCount = @@rowcount, @myError = @@error
					End -- </d1>
					Else
						Print @MoveCmd
										
				End -- </c1>
				
				-----------------------------------------
				-- Look for this dataset in T_Dataset_Archive
				-----------------------------------------
				Set @ArchivePathID = -1
				
				SELECT @ArchivePathID = AS_storage_path_ID
				FROM T_Dataset_Archive
				WHERE (AS_Dataset_ID = @DatasetID)

			
				If @ArchivePathID >= 0
				Begin -- <c2>
					-----------------------------------------
					-- Lookup the auto-defined archive path
					-----------------------------------------
					--
					
					Exec @ArchivePathIDNew = GetInstrumentArchivePathForNewDatasets @InstrumentID, @DatasetID, @AutoSwitchActiveArchive=0, @infoOnly=0
					
					If @ArchivePathIDNew <> 0 And @ArchivePathID <> @ArchivePathIDNew
					Begin -- <d2>

						SELECT @MoveCmd = OldArchive.Path + ' ' + NewArchive.Path
						FROM ( SELECT REPLACE(AP_network_share_path + '\' + @Dataset, '\dmsarch\', '\archive\dmsarch\') AS Path
						       FROM T_Archive_Path
						       WHERE (AP_path_ID = @ArchivePathID) 
						     ) OldArchive
						     CROSS JOIN 
						     ( SELECT REPLACE(AP_network_share_path + '\' + @Dataset, '\dmsarch\', '\archive\dmsarch\') AS Path
						       FROM T_Archive_Path
						       WHERE (AP_path_ID = @ArchivePathIDNew) 
						     ) NewArchive
						--
						SELECT @myRowCount = @@rowcount, @myError = @@error

						If @infoOnly = 0
						Begin -- <e>

							UPDATE T_Dataset_Archive
							SET AS_storage_path_ID = @ArchivePathIDNew
							WHERE AS_Dataset_ID = @DatasetID
							--
							SELECT @myRowCount = @@rowcount, @myError = @@error
						
							
							INSERT INTO T_Dataset_Storage_Move_Log (DatasetID, ArchivePathOld, ArchivePathNew, MoveCmd)
							VALUES (@DatasetID, @ArchivePathID, @ArchivePathIDNew, @MoveCmd)
							--
							SELECT @myRowCount = @@rowcount, @myError = @@error
						End -- </e>
						Else
							Print @MoveCmd
											
					End -- </d2>
					
				End -- </c2>
				
			End -- </b>
			
		End -- </a>
			
		If @infoOnly = 0
		Begin
			Update T_Cached_Dataset_Folder_Paths 
			Set UpdateRequired = 1
			FROM T_Cached_Dataset_Folder_Paths Target Inner Join #TmpDatasets Src
			On Target.Dataset_ID = Src.DatasetID

			Exec UpdateCachedDatasetFolderPaths @ProcessingMode = 0

		End
			
	End Try
	Begin Catch					
		-- Error caught; log the error and set @StoragePathID to 0
		
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'GetInstrumentStoragePathForNewDatasets')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 0, 
							@ErrorNum = @myError output, @message = @message output
		
		SELECT @message AS ErrorMessage
	End catch
		
	-----------------------------------------
	-- Exit
	-----------------------------------------
	--
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[MoveDatasetsToAutoDefinedStoragePath] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveDatasetsToAutoDefinedStoragePath] TO [PNL\D3M580] AS [dbo]
GO

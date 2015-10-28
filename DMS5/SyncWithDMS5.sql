/****** Object:  StoredProcedure [dbo].[SyncWithDMS5] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure SyncWithDMS5
/****************************************************
** 
**	Desc:	Synchronize data with database DMS5
**			Intended to be run in database DMS5_t3 or DMS5_Beta
**
**	Auth:	mem
**	Date:	10/26/2015 mem - Initial version
**			10/27/2015 mem - Add tables for @usersAndCampaigns, @chargeCodesAndEUS, @experiments, @datasets, and @jobs
**    
*****************************************************/
(
	@infoOnly tinyint = 1,
	@DeleteExtras tinyint = 1,
	@ShowUpdateDetails tinyint = 1,
	@instruments tinyint = 1,
	@parameters tinyint = 1,
	@usersAndCampaigns tinyint = 1,
	@chargeCodesAndEUS tinyint = 1,
	@experiments tinyint = 0,
	@datasets tinyint = 0,
	@jobs tinyint = 0,
	@YearsToCopy int = 4,            -- Used when importing experiments, datasets, and/or jobs
	@message varchar(255) = '' output
)
As
	set nocount on
	
	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	If DB_Name() = 'DMS5'
	Begin
		Set @message = 'This stored procedure cannot be run on DMS5 because DMS5 is the source database'
		Print @message
		Goto Done
	End

	Set @YearsToCopy = IsNull(@YearsToCopy, 4)
	If @YearsToCopy < 1
		Set @YearsToCopy = 1

	Declare @ImportThreshold datetime
	Set @ImportThreshold = DateAdd(year, -@YearsToCopy, GetDate())

	
	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 1)
	Set @DeleteExtras = IsNull(@DeleteExtras, 1)
	Set @ShowUpdateDetails = IsNull(@ShowUpdateDetails, 0)
	Set @instruments = IsNull(@instruments, 1)
	Set @parameters = IsNull(@parameters, 1)
	Set @usersAndCampaigns = IsNull(@usersAndCampaigns, 1)
	Set @chargeCodesAndEUS = IsNull(@chargeCodesAndEUS, 1)
	Set @experiments = IsNull(@experiments, 0)
	Set @datasets = IsNull(@datasets, 0)
	Set @jobs = IsNull(@jobs, 0)
		
	Set @message = ''

	Create Table #Tmp_SummaryOfChanges (
		TableName varchar(128), 
		UpdateAction varchar(20), 
		InsertedKey varchar(128), 
		DeletedKey varchar(128)
	)
		
	Declare @tableName varchar(128)
	
	-----------------------------------------------------------
	-- Instruments
	-----------------------------------------------------------

	If @instruments <> 0
	Begin -- <Instruments>
	
		Set @tableName = 'T_Instrument_Class'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			
			MERGE [dbo].[T_Instrument_Class] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Instrument_Class]) as s
			ON ( t.[IN_class] = s.[IN_class])
			WHEN MATCHED AND (
				t.[is_purgable] <> s.[is_purgable] OR
				t.[raw_data_type] <> s.[raw_data_type] OR
				t.[requires_preparation] <> s.[requires_preparation] OR
				ISNULL( NULLIF(t.[x_Allowed_Dataset_Types], s.[x_Allowed_Dataset_Types]),
						NULLIF(s.[x_Allowed_Dataset_Types], t.[x_Allowed_Dataset_Types])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL OR
				ISNULL(Cast(t.[Params] AS varchar(max)), '') <>    ISNULL(Cast(s.[Params] AS varchar(max)), '')
				)
			THEN UPDATE SET 
				[is_purgable] = s.[is_purgable],
				[raw_data_type] = s.[raw_data_type],
				[requires_preparation] = s.[requires_preparation],
				[x_Allowed_Dataset_Types] = s.[x_Allowed_Dataset_Types],
				[Params] = s.[Params],
				[Comment] = s.[Comment]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([IN_class], [is_purgable], [raw_data_type], [requires_preparation], [x_Allowed_Dataset_Types], [Params], [Comment])
				VALUES(s.[IN_class], s.[is_purgable], s.[raw_data_type], s.[requires_preparation], s.[x_Allowed_Dataset_Types], s.[Params], s.[Comment])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Inserted.[IN_class], 
			       Deleted.[IN_class] 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Instrument_Class>
		
		
		Set @tableName = 'T_DatasetTypeName'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
		
			MERGE [dbo].[T_DatasetTypeName] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_DatasetTypeName]) as s
			ON ( t.[DST_Type_ID] = s.[DST_Type_ID])
			WHEN MATCHED AND (
				t.[DST_name] <> s.[DST_name] OR
				t.[DST_Active] <> s.[DST_Active] OR
				ISNULL( NULLIF(t.[DST_Description], s.[DST_Description]),
						NULLIF(s.[DST_Description], t.[DST_Description])) IS NOT NULL
				)
			THEN UPDATE SET 
				[DST_name] = s.[DST_name],
				[DST_Description] = s.[DST_Description],
				[DST_Active] = s.[DST_Active]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([DST_Type_ID], [DST_name], [DST_Description], [DST_Active])
				VALUES(s.[DST_Type_ID], s.[DST_name], s.[DST_Description], s.[DST_Active])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[DST_Type_ID] as varchar(12)), 
			       Cast(Deleted.[DST_Type_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_DatasetTypeName>
		
		
		Set @tableName = 'T_Instrument_Group'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges

			MERGE [dbo].[T_Instrument_Group] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Instrument_Group]) as s
			ON ( t.[IN_Group] = s.[IN_Group])
			WHEN MATCHED AND (
				t.[Active] <> s.[Active] OR
				ISNULL( NULLIF(t.[Usage], s.[Usage]),
						NULLIF(s.[Usage], t.[Usage])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Default_Dataset_Type], s.[Default_Dataset_Type]),
						NULLIF(s.[Default_Dataset_Type], t.[Default_Dataset_Type])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Allocation_Tag], s.[Allocation_Tag]),
						NULLIF(s.[Allocation_Tag], t.[Allocation_Tag])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Usage] = s.[Usage],
				[Comment] = s.[Comment],
				[Active] = s.[Active],
				[Default_Dataset_Type] = s.[Default_Dataset_Type],
				[Allocation_Tag] = s.[Allocation_Tag]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([IN_Group], [Usage], [Comment], [Active], [Default_Dataset_Type], [Allocation_Tag])
				VALUES(s.[IN_Group], s.[Usage], s.[Comment], s.[Active], s.[Default_Dataset_Type], s.[Allocation_Tag])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,  
			       Inserted.[IN_Group], 
			       Deleted.[IN_Group] 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Instrument_Group>
		

		Set @tableName = 'T_Instrument_Group_allowed_DS_Type'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges

			MERGE [dbo].[T_Instrument_Group_allowed_DS_Type] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Instrument_Group_allowed_DS_Type]) as s
			ON ( t.[Dataset_Type] = s.[Dataset_Type] AND t.[IN_Group] = s.[IN_Group])
			WHEN MATCHED AND (
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Comment] = s.[Comment]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([IN_Group], [Dataset_Type], [Comment])
				VALUES(s.[IN_Group], s.[Dataset_Type], s.[Comment])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Inserted.[IN_Group] + ', ' + Inserted.[Dataset_Type], 
			       Deleted.[IN_Group]  + ', ' + Deleted.[Dataset_Type] 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Instrument_Group_allowed_DS_Type>
		
		
		Set @tableName = 'T_Storage_Path'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Storage_Path] ON;
			ALTER TABLE T_Storage_Path NOCHECK CONSTRAINT FK_t_storage_path_T_Instrument_Name
			
			MERGE [dbo].[T_Storage_Path] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Storage_Path]) as s
			ON ( t.[SP_path_ID] = s.[SP_path_ID])
			WHEN MATCHED AND (
				t.[SP_path] <> s.[SP_path] OR
				t.[SP_function] <> s.[SP_function] OR
				ISNULL( NULLIF(t.[SP_machine_name], s.[SP_machine_name]),
						NULLIF(s.[SP_machine_name], t.[SP_machine_name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SP_vol_name_client], s.[SP_vol_name_client]),
						NULLIF(s.[SP_vol_name_client], t.[SP_vol_name_client])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SP_vol_name_server], s.[SP_vol_name_server]),
						NULLIF(s.[SP_vol_name_server], t.[SP_vol_name_server])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SP_instrument_name], s.[SP_instrument_name]),
						NULLIF(s.[SP_instrument_name], t.[SP_instrument_name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SP_code], s.[SP_code]),
						NULLIF(s.[SP_code], t.[SP_code])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SP_description], s.[SP_description]),
						NULLIF(s.[SP_description], t.[SP_description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SP_URL], s.[SP_URL]),
						NULLIF(s.[SP_URL], t.[SP_URL])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SP_created], s.[SP_created]),
						NULLIF(s.[SP_created], t.[SP_created])) IS NOT NULL
				)
			THEN UPDATE SET 
				[SP_path] = s.[SP_path],
				[SP_machine_name] = s.[SP_machine_name],
				[SP_vol_name_client] = s.[SP_vol_name_client],
				[SP_vol_name_server] = s.[SP_vol_name_server],
				[SP_function] = s.[SP_function],
				[SP_instrument_name] = s.[SP_instrument_name],
				[SP_code] = s.[SP_code],
				[SP_description] = s.[SP_description],
				[SP_URL] = s.[SP_URL],
				[SP_created] = s.[SP_created]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([SP_path_ID], [SP_path], [SP_machine_name], [SP_vol_name_client], [SP_vol_name_server], [SP_function], [SP_instrument_name], [SP_code], [SP_description], [SP_URL], [SP_created])
				VALUES(s.[SP_path_ID], s.[SP_path], s.[SP_machine_name], s.[SP_vol_name_client], s.[SP_vol_name_server], s.[SP_function], s.[SP_instrument_name], s.[SP_code], s.[SP_description], s.[SP_URL], s.[SP_created])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[SP_path_ID] as varchar(12)), 
			       Cast(Deleted.[SP_path_ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Storage_Path] OFF;			
				
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails

			ALTER TABLE T_Storage_Path CHECK CONSTRAINT FK_t_storage_path_T_Instrument_Name
			
			If @myRowCount > 0
				DBCC CHECKCONSTRAINTS (T_Storage_Path)

		End -- </T_Storage_Path>
		
		
		Set @tableName = 'T_Instrument_Name'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges

			MERGE [dbo].[T_Instrument_Name] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Instrument_Name]) as s
			ON ( t.[Instrument_ID] = s.[Instrument_ID])
			WHEN MATCHED AND (
				t.[IN_name] <> s.[IN_name] OR
				t.[IN_class] <> s.[IN_class] OR
				t.[IN_Group] <> s.[IN_Group] OR
				t.[IN_usage] <> s.[IN_usage] OR
				t.[IN_operations_role] <> s.[IN_operations_role] OR
				t.[IN_Tracking] <> s.[IN_Tracking] OR
				t.[Percent_EMSL_Owned] <> s.[Percent_EMSL_Owned] OR
				t.[IN_max_simultaneous_captures] <> s.[IN_max_simultaneous_captures] OR
				t.[IN_Max_Queued_Datasets] <> s.[IN_Max_Queued_Datasets] OR
				t.[IN_Capture_Exclusion_Window] <> s.[IN_Capture_Exclusion_Window] OR
				t.[IN_Capture_Log_Level] <> s.[IN_Capture_Log_Level] OR
				t.[Auto_Define_Storage_Path] <> s.[Auto_Define_Storage_Path] OR
				t.[Default_Purge_Policy] <> s.[Default_Purge_Policy] OR
				t.[Perform_Calibration] <> s.[Perform_Calibration] OR
				ISNULL( NULLIF(t.[IN_source_path_ID], s.[IN_source_path_ID]),
						NULLIF(s.[IN_source_path_ID], t.[IN_source_path_ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[IN_storage_path_ID], s.[IN_storage_path_ID]),
						NULLIF(s.[IN_storage_path_ID], t.[IN_storage_path_ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[IN_capture_method], s.[IN_capture_method]),
						NULLIF(s.[IN_capture_method], t.[IN_capture_method])) IS NOT NULL OR
				ISNULL( NULLIF(t.[IN_status], s.[IN_status]),
						NULLIF(s.[IN_status], t.[IN_status])) IS NOT NULL OR
				ISNULL( NULLIF(t.[IN_Room_Number], s.[IN_Room_Number]),
						NULLIF(s.[IN_Room_Number], t.[IN_Room_Number])) IS NOT NULL OR
				ISNULL( NULLIF(t.[IN_Description], s.[IN_Description]),
						NULLIF(s.[IN_Description], t.[IN_Description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[IN_Created], s.[IN_Created]),
						NULLIF(s.[IN_Created], t.[IN_Created])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auto_SP_Vol_Name_Client], s.[Auto_SP_Vol_Name_Client]),
						NULLIF(s.[Auto_SP_Vol_Name_Client], t.[Auto_SP_Vol_Name_Client])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auto_SP_Vol_Name_Server], s.[Auto_SP_Vol_Name_Server]),
						NULLIF(s.[Auto_SP_Vol_Name_Server], t.[Auto_SP_Vol_Name_Server])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auto_SP_Path_Root], s.[Auto_SP_Path_Root]),
						NULLIF(s.[Auto_SP_Path_Root], t.[Auto_SP_Path_Root])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auto_SP_Archive_Server_Name], s.[Auto_SP_Archive_Server_Name]),
						NULLIF(s.[Auto_SP_Archive_Server_Name], t.[Auto_SP_Archive_Server_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auto_SP_Archive_Path_Root], s.[Auto_SP_Archive_Path_Root]),
						NULLIF(s.[Auto_SP_Archive_Path_Root], t.[Auto_SP_Archive_Path_Root])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auto_SP_Archive_Share_Path_Root], s.[Auto_SP_Archive_Share_Path_Root]),
						NULLIF(s.[Auto_SP_Archive_Share_Path_Root], t.[Auto_SP_Archive_Share_Path_Root])) IS NOT NULL
				)
			THEN UPDATE SET 
				[IN_name] = s.[IN_name],
				[IN_class] = s.[IN_class],
				[IN_Group] = s.[IN_Group],
				[IN_source_path_ID] = s.[IN_source_path_ID],
				[IN_storage_path_ID] = s.[IN_storage_path_ID],
				[IN_capture_method] = s.[IN_capture_method],
				[IN_status] = s.[IN_status],
				[IN_Room_Number] = s.[IN_Room_Number],
				[IN_Description] = s.[IN_Description],
				[IN_usage] = s.[IN_usage],
				[IN_operations_role] = s.[IN_operations_role],
				[IN_Tracking] = s.[IN_Tracking],
				[Percent_EMSL_Owned] = s.[Percent_EMSL_Owned],
				[IN_max_simultaneous_captures] = s.[IN_max_simultaneous_captures],
				[IN_Max_Queued_Datasets] = s.[IN_Max_Queued_Datasets],
				[IN_Capture_Exclusion_Window] = s.[IN_Capture_Exclusion_Window],
				[IN_Capture_Log_Level] = s.[IN_Capture_Log_Level],
				[IN_Created] = s.[IN_Created],
				[Auto_Define_Storage_Path] = s.[Auto_Define_Storage_Path],
				[Auto_SP_Vol_Name_Client] = s.[Auto_SP_Vol_Name_Client],
				[Auto_SP_Vol_Name_Server] = s.[Auto_SP_Vol_Name_Server],
				[Auto_SP_Path_Root] = s.[Auto_SP_Path_Root],
				[Auto_SP_Archive_Server_Name] = s.[Auto_SP_Archive_Server_Name],
				[Auto_SP_Archive_Path_Root] = s.[Auto_SP_Archive_Path_Root],
				[Auto_SP_Archive_Share_Path_Root] = s.[Auto_SP_Archive_Share_Path_Root],
				[Default_Purge_Policy] = s.[Default_Purge_Policy],
				[Perform_Calibration] = s.[Perform_Calibration]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([IN_name], [Instrument_ID], [IN_class], [IN_Group], [IN_source_path_ID], [IN_storage_path_ID], [IN_capture_method], [IN_status], [IN_Room_Number], [IN_Description], [IN_usage], [IN_operations_role], [IN_Tracking], [Percent_EMSL_Owned], [IN_max_simultaneous_captures], [IN_Max_Queued_Datasets], [IN_Capture_Exclusion_Window], [IN_Capture_Log_Level], [IN_Created], [Auto_Define_Storage_Path], [Auto_SP_Vol_Name_Client], [Auto_SP_Vol_Name_Server], [Auto_SP_Path_Root], [Auto_SP_Archive_Server_Name], [Auto_SP_Archive_Path_Root], [Auto_SP_Archive_Share_Path_Root], [Default_Purge_Policy], [Perform_Calibration])
				VALUES(s.[IN_name], s.[Instrument_ID], s.[IN_class], s.[IN_Group], s.[IN_source_path_ID], s.[IN_storage_path_ID], s.[IN_capture_method], s.[IN_status], s.[IN_Room_Number], s.[IN_Description], s.[IN_usage], s.[IN_operations_role], s.[IN_Tracking], s.[Percent_EMSL_Owned], s.[IN_max_simultaneous_captures], s.[IN_Max_Queued_Datasets], s.[IN_Capture_Exclusion_Window], s.[IN_Capture_Log_Level], s.[IN_Created], s.[Auto_Define_Storage_Path], s.[Auto_SP_Vol_Name_Client], s.[Auto_SP_Vol_Name_Server], s.[Auto_SP_Path_Root], s.[Auto_SP_Archive_Server_Name], s.[Auto_SP_Archive_Path_Root], s.[Auto_SP_Archive_Share_Path_Root], s.[Default_Purge_Policy], s.[Perform_Calibration])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Instrument_ID] as varchar(12)), 
			       Cast(Deleted.[Instrument_ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Instrument_Name>
		
		
	End -- </Instruments>


	If @parameters <> 0
	Begin -- <Parameters>
	
		Set @tableName = 'T_Param_File_Types'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges

			MERGE [dbo].[T_Param_File_Types] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Param_File_Types]) as s
			ON ( t.[Param_File_Type_ID] = s.[Param_File_Type_ID])
			WHEN MATCHED AND (
				ISNULL( NULLIF(t.[Param_File_Type], s.[Param_File_Type]),
						NULLIF(s.[Param_File_Type], t.[Param_File_Type])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Param_File_Type] = s.[Param_File_Type]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Param_File_Type_ID], [Param_File_Type])
				VALUES(s.[Param_File_Type_ID], s.[Param_File_Type])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Param_File_Type_ID] as varchar(12)), 
			       Cast(Deleted.[Param_File_Type_ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Param_File_Types>
		
		
		Set @tableName = 'T_Analysis_Tool'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges

			MERGE [dbo].[T_Analysis_Tool] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Analysis_Tool]) as s
			ON ( t.[AJT_toolID] = s.[AJT_toolID])
			WHEN MATCHED AND (
				t.[AJT_toolName] <> s.[AJT_toolName] OR
				t.[AJT_toolBasename] <> s.[AJT_toolBasename] OR
				t.[AJT_active] <> s.[AJT_active] OR
				t.[AJT_orgDbReqd] <> s.[AJT_orgDbReqd] OR
				t.[AJT_extractionRequired] <> s.[AJT_extractionRequired] OR
				t.[Use_SpecialProcWaiting] <> s.[Use_SpecialProcWaiting] OR
				ISNULL( NULLIF(t.[AJT_paramFileType], s.[AJT_paramFileType]),
						NULLIF(s.[AJT_paramFileType], t.[AJT_paramFileType])) IS NOT NULL OR
				ISNULL( NULLIF(t.[AJT_parmFileStoragePath], s.[AJT_parmFileStoragePath]),
						NULLIF(s.[AJT_parmFileStoragePath], t.[AJT_parmFileStoragePath])) IS NOT NULL OR
				ISNULL( NULLIF(t.[AJT_parmFileStoragePathLocal], s.[AJT_parmFileStoragePathLocal]),
						NULLIF(s.[AJT_parmFileStoragePathLocal], t.[AJT_parmFileStoragePathLocal])) IS NOT NULL OR
				ISNULL( NULLIF(t.[AJT_defaultSettingsFileName], s.[AJT_defaultSettingsFileName]),
						NULLIF(s.[AJT_defaultSettingsFileName], t.[AJT_defaultSettingsFileName])) IS NOT NULL OR
				ISNULL( NULLIF(t.[AJT_resultType], s.[AJT_resultType]),
						NULLIF(s.[AJT_resultType], t.[AJT_resultType])) IS NOT NULL OR
				ISNULL( NULLIF(t.[AJT_autoScanFolderFlag], s.[AJT_autoScanFolderFlag]),
						NULLIF(s.[AJT_autoScanFolderFlag], t.[AJT_autoScanFolderFlag])) IS NOT NULL OR
				ISNULL( NULLIF(t.[AJT_searchEngineInputFileFormats], s.[AJT_searchEngineInputFileFormats]),
						NULLIF(s.[AJT_searchEngineInputFileFormats], t.[AJT_searchEngineInputFileFormats])) IS NOT NULL OR
				ISNULL( NULLIF(t.[x_Unused_AJT_toolTag], s.[x_Unused_AJT_toolTag]),
						NULLIF(s.[x_Unused_AJT_toolTag], t.[x_Unused_AJT_toolTag])) IS NOT NULL OR
				ISNULL( NULLIF(t.[AJT_description], s.[AJT_description]),
						NULLIF(s.[AJT_description], t.[AJT_description])) IS NOT NULL
				)
			THEN UPDATE SET 
				[AJT_toolName] = s.[AJT_toolName],
				[AJT_toolBasename] = s.[AJT_toolBasename],
				[AJT_paramFileType] = s.[AJT_paramFileType],
				[AJT_parmFileStoragePath] = s.[AJT_parmFileStoragePath],
				[AJT_parmFileStoragePathLocal] = s.[AJT_parmFileStoragePathLocal],
				[AJT_defaultSettingsFileName] = s.[AJT_defaultSettingsFileName],
				[AJT_resultType] = s.[AJT_resultType],
				[AJT_autoScanFolderFlag] = s.[AJT_autoScanFolderFlag],
				[AJT_active] = s.[AJT_active],
				[AJT_searchEngineInputFileFormats] = s.[AJT_searchEngineInputFileFormats],
				[AJT_orgDbReqd] = s.[AJT_orgDbReqd],
				[AJT_extractionRequired] = s.[AJT_extractionRequired],
				[x_Unused_AJT_toolTag] = s.[x_Unused_AJT_toolTag],
				[AJT_description] = s.[AJT_description],
				[Use_SpecialProcWaiting] = s.[Use_SpecialProcWaiting]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([AJT_toolID], [AJT_toolName], [AJT_toolBasename], [AJT_paramFileType], [AJT_parmFileStoragePath], [AJT_parmFileStoragePathLocal], [AJT_defaultSettingsFileName], [AJT_resultType], [AJT_autoScanFolderFlag], [AJT_active], [AJT_searchEngineInputFileFormats], [AJT_orgDbReqd], [AJT_extractionRequired], [x_Unused_AJT_toolTag], [AJT_description], [Use_SpecialProcWaiting])
				VALUES(s.[AJT_toolID], s.[AJT_toolName], s.[AJT_toolBasename], s.[AJT_paramFileType], s.[AJT_parmFileStoragePath], s.[AJT_parmFileStoragePathLocal], s.[AJT_defaultSettingsFileName], s.[AJT_resultType], s.[AJT_autoScanFolderFlag], s.[AJT_active], s.[AJT_searchEngineInputFileFormats], s.[AJT_orgDbReqd], s.[AJT_extractionRequired], s.[x_Unused_AJT_toolTag], s.[AJT_description], s.[Use_SpecialProcWaiting])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[AJT_toolID] as varchar(12)), 
			       Cast(Deleted.[AJT_toolID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Analysis_Tool>


		Set @tableName = 'T_Analysis_Tool_Allowed_Dataset_Type'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges

			MERGE [dbo].[T_Analysis_Tool_Allowed_Dataset_Type] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Analysis_Tool_Allowed_Dataset_Type]) as s
			ON ( t.[Analysis_Tool_ID] = s.[Analysis_Tool_ID] AND t.[Dataset_Type] = s.[Dataset_Type])
			WHEN MATCHED AND (
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Comment] = s.[Comment]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Analysis_Tool_ID], [Dataset_Type], [Comment])
				VALUES(s.[Analysis_Tool_ID], s.[Dataset_Type], s.[Comment])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Analysis_Tool_ID] as varchar(12)) + ', ' + Inserted.[Dataset_Type], 
			       Cast(Deleted.[Analysis_Tool_ID] as varchar(12))  + ', ' + Deleted.[Dataset_Type] 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Analysis_Tool_Allowed_Dataset_Type>


		Set @tableName = 'T_Analysis_Tool_Allowed_Instrument_Class'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges

			MERGE [dbo].[T_Analysis_Tool_Allowed_Instrument_Class] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Analysis_Tool_Allowed_Instrument_Class]) as s
			ON ( t.[Analysis_Tool_ID] = s.[Analysis_Tool_ID] AND t.[Instrument_Class] = s.[Instrument_Class])
			WHEN MATCHED AND (
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Comment] = s.[Comment]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Analysis_Tool_ID], [Instrument_Class], [Comment])
				VALUES(s.[Analysis_Tool_ID], s.[Instrument_Class], s.[Comment])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Analysis_Tool_ID] as varchar(12)) + ', ' + Inserted.[Instrument_Class], 
			       Cast(Deleted.[Analysis_Tool_ID] as varchar(12))  + ', ' + Deleted.[Instrument_Class] 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Analysis_Tool_Allowed_Instrument_Class>


		Set @tableName = 'T_Param_Files'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Param_Files] ON;
			
			MERGE [dbo].[T_Param_Files] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Param_Files]) as s
			ON ( t.[Param_File_ID] = s.[Param_File_ID])
			WHEN MATCHED AND (
				t.[Param_File_Name] <> s.[Param_File_Name] OR
				t.[Param_File_Type_ID] <> s.[Param_File_Type_ID] OR
				t.[Valid] <> s.[Valid] OR
				ISNULL( NULLIF(t.[Param_File_Description], s.[Param_File_Description]),
						NULLIF(s.[Param_File_Description], t.[Param_File_Description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Date_Created], s.[Date_Created]),
						NULLIF(s.[Date_Created], t.[Date_Created])) IS NOT NULL OR
				-- Ignore: ISNULL( NULLIF(t.[Date_Modified], s.[Date_Modified]),
				--                 NULLIF(s.[Date_Modified], t.[Date_Modified])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Job_Usage_Count], s.[Job_Usage_Count]),
						NULLIF(s.[Job_Usage_Count], t.[Job_Usage_Count])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Param_File_Name] = s.[Param_File_Name],
				[Param_File_Description] = s.[Param_File_Description],
				[Param_File_Type_ID] = s.[Param_File_Type_ID],
				[Date_Created] = s.[Date_Created],
				[Date_Modified] = s.[Date_Modified],
				[Valid] = s.[Valid],
				[Job_Usage_Count] = s.[Job_Usage_Count]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Param_File_ID], [Param_File_Name], [Param_File_Description], [Param_File_Type_ID], [Date_Created], [Date_Modified], [Valid], [Job_Usage_Count])
				VALUES(s.[Param_File_ID], s.[Param_File_Name], s.[Param_File_Description], s.[Param_File_Type_ID], s.[Date_Created], s.[Date_Modified], s.[Valid], s.[Job_Usage_Count])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Param_File_ID] as varchar(12)), 
			       Cast(Deleted.[Param_File_ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Param_Files] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Param_Files>


		Set @tableName = 'T_Param_Entries'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Param_Entries] ON;
			
			MERGE [dbo].[T_Param_Entries] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Param_Entries]) as s
			ON ( t.[Param_Entry_ID] = s.[Param_Entry_ID])
			WHEN MATCHED AND (
				t.[Param_File_ID] <> s.[Param_File_ID] OR
				ISNULL( NULLIF(t.[Entry_Sequence_Order], s.[Entry_Sequence_Order]),
						NULLIF(s.[Entry_Sequence_Order], t.[Entry_Sequence_Order])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Entry_Type], s.[Entry_Type]),
						NULLIF(s.[Entry_Type], t.[Entry_Type])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Entry_Specifier], s.[Entry_Specifier]),
						NULLIF(s.[Entry_Specifier], t.[Entry_Specifier])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Entry_Value], s.[Entry_Value]),
						NULLIF(s.[Entry_Value], t.[Entry_Value])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Entered], s.[Entered]),
						NULLIF(s.[Entered], t.[Entered])) IS NOT NULL
				-- Ignore: ISNULL( NULLIF(t.[Entered_By], s.[Entered_By]),
				--                 NULLIF(s.[Entered_By], t.[Entered_By])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Entry_Sequence_Order] = s.[Entry_Sequence_Order],
				[Entry_Type] = s.[Entry_Type],
				[Entry_Specifier] = s.[Entry_Specifier],
				[Entry_Value] = s.[Entry_Value],
				[Param_File_ID] = s.[Param_File_ID],
				[Entered] = s.[Entered],
				[Entered_By] = s.[Entered_By]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Param_Entry_ID], [Entry_Sequence_Order], [Entry_Type], [Entry_Specifier], [Entry_Value], [Param_File_ID], [Entered], [Entered_By])
				VALUES(s.[Param_Entry_ID], s.[Entry_Sequence_Order], s.[Entry_Type], s.[Entry_Specifier], s.[Entry_Value], s.[Param_File_ID], s.[Entered], s.[Entered_By])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Param_Entry_ID] as varchar(12)), 
			       Cast(Deleted.[Param_Entry_ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Param_Entries] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Param_Entries>

		
		Set @tableName = 'T_Mass_Correction_Factors'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Mass_Correction_Factors] ON;
			
			MERGE [dbo].[T_Mass_Correction_Factors] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Mass_Correction_Factors]) as s
			ON ( t.[Mass_Correction_ID] = s.[Mass_Correction_ID])
			WHEN MATCHED AND (
				t.[Mass_Correction_Tag] <> s.[Mass_Correction_Tag] OR
				t.[Monoisotopic_Mass_Correction] <> s.[Monoisotopic_Mass_Correction] OR
				t.[Affected_Atom] <> s.[Affected_Atom] OR
				ISNULL( NULLIF(t.[Description], s.[Description]),
						NULLIF(s.[Description], t.[Description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Average_Mass_Correction], s.[Average_Mass_Correction]),
						NULLIF(s.[Average_Mass_Correction], t.[Average_Mass_Correction])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Original_Source], s.[Original_Source]),
						NULLIF(s.[Original_Source], t.[Original_Source])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Original_Source_Name], s.[Original_Source_Name]),
						NULLIF(s.[Original_Source_Name], t.[Original_Source_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Alternative_Name], s.[Alternative_Name]),
						NULLIF(s.[Alternative_Name], t.[Alternative_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Empirical_Formula], s.[Empirical_Formula]),
						NULLIF(s.[Empirical_Formula], t.[Empirical_Formula])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Mass_Correction_Tag] = s.[Mass_Correction_Tag],
				[Description] = s.[Description],
				[Monoisotopic_Mass_Correction] = s.[Monoisotopic_Mass_Correction],
				[Average_Mass_Correction] = s.[Average_Mass_Correction],
				[Affected_Atom] = s.[Affected_Atom],
				[Original_Source] = s.[Original_Source],
				[Original_Source_Name] = s.[Original_Source_Name],
				[Alternative_Name] = s.[Alternative_Name],
				[Empirical_Formula] = s.[Empirical_Formula]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Mass_Correction_ID], [Mass_Correction_Tag], [Description], [Monoisotopic_Mass_Correction], [Average_Mass_Correction], [Affected_Atom], [Original_Source], [Original_Source_Name], [Alternative_Name], [Empirical_Formula])
				VALUES(s.[Mass_Correction_ID], s.[Mass_Correction_Tag], s.[Description], s.[Monoisotopic_Mass_Correction], s.[Average_Mass_Correction], s.[Affected_Atom], s.[Original_Source], s.[Original_Source_Name], s.[Alternative_Name], s.[Empirical_Formula])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Mass_Correction_ID] as varchar(12)), 
			       Cast(Deleted.[Mass_Correction_ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Mass_Correction_Factors] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Mass_Correction_Factors>


		Set @tableName = 'T_Param_File_Mass_Mods'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Param_File_Mass_Mods] ON;
			
			MERGE [dbo].[T_Param_File_Mass_Mods] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Param_File_Mass_Mods]) as s
			ON ( t.[Mod_Entry_ID] = s.[Mod_Entry_ID])
			WHEN MATCHED AND (
				t.[Local_Symbol_ID] <> s.[Local_Symbol_ID] OR
				t.[Mass_Correction_ID] <> s.[Mass_Correction_ID] OR
				ISNULL( NULLIF(t.[Residue_ID], s.[Residue_ID]),
						NULLIF(s.[Residue_ID], t.[Residue_ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Param_File_ID], s.[Param_File_ID]),
						NULLIF(s.[Param_File_ID], t.[Param_File_ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Mod_Type_Symbol], s.[Mod_Type_Symbol]),
						NULLIF(s.[Mod_Type_Symbol], t.[Mod_Type_Symbol])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Residue_ID] = s.[Residue_ID],
				[Local_Symbol_ID] = s.[Local_Symbol_ID],
				[Mass_Correction_ID] = s.[Mass_Correction_ID],
				[Param_File_ID] = s.[Param_File_ID],
				[Mod_Type_Symbol] = s.[Mod_Type_Symbol]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Mod_Entry_ID], [Residue_ID], [Local_Symbol_ID], [Mass_Correction_ID], [Param_File_ID], [Mod_Type_Symbol])
				VALUES(s.[Mod_Entry_ID], s.[Residue_ID], s.[Local_Symbol_ID], s.[Mass_Correction_ID], s.[Param_File_ID], s.[Mod_Type_Symbol])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[Mod_Entry_ID] as varchar(12)), 
			       Cast(Deleted.[Mod_Entry_ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Param_File_Mass_Mods] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Param_File_Mass_Mods>


		Set @tableName = 'T_Settings_Files'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Settings_Files] ON;
			
			MERGE [dbo].[T_Settings_Files] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Settings_Files]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
				t.[Analysis_Tool] <> s.[Analysis_Tool] OR
				t.[File_Name] <> s.[File_Name] OR
				ISNULL( NULLIF(t.[Description], s.[Description]),
						NULLIF(s.[Description], t.[Description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Active], s.[Active]),
						NULLIF(s.[Active], t.[Active])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Last_Updated], s.[Last_Updated]),
						NULLIF(s.[Last_Updated], t.[Last_Updated])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Job_Usage_Count], s.[Job_Usage_Count]),
						NULLIF(s.[Job_Usage_Count], t.[Job_Usage_Count])) IS NOT NULL OR
				ISNULL( NULLIF(t.[HMS_AutoSupersede], s.[HMS_AutoSupersede]),
						NULLIF(s.[HMS_AutoSupersede], t.[HMS_AutoSupersede])) IS NOT NULL OR
				ISNULL( NULLIF(t.[MSGFPlus_AutoCentroid], s.[MSGFPlus_AutoCentroid]),
						NULLIF(s.[MSGFPlus_AutoCentroid], t.[MSGFPlus_AutoCentroid])) IS NOT NULL OR
				ISNULL(Cast(t.[Contents] AS varchar(max)), '') <>    ISNULL(Cast(s.[Contents] AS varchar(max)), '')
				)
			THEN UPDATE SET 
				[Analysis_Tool] = s.[Analysis_Tool],
				[File_Name] = s.[File_Name],
				[Description] = s.[Description],
				[Active] = s.[Active],
				[Last_Updated] = s.[Last_Updated],
				[Contents] = s.[Contents],
				[Job_Usage_Count] = s.[Job_Usage_Count],
				[HMS_AutoSupersede] = s.[HMS_AutoSupersede],
				[MSGFPlus_AutoCentroid] = s.[MSGFPlus_AutoCentroid]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([ID], [Analysis_Tool], [File_Name], [Description], [Active], [Last_Updated], [Contents], [Job_Usage_Count], [HMS_AutoSupersede], [MSGFPlus_AutoCentroid])
				VALUES(s.[ID], s.[Analysis_Tool], s.[File_Name], s.[Description], s.[Active], s.[Last_Updated], s.[Contents], s.[Job_Usage_Count], s.[HMS_AutoSupersede], s.[MSGFPlus_AutoCentroid])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action, 
			       Cast(Inserted.[ID] as varchar(12)), 
			       Cast(Deleted.[ID] as varchar(12)) 
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Settings_Files] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
			
		End -- </T_Settings_Files>
		

	End -- </Parameters>

	If @usersAndCampaigns <> 0
	Begin -- <UsersAndCampaigns>
	
		Set @tableName = 'T_Users'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Users] ON;
			 
			MERGE [dbo].[T_Users] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Users]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
				t.[U_PRN] <> s.[U_PRN] OR
				t.[U_Name] <> s.[U_Name] OR
				t.[U_HID] <> s.[U_HID] OR
				t.[U_Status] <> s.[U_Status] OR
				t.[U_active] <> s.[U_active] OR
				t.[U_update] <> s.[U_update] OR
				ISNULL( NULLIF(t.[U_email], s.[U_email]),
						NULLIF(s.[U_email], t.[U_email])) IS NOT NULL OR
				ISNULL( NULLIF(t.[U_domain], s.[U_domain]),
						NULLIF(s.[U_domain], t.[U_domain])) IS NOT NULL OR
				ISNULL( NULLIF(t.[U_Payroll], s.[U_Payroll]),
						NULLIF(s.[U_Payroll], t.[U_Payroll])) IS NOT NULL OR
				ISNULL( NULLIF(t.[U_created], s.[U_created]),
						NULLIF(s.[U_created], t.[U_created])) IS NOT NULL OR
				ISNULL( NULLIF(t.[U_comment], s.[U_comment]),
						NULLIF(s.[U_comment], t.[U_comment])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
						NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL
				)
			THEN UPDATE SET 
				[U_PRN] = s.[U_PRN],
				[U_Name] = s.[U_Name],
				[U_HID] = s.[U_HID],
				[U_Status] = s.[U_Status],
				[U_email] = s.[U_email],
				[U_domain] = s.[U_domain],
				[U_Payroll] = s.[U_Payroll],
				[U_active] = s.[U_active],
				[U_update] = s.[U_update],
				[U_created] = s.[U_created],
				[U_comment] = s.[U_comment],
				[Last_Affected] = s.[Last_Affected]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([U_PRN], [U_Name], [U_HID], [ID], [U_Status], [U_email], [U_domain], [U_Payroll], [U_active], [U_update], [U_created], [U_comment], [Last_Affected])
				VALUES(s.[U_PRN], s.[U_Name], s.[U_HID], s.[ID], s.[U_Status], s.[U_email], s.[U_domain], s.[U_Payroll], s.[U_active], s.[U_update], s.[U_created], s.[U_comment], s.[Last_Affected])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[ID] as varchar(12)),
				Cast(Deleted.[ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Users] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
				
		End

		Set @tableName = 'T_Research_Team'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Research_Team] ON;
			 
			MERGE [dbo].[T_Research_Team] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Research_Team]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
				t.[Team] <> s.[Team] OR
				ISNULL( NULLIF(t.[Description], s.[Description]),
						NULLIF(s.[Description], t.[Description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Collaborators], s.[Collaborators]),
						NULLIF(s.[Collaborators], t.[Collaborators])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Team] = s.[Team],
				[Description] = s.[Description],
				[Collaborators] = s.[Collaborators]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([ID], [Team], [Description], [Collaborators])
				VALUES(s.[ID], s.[Team], s.[Description], s.[Collaborators])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[ID] as varchar(12)),
				Cast(Deleted.[ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Research_Team] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Research_Team_Membership'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			
			MERGE [dbo].[T_Research_Team_Membership] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Research_Team_Membership]) as s
			ON ( t.[Role_ID] = s.[Role_ID] AND t.[Team_ID] = s.[Team_ID] AND t.[User_ID] = s.[User_ID])
			-- Note: all of the columns in table T_Research_Team_Membership are primary keys or identity columns; there are no updatable columns
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Team_ID], [Role_ID], [User_ID])
				VALUES(s.[Team_ID], s.[Role_ID], s.[User_ID])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				'Role_' + Cast(Inserted.[Role_ID] as varchar(12)) + ', Team_' + Cast(Inserted.[Team_ID] as varchar(12)) + ', User_' + Cast(Inserted.[User_ID] as varchar(12)),
				'Role_' + Cast(Deleted.[Role_ID] as varchar(12)) + ', Team_' + Cast(Deleted.[Team_ID] as varchar(12)) + ', User_' + Cast(Deleted.[User_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Campaign'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Campaign] ON;
			 
			MERGE [dbo].[T_Campaign] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Campaign]) as s
			ON ( t.[Campaign_ID] = s.[Campaign_ID])
			WHEN MATCHED AND (
				t.[Campaign_Num] <> s.[Campaign_Num] OR
				t.[CM_Project_Num] <> s.[CM_Project_Num] OR
				t.[CM_created] <> s.[CM_created] OR
				t.[CM_State] <> s.[CM_State] OR
				t.[CM_Data_Release_Restrictions] <> s.[CM_Data_Release_Restrictions] OR
				ISNULL( NULLIF(t.[CM_Proj_Mgr_PRN], s.[CM_Proj_Mgr_PRN]),
						NULLIF(s.[CM_Proj_Mgr_PRN], t.[CM_Proj_Mgr_PRN])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_PI_PRN], s.[CM_PI_PRN]),
						NULLIF(s.[CM_PI_PRN], t.[CM_PI_PRN])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_comment], s.[CM_comment]),
						NULLIF(s.[CM_comment], t.[CM_comment])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_Technical_Lead], s.[CM_Technical_Lead]),
						NULLIF(s.[CM_Technical_Lead], t.[CM_Technical_Lead])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_Description], s.[CM_Description]),
						NULLIF(s.[CM_Description], t.[CM_Description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_External_Links], s.[CM_External_Links]),
						NULLIF(s.[CM_External_Links], t.[CM_External_Links])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_Team_Members], s.[CM_Team_Members]),
						NULLIF(s.[CM_Team_Members], t.[CM_Team_Members])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_EPR_List], s.[CM_EPR_List]),
						NULLIF(s.[CM_EPR_List], t.[CM_EPR_List])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_EUS_Proposal_List], s.[CM_EUS_Proposal_List]),
						NULLIF(s.[CM_EUS_Proposal_List], t.[CM_EUS_Proposal_List])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_Organisms], s.[CM_Organisms]),
						NULLIF(s.[CM_Organisms], t.[CM_Organisms])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_Experiment_Prefixes], s.[CM_Experiment_Prefixes]),
						NULLIF(s.[CM_Experiment_Prefixes], t.[CM_Experiment_Prefixes])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_Research_Team], s.[CM_Research_Team]),
						NULLIF(s.[CM_Research_Team], t.[CM_Research_Team])) IS NOT NULL OR
				ISNULL( NULLIF(t.[CM_Fraction_EMSL_Funded], s.[CM_Fraction_EMSL_Funded]),
						NULLIF(s.[CM_Fraction_EMSL_Funded], t.[CM_Fraction_EMSL_Funded])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Campaign_Num] = s.[Campaign_Num],
				[CM_Project_Num] = s.[CM_Project_Num],
				[CM_Proj_Mgr_PRN] = s.[CM_Proj_Mgr_PRN],
				[CM_PI_PRN] = s.[CM_PI_PRN],
				[CM_comment] = s.[CM_comment],
				[CM_created] = s.[CM_created],
				[CM_Technical_Lead] = s.[CM_Technical_Lead],
				[CM_State] = s.[CM_State],
				[CM_Description] = s.[CM_Description],
				[CM_External_Links] = s.[CM_External_Links],
				[CM_Team_Members] = s.[CM_Team_Members],
				[CM_EPR_List] = s.[CM_EPR_List],
				[CM_EUS_Proposal_List] = s.[CM_EUS_Proposal_List],
				[CM_Organisms] = s.[CM_Organisms],
				[CM_Experiment_Prefixes] = s.[CM_Experiment_Prefixes],
				[CM_Research_Team] = s.[CM_Research_Team],
				[CM_Data_Release_Restrictions] = s.[CM_Data_Release_Restrictions],
				[CM_Fraction_EMSL_Funded] = s.[CM_Fraction_EMSL_Funded]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Campaign_Num], [CM_Project_Num], [CM_Proj_Mgr_PRN], [CM_PI_PRN], [CM_comment], [CM_created], [Campaign_ID], [CM_Technical_Lead], [CM_State], [CM_Description], [CM_External_Links], [CM_Team_Members], [CM_EPR_List], [CM_EUS_Proposal_List], [CM_Organisms], [CM_Experiment_Prefixes], [CM_Research_Team], [CM_Data_Release_Restrictions], [CM_Fraction_EMSL_Funded])
				VALUES(s.[Campaign_Num], s.[CM_Project_Num], s.[CM_Proj_Mgr_PRN], s.[CM_PI_PRN], s.[CM_comment], s.[CM_created], s.[Campaign_ID], s.[CM_Technical_Lead], s.[CM_State], s.[CM_Description], s.[CM_External_Links], s.[CM_Team_Members], s.[CM_EPR_List], s.[CM_EUS_Proposal_List], s.[CM_Organisms], s.[CM_Experiment_Prefixes], s.[CM_Research_Team], s.[CM_Data_Release_Restrictions], s.[CM_Fraction_EMSL_Funded])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[Campaign_ID] as varchar(12)),
				Cast(Deleted.[Campaign_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Campaign] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Campaign_Tracking'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Campaign_Tracking] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Campaign_Tracking]) as s
			ON ( t.[C_ID] = s.[C_ID])
			WHEN MATCHED AND (
				t.[Cell_Culture_Count] <> s.[Cell_Culture_Count] OR
				t.[Experiment_Count] <> s.[Experiment_Count] OR
				t.[Dataset_Count] <> s.[Dataset_Count] OR
				t.[Job_Count] <> s.[Job_Count] OR
				t.[Run_Request_Count] <> s.[Run_Request_Count] OR
				t.[Sample_Prep_Request_Count] <> s.[Sample_Prep_Request_Count] OR
				ISNULL( NULLIF(t.[Data_Package_Count], s.[Data_Package_Count]),
						NULLIF(s.[Data_Package_Count], t.[Data_Package_Count])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Cell_Culture_Most_Recent], s.[Cell_Culture_Most_Recent]),
						NULLIF(s.[Cell_Culture_Most_Recent], t.[Cell_Culture_Most_Recent])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Experiment_Most_Recent], s.[Experiment_Most_Recent]),
						NULLIF(s.[Experiment_Most_Recent], t.[Experiment_Most_Recent])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Dataset_Most_Recent], s.[Dataset_Most_Recent]),
						NULLIF(s.[Dataset_Most_Recent], t.[Dataset_Most_Recent])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Job_Most_Recent], s.[Job_Most_Recent]),
						NULLIF(s.[Job_Most_Recent], t.[Job_Most_Recent])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Run_Request_Most_Recent], s.[Run_Request_Most_Recent]),
						NULLIF(s.[Run_Request_Most_Recent], t.[Run_Request_Most_Recent])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Sample_Prep_Request_Most_Recent], s.[Sample_Prep_Request_Most_Recent]),
						NULLIF(s.[Sample_Prep_Request_Most_Recent], t.[Sample_Prep_Request_Most_Recent])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Most_Recent_Activity], s.[Most_Recent_Activity]),
						NULLIF(s.[Most_Recent_Activity], t.[Most_Recent_Activity])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Cell_Culture_Count] = s.[Cell_Culture_Count],
				[Experiment_Count] = s.[Experiment_Count],
				[Dataset_Count] = s.[Dataset_Count],
				[Job_Count] = s.[Job_Count],
				[Run_Request_Count] = s.[Run_Request_Count],
				[Sample_Prep_Request_Count] = s.[Sample_Prep_Request_Count],
				[Data_Package_Count] = s.[Data_Package_Count],
				[Cell_Culture_Most_Recent] = s.[Cell_Culture_Most_Recent],
				[Experiment_Most_Recent] = s.[Experiment_Most_Recent],
				[Dataset_Most_Recent] = s.[Dataset_Most_Recent],
				[Job_Most_Recent] = s.[Job_Most_Recent],
				[Run_Request_Most_Recent] = s.[Run_Request_Most_Recent],
				[Sample_Prep_Request_Most_Recent] = s.[Sample_Prep_Request_Most_Recent],
				[Most_Recent_Activity] = s.[Most_Recent_Activity]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([C_ID], [Cell_Culture_Count], [Experiment_Count], [Dataset_Count], [Job_Count], [Run_Request_Count], [Sample_Prep_Request_Count], [Data_Package_Count], [Cell_Culture_Most_Recent], [Experiment_Most_Recent], [Dataset_Most_Recent], [Job_Most_Recent], [Run_Request_Most_Recent], [Sample_Prep_Request_Most_Recent], [Most_Recent_Activity])
				VALUES(s.[C_ID], s.[Cell_Culture_Count], s.[Experiment_Count], s.[Dataset_Count], s.[Job_Count], s.[Run_Request_Count], s.[Sample_Prep_Request_Count], s.[Data_Package_Count], s.[Cell_Culture_Most_Recent], s.[Experiment_Most_Recent], s.[Dataset_Most_Recent], s.[Job_Most_Recent], s.[Run_Request_Most_Recent], s.[Sample_Prep_Request_Most_Recent], s.[Most_Recent_Activity])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[C_ID] as varchar(12)),
				Cast(Deleted.[C_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End
		
	End -- </UsersAndCampaigns>

	If @chargeCodesAndEUS <> 0
	Begin -- <ChargeCodesAndEUS>

		Set @tableName = 'T_Charge_Code'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Charge_Code] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Charge_Code]) as s
			ON ( t.[Charge_Code] = s.[Charge_Code])
			WHEN MATCHED AND (
				t.[Setup_Date] <> s.[Setup_Date] OR
				t.[Deactivated] <> s.[Deactivated] OR
				t.[Auth_Amt] <> s.[Auth_Amt] OR
				t.[Auto_Defined] <> s.[Auto_Defined] OR
				t.[Charge_Code_State] <> s.[Charge_Code_State] OR
				t.[Last_Affected] <> s.[Last_Affected] OR
				t.[Activation_State] <> s.[Activation_State] OR
				ISNULL( NULLIF(t.[Resp_PRN], s.[Resp_PRN]),
						NULLIF(s.[Resp_PRN], t.[Resp_PRN])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Resp_HID], s.[Resp_HID]),
						NULLIF(s.[Resp_HID], t.[Resp_HID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[WBS_Title], s.[WBS_Title]),
						NULLIF(s.[WBS_Title], t.[WBS_Title])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Charge_Code_Title], s.[Charge_Code_Title]),
						NULLIF(s.[Charge_Code_Title], t.[Charge_Code_Title])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SubAccount], s.[SubAccount]),
						NULLIF(s.[SubAccount], t.[SubAccount])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SubAccount_Title], s.[SubAccount_Title]),
						NULLIF(s.[SubAccount_Title], t.[SubAccount_Title])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SubAccount_Effective_Date], s.[SubAccount_Effective_Date]),
						NULLIF(s.[SubAccount_Effective_Date], t.[SubAccount_Effective_Date])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Inactive_Date], s.[Inactive_Date]),
						NULLIF(s.[Inactive_Date], t.[Inactive_Date])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SubAccount_Inactive_Date], s.[SubAccount_Inactive_Date]),
						NULLIF(s.[SubAccount_Inactive_Date], t.[SubAccount_Inactive_Date])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Inactive_Date_Most_Recent], s.[Inactive_Date_Most_Recent]),
						NULLIF(s.[Inactive_Date_Most_Recent], t.[Inactive_Date_Most_Recent])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auth_PRN], s.[Auth_PRN]),
						NULLIF(s.[Auth_PRN], t.[Auth_PRN])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Auth_HID], s.[Auth_HID]),
						NULLIF(s.[Auth_HID], t.[Auth_HID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Usage_SamplePrep], s.[Usage_SamplePrep]),
						NULLIF(s.[Usage_SamplePrep], t.[Usage_SamplePrep])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Usage_RequestedRun], s.[Usage_RequestedRun]),
						NULLIF(s.[Usage_RequestedRun], t.[Usage_RequestedRun])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Resp_PRN] = s.[Resp_PRN],
				[Resp_HID] = s.[Resp_HID],
				[WBS_Title] = s.[WBS_Title],
				[Charge_Code_Title] = s.[Charge_Code_Title],
				[SubAccount] = s.[SubAccount],
				[SubAccount_Title] = s.[SubAccount_Title],
				[Setup_Date] = s.[Setup_Date],
				[SubAccount_Effective_Date] = s.[SubAccount_Effective_Date],
				[Inactive_Date] = s.[Inactive_Date],
				[SubAccount_Inactive_Date] = s.[SubAccount_Inactive_Date],
				[Inactive_Date_Most_Recent] = s.[Inactive_Date_Most_Recent],
				[Deactivated] = s.[Deactivated],
				[Auth_Amt] = s.[Auth_Amt],
				[Auth_PRN] = s.[Auth_PRN],
				[Auth_HID] = s.[Auth_HID],
				[Auto_Defined] = s.[Auto_Defined],
				[Charge_Code_State] = s.[Charge_Code_State],
				[Last_Affected] = s.[Last_Affected],
				[Usage_SamplePrep] = s.[Usage_SamplePrep],
				[Usage_RequestedRun] = s.[Usage_RequestedRun],
				[Activation_State] = s.[Activation_State]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Charge_Code], [Resp_PRN], [Resp_HID], [WBS_Title], [Charge_Code_Title], [SubAccount], [SubAccount_Title], [Setup_Date], [SubAccount_Effective_Date], [Inactive_Date], [SubAccount_Inactive_Date], [Inactive_Date_Most_Recent], [Deactivated], [Auth_Amt], [Auth_PRN], [Auth_HID], [Auto_Defined], [Charge_Code_State], [Last_Affected], [Usage_SamplePrep], [Usage_RequestedRun], [Activation_State])
				VALUES(s.[Charge_Code], s.[Resp_PRN], s.[Resp_HID], s.[WBS_Title], s.[Charge_Code_Title], s.[SubAccount], s.[SubAccount_Title], s.[Setup_Date], s.[SubAccount_Effective_Date], s.[Inactive_Date], s.[SubAccount_Inactive_Date], s.[Inactive_Date_Most_Recent], s.[Deactivated], s.[Auth_Amt], s.[Auth_PRN], s.[Auth_HID], s.[Auto_Defined], s.[Charge_Code_State], s.[Last_Affected], s.[Usage_SamplePrep], s.[Usage_RequestedRun], s.[Activation_State])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Inserted.[Charge_Code],
				Deleted.[Charge_Code]
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_EUS_Users'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_EUS_Users] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_EUS_Users]) as s
			ON ( t.[PERSON_ID] = s.[PERSON_ID])
			WHEN MATCHED AND (
				t.[Site_Status] <> s.[Site_Status] OR
				ISNULL( NULLIF(t.[NAME_FM], s.[NAME_FM]),
						NULLIF(s.[NAME_FM], t.[NAME_FM])) IS NOT NULL OR
				ISNULL( NULLIF(t.[HID], s.[HID]),
						NULLIF(s.[HID], t.[HID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
						NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL
				)
			THEN UPDATE SET 
				[NAME_FM] = s.[NAME_FM],
				[HID] = s.[HID],
				[Site_Status] = s.[Site_Status],
				[Last_Affected] = s.[Last_Affected]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([PERSON_ID], [NAME_FM], [HID], [Site_Status], [Last_Affected])
				VALUES(s.[PERSON_ID], s.[NAME_FM], s.[HID], s.[Site_Status], s.[Last_Affected])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[PERSON_ID] as varchar(12)),
				Cast(Deleted.[PERSON_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_EUS_Proposal'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_EUS_Proposals] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_EUS_Proposals]) as s
			ON ( t.[Proposal_ID] = s.[Proposal_ID])
			WHEN MATCHED AND (
				t.[State_ID] <> s.[State_ID] OR
				t.[Import_Date] <> s.[Import_Date] OR
				ISNULL( NULLIF(t.[Title], s.[Title]),
						NULLIF(s.[Title], t.[Title])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Proposal_Type], s.[Proposal_Type]),
						NULLIF(s.[Proposal_Type], t.[Proposal_Type])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Proposal_Start_Date], s.[Proposal_Start_Date]),
						NULLIF(s.[Proposal_Start_Date], t.[Proposal_Start_Date])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Proposal_End_Date], s.[Proposal_End_Date]),
						NULLIF(s.[Proposal_End_Date], t.[Proposal_End_Date])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
						NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Title] = s.[Title],
				[State_ID] = s.[State_ID],
				[Import_Date] = s.[Import_Date],
				[Proposal_Type] = s.[Proposal_Type],
				[Proposal_Start_Date] = s.[Proposal_Start_Date],
				[Proposal_End_Date] = s.[Proposal_End_Date],
				[Last_Affected] = s.[Last_Affected]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Proposal_ID], [Title], [State_ID], [Import_Date], [Proposal_Type], [Proposal_Start_Date], [Proposal_End_Date], [Last_Affected])
				VALUES(s.[Proposal_ID], s.[Title], s.[State_ID], s.[Import_Date], s.[Proposal_Type], s.[Proposal_Start_Date], s.[Proposal_End_Date], s.[Last_Affected])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Inserted.[Proposal_ID],
				Deleted.[Proposal_ID]
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_EUS_Proposal_Users'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_EUS_Proposal_Users] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_EUS_Proposal_Users]) as s
			ON ( t.[Person_ID] = s.[Person_ID] AND t.[Proposal_ID] = s.[Proposal_ID])
			WHEN MATCHED AND (
				t.[Of_DMS_Interest] <> s.[Of_DMS_Interest] OR
				t.[State_ID] <> s.[State_ID] OR
				ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
						NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Of_DMS_Interest] = s.[Of_DMS_Interest],
				[State_ID] = s.[State_ID],
				[Last_Affected] = s.[Last_Affected]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Proposal_ID], [Person_ID], [Of_DMS_Interest], [State_ID], [Last_Affected])
				VALUES(s.[Proposal_ID], s.[Person_ID], s.[Of_DMS_Interest], s.[State_ID], s.[Last_Affected])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[Person_ID] as varchar(12)) + ', ' + Inserted.[Proposal_ID],
				Cast(Deleted.[Person_ID] as varchar(12)) + ', ' + Deleted.[Proposal_ID]
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_EMSL_Instruments'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_EMSL_Instruments] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_EMSL_Instruments]) as s
			ON ( t.[EUS_Instrument_ID] = s.[EUS_Instrument_ID])
			WHEN MATCHED AND (
				ISNULL( NULLIF(t.[EUS_Display_Name], s.[EUS_Display_Name]),
						NULLIF(s.[EUS_Display_Name], t.[EUS_Display_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[EUS_Instrument_Name], s.[EUS_Instrument_Name]),
						NULLIF(s.[EUS_Instrument_Name], t.[EUS_Instrument_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[EUS_Available_Hours], s.[EUS_Available_Hours]),
						NULLIF(s.[EUS_Available_Hours], t.[EUS_Available_Hours])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Local_Category_Name], s.[Local_Category_Name]),
						NULLIF(s.[Local_Category_Name], t.[Local_Category_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Local_Instrument_Name], s.[Local_Instrument_Name]),
						NULLIF(s.[Local_Instrument_Name], t.[Local_Instrument_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
						NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL OR
				ISNULL( NULLIF(t.[EUS_Active_Sw], s.[EUS_Active_Sw]),
						NULLIF(s.[EUS_Active_Sw], t.[EUS_Active_Sw])) IS NOT NULL OR
				ISNULL( NULLIF(t.[EUS_Primary_Instrument], s.[EUS_Primary_Instrument]),
						NULLIF(s.[EUS_Primary_Instrument], t.[EUS_Primary_Instrument])) IS NOT NULL
				)
			THEN UPDATE SET 
				[EUS_Display_Name] = s.[EUS_Display_Name],
				[EUS_Instrument_Name] = s.[EUS_Instrument_Name],
				[EUS_Available_Hours] = s.[EUS_Available_Hours],
				[Local_Category_Name] = s.[Local_Category_Name],
				[Local_Instrument_Name] = s.[Local_Instrument_Name],
				[Last_Affected] = s.[Last_Affected],
				[EUS_Active_Sw] = s.[EUS_Active_Sw],
				[EUS_Primary_Instrument] = s.[EUS_Primary_Instrument]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([EUS_Display_Name], [EUS_Instrument_Name], [EUS_Instrument_ID], [EUS_Available_Hours], [Local_Category_Name], [Local_Instrument_Name], [Last_Affected], [EUS_Active_Sw], [EUS_Primary_Instrument])
				VALUES(s.[EUS_Display_Name], s.[EUS_Instrument_Name], s.[EUS_Instrument_ID], s.[EUS_Available_Hours], s.[Local_Category_Name], s.[Local_Instrument_Name], s.[Last_Affected], s.[EUS_Active_Sw], s.[EUS_Primary_Instrument])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[EUS_Instrument_ID] as varchar(12)),
				Cast(Deleted.[EUS_Instrument_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_EMSL_Instrument_Allocation'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_EMSL_Instrument_Allocation] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_EMSL_Instrument_Allocation]) as s
			ON ( t.[EUS_Instrument_ID] = s.[EUS_Instrument_ID] AND t.[FY] = s.[FY] AND t.[Proposal_ID] = s.[Proposal_ID])
			WHEN MATCHED AND (
				ISNULL( NULLIF(t.[Allocated_Hours], s.[Allocated_Hours]),
						NULLIF(s.[Allocated_Hours], t.[Allocated_Hours])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Ext_Display_Name], s.[Ext_Display_Name]),
						NULLIF(s.[Ext_Display_Name], t.[Ext_Display_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Ext_Requested_Hours], s.[Ext_Requested_Hours]),
						NULLIF(s.[Ext_Requested_Hours], t.[Ext_Requested_Hours])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
						NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Allocated_Hours] = s.[Allocated_Hours],
				[Ext_Display_Name] = s.[Ext_Display_Name],
				[Ext_Requested_Hours] = s.[Ext_Requested_Hours],
				[Last_Affected] = s.[Last_Affected]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([EUS_Instrument_ID], [Proposal_ID], [FY], [Allocated_Hours], [Ext_Display_Name], [Ext_Requested_Hours], [Last_Affected])
				VALUES(s.[EUS_Instrument_ID], s.[Proposal_ID], s.[FY], s.[Allocated_Hours], s.[Ext_Display_Name], s.[Ext_Requested_Hours], s.[Last_Affected])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[EUS_Instrument_ID] as varchar(12)) + ', ' + Inserted.[FY] + ', ' + Inserted.[Proposal_ID],
				Cast(Deleted.[EUS_Instrument_ID] as varchar(12)) + ', ' + Deleted.[FY] + ', ' + Deleted.[Proposal_ID]
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_EMSL_Instrument_Usage_Report'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_EMSL_Instrument_Usage_Report] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_EMSL_Instrument_Usage_Report]) as s
			ON ( t.[Seq] = s.[Seq])
			WHEN MATCHED AND (
				t.[Updated] <> s.[Updated] OR
				ISNULL( NULLIF(t.[EMSL_Inst_ID], s.[EMSL_Inst_ID]),
						NULLIF(s.[EMSL_Inst_ID], t.[EMSL_Inst_ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Instrument], s.[Instrument]),
						NULLIF(s.[Instrument], t.[Instrument])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Type], s.[Type]),
						NULLIF(s.[Type], t.[Type])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Start], s.[Start]),
						NULLIF(s.[Start], t.[Start])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Minutes], s.[Minutes]),
						NULLIF(s.[Minutes], t.[Minutes])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Proposal], s.[Proposal]),
						NULLIF(s.[Proposal], t.[Proposal])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Usage], s.[Usage]),
						NULLIF(s.[Usage], t.[Usage])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Users], s.[Users]),
						NULLIF(s.[Users], t.[Users])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Operator], s.[Operator]),
						NULLIF(s.[Operator], t.[Operator])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Year], s.[Year]),
						NULLIF(s.[Year], t.[Year])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Month], s.[Month]),
						NULLIF(s.[Month], t.[Month])) IS NOT NULL OR
				ISNULL( NULLIF(t.[ID], s.[ID]),
						NULLIF(s.[ID], t.[ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[UpdatedBy], s.[UpdatedBy]),
						NULLIF(s.[UpdatedBy], t.[UpdatedBy])) IS NOT NULL
				)
			THEN UPDATE SET 
				[EMSL_Inst_ID] = s.[EMSL_Inst_ID],
				[Instrument] = s.[Instrument],
				[Type] = s.[Type],
				[Start] = s.[Start],
				[Minutes] = s.[Minutes],
				[Proposal] = s.[Proposal],
				[Usage] = s.[Usage],
				[Users] = s.[Users],
				[Operator] = s.[Operator],
				[Comment] = s.[Comment],
				[Year] = s.[Year],
				[Month] = s.[Month],
				[ID] = s.[ID],
				[Updated] = s.[Updated],
				[UpdatedBy] = s.[UpdatedBy]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([EMSL_Inst_ID], [Instrument], [Type], [Start], [Minutes], [Proposal], [Usage], [Users], [Operator], [Comment], [Year], [Month], [ID], [Seq], [Updated], [UpdatedBy])
				VALUES(s.[EMSL_Inst_ID], s.[Instrument], s.[Type], s.[Start], s.[Minutes], s.[Proposal], s.[Usage], s.[Users], s.[Operator], s.[Comment], s.[Year], s.[Month], s.[ID], s.[Seq], s.[Updated], s.[UpdatedBy])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[Seq] as varchar(12)),
				Cast(Deleted.[Seq] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_EMSL_DMS_Instrument_Mapping'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_EMSL_DMS_Instrument_Mapping] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_EMSL_DMS_Instrument_Mapping]) as s
			ON ( t.[DMS_Instrument_ID] = s.[DMS_Instrument_ID] AND t.[EUS_Instrument_ID] = s.[EUS_Instrument_ID])
			-- Note: all of the columns in table T_EMSL_DMS_Instrument_Mapping are primary keys or identity columns; there are no updatable columns
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([EUS_Instrument_ID], [DMS_Instrument_ID])
				VALUES(s.[EUS_Instrument_ID], s.[DMS_Instrument_ID])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[DMS_Instrument_ID] as varchar(12)) + ', ' + Cast(Inserted.[EUS_Instrument_ID] as varchar(12)),
				Cast(Deleted.[DMS_Instrument_ID] as varchar(12)) + ', ' + Cast(Deleted.[EUS_Instrument_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Instrument_Group_Allocation_Tag'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Instrument_Group_Allocation_Tag] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Instrument_Group_Allocation_Tag]) as s
			ON ( t.[Allocation_Tag] = s.[Allocation_Tag])
			WHEN MATCHED AND (
				t.[Allocation_Description] <> s.[Allocation_Description]
				)
			THEN UPDATE SET 
				[Allocation_Description] = s.[Allocation_Description]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Allocation_Tag], [Allocation_Description])
				VALUES(s.[Allocation_Tag], s.[Allocation_Description])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Inserted.[Allocation_Tag],
				Deleted.[Allocation_Tag]
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Instrument_Allocation'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Instrument_Allocation] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Instrument_Allocation]) as s
			ON ( t.[Allocation_Tag] = s.[Allocation_Tag] AND t.[Fiscal_Year] = s.[Fiscal_Year] AND t.[Proposal_ID] = s.[Proposal_ID])
			WHEN MATCHED AND (
				ISNULL( NULLIF(t.[Allocated_Hours], s.[Allocated_Hours]),
						NULLIF(s.[Allocated_Hours], t.[Allocated_Hours])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Entered], s.[Entered]),
						NULLIF(s.[Entered], t.[Entered])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
						NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Allocated_Hours] = s.[Allocated_Hours],
				[Comment] = s.[Comment],
				[Entered] = s.[Entered],
				[Last_Affected] = s.[Last_Affected]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Allocation_Tag], [Proposal_ID], [Fiscal_Year], [Allocated_Hours], [Comment], [Entered], [Last_Affected])
				VALUES(s.[Allocation_Tag], s.[Proposal_ID], s.[Fiscal_Year], s.[Allocated_Hours], s.[Comment], s.[Entered], s.[Last_Affected])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Inserted.[Allocation_Tag] + ', ' + Cast(Inserted.[Fiscal_Year] as varchar(12)) + ', ' + Inserted.[Proposal_ID],
				Deleted.[Allocation_Tag] + ', ' + Cast(Deleted.[Fiscal_Year] as varchar(12)) + ', ' + Deleted.[Proposal_ID]
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 


			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End
		
		Set @tableName = 'T_Instrument_Allocation_Updates'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Instrument_Allocation_Updates] ON;
			 
			MERGE [dbo].[T_Instrument_Allocation_Updates] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Instrument_Allocation_Updates]) as s
			ON ( t.[Entry_ID] = s.[Entry_ID])
			WHEN MATCHED AND (
				t.[Allocation_Tag] <> s.[Allocation_Tag] OR
				t.[Proposal_ID] <> s.[Proposal_ID] OR
				ISNULL( NULLIF(t.[Fiscal_Year], s.[Fiscal_Year]),
						NULLIF(s.[Fiscal_Year], t.[Fiscal_Year])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Allocated_Hours_Old], s.[Allocated_Hours_Old]),
						NULLIF(s.[Allocated_Hours_Old], t.[Allocated_Hours_Old])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Allocated_Hours_New], s.[Allocated_Hours_New]),
						NULLIF(s.[Allocated_Hours_New], t.[Allocated_Hours_New])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Entered], s.[Entered]),
						NULLIF(s.[Entered], t.[Entered])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Entered_By], s.[Entered_By]),
						NULLIF(s.[Entered_By], t.[Entered_By])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Allocation_Tag] = s.[Allocation_Tag],
				[Proposal_ID] = s.[Proposal_ID],
				[Fiscal_Year] = s.[Fiscal_Year],
				[Allocated_Hours_Old] = s.[Allocated_Hours_Old],
				[Allocated_Hours_New] = s.[Allocated_Hours_New],
				[Comment] = s.[Comment],
				[Entered] = s.[Entered],
				[Entered_By] = s.[Entered_By]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Entry_ID], [Allocation_Tag], [Proposal_ID], [Fiscal_Year], [Allocated_Hours_Old], [Allocated_Hours_New], [Comment], [Entered], [Entered_By])
				VALUES(s.[Entry_ID], s.[Allocation_Tag], s.[Proposal_ID], s.[Fiscal_Year], s.[Allocated_Hours_Old], s.[Allocated_Hours_New], s.[Comment], s.[Entered], s.[Entered_By])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[Entry_ID] as varchar(12)),
				Cast(Deleted.[Entry_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Instrument_Allocation_Updates] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End


	End -- </ChargeCodesAndEUS>

	If @experiments <> 0
	Begin -- <Experiments>
		set @myrowcount=0
	End -- </Experiments>

	If @datasets <> 0
	Begin -- <Datasets>
		set @myrowcount=0
	End -- </Datasets>

	If @jobs <> 0
	Begin -- <Jobs>
		set @myrowcount=0
	End -- </Jobs>

Done:

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	
	If @message <> ''
		Select @message as Error
	Else
	Begin
		If @infoOnly = 0
			Select 'Complete' as Message
	End
		
	Return @myError

GO

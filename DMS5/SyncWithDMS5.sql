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
**			10/27/2015 mem - Add tables for @usersAndCampaigns, @chargeCodesAndEUS
**			10/28/2015 mem - Add tables for @experiments, @datasets, and @jobs
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
	@experiments tinyint = 0,			-- Includes cell cultures sample prep requests
	@datasets tinyint = 0,
	@jobs tinyint = 0,
	@yearsToCopy int = 2,				-- Used when importing experiments, datasets, and/or jobs
	@message varchar(255) = '' output
)
As
	set nocount on
	
	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	---------------------------------------------------
	-- Make sure we're not running in DMS5
	---------------------------------------------------
	
	If DB_Name() = 'DMS5'
	Begin
		Set @message = 'Error: This procedure cannot be used with DMS5 because DMS5 is the source database'
		Print @message
		
		Goto Done
	End

	Set @yearsToCopy = IsNull(@YearsToCopy, 4)
	If @yearsToCopy < 1
		Set @yearsToCopy = 1

	Declare @importThreshold datetime
	Set @importThreshold = DateAdd(year, -@YearsToCopy, GetDate())
	
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

		Set @tableName = 'T_Sample_Labelling'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Sample_Labelling] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Sample_Labelling]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[Label] <> s.[Label]
			    )
			THEN UPDATE SET 
			    [Label] = s.[Label]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Label], [ID])
			    VALUES(s.[Label], s.[ID])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
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

		Set @tableName = 'T_Enzymes'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Enzymes] ON;
			 
			MERGE [dbo].[T_Enzymes] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Enzymes]) as s
			ON ( t.[Enzyme_ID] = s.[Enzyme_ID])
			WHEN MATCHED AND (
			    t.[Enzyme_Name] <> s.[Enzyme_Name] OR
			    t.[Description] <> s.[Description] OR
			    t.[Cleavage_Method] <> s.[Cleavage_Method] OR
			    t.[Cleavage_Offset] <> s.[Cleavage_Offset] OR
			    ISNULL( NULLIF(t.[P1], s.[P1]),
			            NULLIF(s.[P1], t.[P1])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[P1_Exception], s.[P1_Exception]),
			            NULLIF(s.[P1_Exception], t.[P1_Exception])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[P2], s.[P2]),
			            NULLIF(s.[P2], t.[P2])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[P2_Exception], s.[P2_Exception]),
			            NULLIF(s.[P2_Exception], t.[P2_Exception])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Sequest_Enzyme_Index], s.[Sequest_Enzyme_Index]),
			            NULLIF(s.[Sequest_Enzyme_Index], t.[Sequest_Enzyme_Index])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Protein_Collection_Name], s.[Protein_Collection_Name]),
			            NULLIF(s.[Protein_Collection_Name], t.[Protein_Collection_Name])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Enzyme_Name] = s.[Enzyme_Name],
			    [Description] = s.[Description],
			    [P1] = s.[P1],
			    [P1_Exception] = s.[P1_Exception],
			    [P2] = s.[P2],
			    [P2_Exception] = s.[P2_Exception],
			    [Cleavage_Method] = s.[Cleavage_Method],
			    [Cleavage_Offset] = s.[Cleavage_Offset],
			    [Sequest_Enzyme_Index] = s.[Sequest_Enzyme_Index],
			    [Protein_Collection_Name] = s.[Protein_Collection_Name]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Enzyme_ID], [Enzyme_Name], [Description], [P1], [P1_Exception], [P2], [P2_Exception], [Cleavage_Method], [Cleavage_Offset], [Sequest_Enzyme_Index], [Protein_Collection_Name])
			    VALUES(s.[Enzyme_ID], s.[Enzyme_Name], s.[Description], s.[P1], s.[P1_Exception], s.[P2], s.[P2_Exception], s.[Cleavage_Method], s.[Cleavage_Offset], s.[Sequest_Enzyme_Index], s.[Protein_Collection_Name])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[Enzyme_ID] as varchar(12)),
			       Cast(Deleted.[Enzyme_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Enzymes] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Material_Locations'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Material_Locations] ON;
			 
			MERGE [dbo].[T_Material_Locations] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Material_Locations]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[Freezer] <> s.[Freezer] OR
			    t.[Shelf] <> s.[Shelf] OR
			    t.[Rack] <> s.[Rack] OR
			    t.[Row] <> s.[Row] OR
			    t.[Col] <> s.[Col] OR
			    t.[Status] <> s.[Status] OR
			    t.[Container_Limit] <> s.[Container_Limit] OR
			    ISNULL( NULLIF(t.[Tag], s.[Tag]),
			            NULLIF(s.[Tag], t.[Tag])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Barcode], s.[Barcode]),
			            NULLIF(s.[Barcode], t.[Barcode])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Comment], s.[Comment]),
			            NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Tag] = s.[Tag],
			    [Freezer] = s.[Freezer],
			    [Shelf] = s.[Shelf],
			    [Rack] = s.[Rack],
			    [Row] = s.[Row],
			    [Col] = s.[Col],
			    [Status] = s.[Status],
			    [Barcode] = s.[Barcode],
			    [Comment] = s.[Comment],
			    [Container_Limit] = s.[Container_Limit]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([ID], [Tag], [Freezer], [Shelf], [Rack], [Row], [Col], [Status], [Barcode], [Comment], [Container_Limit])
			    VALUES(s.[ID], s.[Tag], s.[Freezer], s.[Shelf], s.[Rack], s.[Row], s.[Col], s.[Status], s.[Barcode], s.[Comment], s.[Container_Limit])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Material_Locations] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Material_Containers'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Material_Containers] ON;
			 
			MERGE [dbo].[T_Material_Containers] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Material_Containers]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[Tag] <> s.[Tag] OR
			    t.[Type] <> s.[Type] OR
			    t.[Location_ID] <> s.[Location_ID] OR
			    t.[Created] <> s.[Created] OR
			    t.[Status] <> s.[Status] OR
			    ISNULL( NULLIF(t.[Comment], s.[Comment]),
			            NULLIF(s.[Comment], t.[Comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Barcode], s.[Barcode]),
			            NULLIF(s.[Barcode], t.[Barcode])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Researcher], s.[Researcher]),
			            NULLIF(s.[Researcher], t.[Researcher])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Tag] = s.[Tag],
			    [Type] = s.[Type],
			    [Comment] = s.[Comment],
			    [Barcode] = s.[Barcode],
			    [Location_ID] = s.[Location_ID],
			    [Created] = s.[Created],
			    [Status] = s.[Status],
			    [Researcher] = s.[Researcher]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([ID], [Tag], [Type], [Comment], [Barcode], [Location_ID], [Created], [Status], [Researcher])
			    VALUES(s.[ID], s.[Tag], s.[Type], s.[Comment], s.[Barcode], s.[Location_ID], s.[Created], s.[Status], s.[Researcher])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Material_Containers] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Sample_Prep_Request'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Sample_Prep_Request] ON;
			 
			MERGE [dbo].[T_Sample_Prep_Request] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Sample_Prep_Request]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[Request_Type] <> s.[Request_Type] OR
			    t.[Created] <> s.[Created] OR
			    t.[State] <> s.[State] OR
			    t.[StateChanged] <> s.[StateChanged] OR
			    t.[UseSingleLCColumn] <> s.[UseSingleLCColumn] OR
			    t.[Internal_standard_ID] <> s.[Internal_standard_ID] OR
			    t.[Postdigest_internal_std_ID] <> s.[Postdigest_internal_std_ID] OR
			    t.[Facility] <> s.[Facility] OR
			    t.[Number_Of_Biomaterial_Reps_Received] <> s.[Number_Of_Biomaterial_Reps_Received] OR
			  ISNULL( NULLIF(t.[Request_Name], s.[Request_Name]),
			            NULLIF(s.[Request_Name], t.[Request_Name])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Requester_PRN], s.[Requester_PRN]),
			            NULLIF(s.[Requester_PRN], t.[Requester_PRN])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Reason], s.[Reason]),
			            NULLIF(s.[Reason], t.[Reason])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Cell_Culture_List], s.[Cell_Culture_List]),
			            NULLIF(s.[Cell_Culture_List], t.[Cell_Culture_List])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Organism], s.[Organism]),
			            NULLIF(s.[Organism], t.[Organism])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Biohazard_Level], s.[Biohazard_Level]),
			            NULLIF(s.[Biohazard_Level], t.[Biohazard_Level])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Campaign], s.[Campaign]),
			            NULLIF(s.[Campaign], t.[Campaign])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Number_of_Samples], s.[Number_of_Samples]),
			            NULLIF(s.[Number_of_Samples], t.[Number_of_Samples])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Sample_Name_List], s.[Sample_Name_List]),
			            NULLIF(s.[Sample_Name_List], t.[Sample_Name_List])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Sample_Type], s.[Sample_Type]),
			            NULLIF(s.[Sample_Type], t.[Sample_Type])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Prep_Method], s.[Prep_Method]),
			            NULLIF(s.[Prep_Method], t.[Prep_Method])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Prep_By_Robot], s.[Prep_By_Robot]),
			            NULLIF(s.[Prep_By_Robot], t.[Prep_By_Robot])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Special_Instructions], s.[Special_Instructions]),
			            NULLIF(s.[Special_Instructions], t.[Special_Instructions])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Sample_Naming_Convention], s.[Sample_Naming_Convention]),
			            NULLIF(s.[Sample_Naming_Convention], t.[Sample_Naming_Convention])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Assigned_Personnel], s.[Assigned_Personnel]),
			            NULLIF(s.[Assigned_Personnel], t.[Assigned_Personnel])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Work_Package_Number], s.[Work_Package_Number]),
			            NULLIF(s.[Work_Package_Number], t.[Work_Package_Number])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[User_Proposal_Number], s.[User_Proposal_Number]),
			            NULLIF(s.[User_Proposal_Number], t.[User_Proposal_Number])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Replicates_of_Samples], s.[Replicates_of_Samples]),
			            NULLIF(s.[Replicates_of_Samples], t.[Replicates_of_Samples])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Technical_Replicates], s.[Technical_Replicates]),
			            NULLIF(s.[Technical_Replicates], t.[Technical_Replicates])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Instrument_Group], s.[Instrument_Group]),
			            NULLIF(s.[Instrument_Group], t.[Instrument_Group])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Instrument_Name], s.[Instrument_Name]),
			            NULLIF(s.[Instrument_Name], t.[Instrument_Name])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Dataset_Type], s.[Dataset_Type]),
			            NULLIF(s.[Dataset_Type], t.[Dataset_Type])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Instrument_Analysis_Specifications], s.[Instrument_Analysis_Specifications]),
			            NULLIF(s.[Instrument_Analysis_Specifications], t.[Instrument_Analysis_Specifications])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Comment], s.[Comment]),
			            NULLIF(s.[Comment], t.[Comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Priority], s.[Priority]),
			            NULLIF(s.[Priority], t.[Priority])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Requested_Personnel], s.[Requested_Personnel]),
			            NULLIF(s.[Requested_Personnel], t.[Requested_Personnel])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Estimated_Completion], s.[Estimated_Completion]),
			            NULLIF(s.[Estimated_Completion], t.[Estimated_Completion])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Estimated_MS_runs], s.[Estimated_MS_runs]),
			            NULLIF(s.[Estimated_MS_runs], t.[Estimated_MS_runs])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EUS_UsageType], s.[EUS_UsageType]),
			            NULLIF(s.[EUS_UsageType], t.[EUS_UsageType])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EUS_Proposal_ID], s.[EUS_Proposal_ID]),
			            NULLIF(s.[EUS_Proposal_ID], t.[EUS_Proposal_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EUS_User_List], s.[EUS_User_List]),
			            NULLIF(s.[EUS_User_List], t.[EUS_User_List])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Project_Number], s.[Project_Number]),
			            NULLIF(s.[Project_Number], t.[Project_Number])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Separation_Type], s.[Separation_Type]),
			            NULLIF(s.[Separation_Type], t.[Separation_Type])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[BlockAndRandomizeSamples], s.[BlockAndRandomizeSamples]),
			            NULLIF(s.[BlockAndRandomizeSamples], t.[BlockAndRandomizeSamples])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[BlockAndRandomizeRuns], s.[BlockAndRandomizeRuns]),
			            NULLIF(s.[BlockAndRandomizeRuns], t.[BlockAndRandomizeRuns])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[IOPSPermitsCurrent], s.[IOPSPermitsCurrent]),
			            NULLIF(s.[IOPSPermitsCurrent], t.[IOPSPermitsCurrent])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Reason_For_High_Priority], s.[Reason_For_High_Priority]),
			            NULLIF(s.[Reason_For_High_Priority], t.[Reason_For_High_Priority])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Sample_Submission_Item_Count], s.[Sample_Submission_Item_Count]),
			            NULLIF(s.[Sample_Submission_Item_Count], t.[Sample_Submission_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Biomaterial_Item_Count], s.[Biomaterial_Item_Count]),
			            NULLIF(s.[Biomaterial_Item_Count], t.[Biomaterial_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Experiment_Item_Count], s.[Experiment_Item_Count]),
			            NULLIF(s.[Experiment_Item_Count], t.[Experiment_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Experiment_Group_Item_Count], s.[Experiment_Group_Item_Count]),
			            NULLIF(s.[Experiment_Group_Item_Count], t.[Experiment_Group_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Material_Containers_Item_Count], s.[Material_Containers_Item_Count]),
			            NULLIF(s.[Material_Containers_Item_Count], t.[Material_Containers_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Requested_Run_Item_Count], s.[Requested_Run_Item_Count]),
			            NULLIF(s.[Requested_Run_Item_Count], t.[Requested_Run_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Dataset_Item_Count], s.[Dataset_Item_Count]),
			            NULLIF(s.[Dataset_Item_Count], t.[Dataset_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[HPLC_Runs_Item_Count], s.[HPLC_Runs_Item_Count]),
			            NULLIF(s.[HPLC_Runs_Item_Count], t.[HPLC_Runs_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Total_Item_Count], s.[Total_Item_Count]),
			            NULLIF(s.[Total_Item_Count], t.[Total_Item_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Material_Container_List], s.[Material_Container_List]),
			            NULLIF(s.[Material_Container_List], t.[Material_Container_List])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Request_Type] = s.[Request_Type],
			    [Request_Name] = s.[Request_Name],
			    [Requester_PRN] = s.[Requester_PRN],
			    [Reason] = s.[Reason],
			    [Cell_Culture_List] = s.[Cell_Culture_List],
			    [Organism] = s.[Organism],
			    [Biohazard_Level] = s.[Biohazard_Level],
			    [Campaign] = s.[Campaign],
			    [Number_of_Samples] = s.[Number_of_Samples],
			    [Sample_Name_List] = s.[Sample_Name_List],
			    [Sample_Type] = s.[Sample_Type],
			    [Prep_Method] = s.[Prep_Method],
			    [Prep_By_Robot] = s.[Prep_By_Robot],
			    [Special_Instructions] = s.[Special_Instructions],
			    [Sample_Naming_Convention] = s.[Sample_Naming_Convention],
			    [Assigned_Personnel] = s.[Assigned_Personnel],
			    [Work_Package_Number] = s.[Work_Package_Number],
			    [User_Proposal_Number] = s.[User_Proposal_Number],
			    [Replicates_of_Samples] = s.[Replicates_of_Samples],
			    [Technical_Replicates] = s.[Technical_Replicates],
			    [Instrument_Group] = s.[Instrument_Group],
			    [Instrument_Name] = s.[Instrument_Name],
			    [Dataset_Type] = s.[Dataset_Type],
			    [Instrument_Analysis_Specifications] = s.[Instrument_Analysis_Specifications],
			    [Comment] = s.[Comment],
			    [Priority] = s.[Priority],
			    [Created] = s.[Created],
			    [State] = s.[State],
			    [Requested_Personnel] = s.[Requested_Personnel],
			    [StateChanged] = s.[StateChanged],
			    [UseSingleLCColumn] = s.[UseSingleLCColumn],
			    [Internal_standard_ID] = s.[Internal_standard_ID],
			    [Postdigest_internal_std_ID] = s.[Postdigest_internal_std_ID],
			    [Estimated_Completion] = s.[Estimated_Completion],
			    [Estimated_MS_runs] = s.[Estimated_MS_runs],
			    [EUS_UsageType] = s.[EUS_UsageType],
			    [EUS_Proposal_ID] = s.[EUS_Proposal_ID],
			    [EUS_User_List] = s.[EUS_User_List],
			    [Project_Number] = s.[Project_Number],
			    [Facility] = s.[Facility],
			    [Separation_Type] = s.[Separation_Type],
			    [BlockAndRandomizeSamples] = s.[BlockAndRandomizeSamples],
			    [BlockAndRandomizeRuns] = s.[BlockAndRandomizeRuns],
			    [IOPSPermitsCurrent] = s.[IOPSPermitsCurrent],
			    [Reason_For_High_Priority] = s.[Reason_For_High_Priority],
			    [Number_Of_Biomaterial_Reps_Received] = s.[Number_Of_Biomaterial_Reps_Received],
			    [Sample_Submission_Item_Count] = s.[Sample_Submission_Item_Count],
			    [Biomaterial_Item_Count] = s.[Biomaterial_Item_Count],
			    [Experiment_Item_Count] = s.[Experiment_Item_Count],
			    [Experiment_Group_Item_Count] = s.[Experiment_Group_Item_Count],
			    [Material_Containers_Item_Count] = s.[Material_Containers_Item_Count],
			    [Requested_Run_Item_Count] = s.[Requested_Run_Item_Count],
			    [Dataset_Item_Count] = s.[Dataset_Item_Count],
			    [HPLC_Runs_Item_Count] = s.[HPLC_Runs_Item_Count],
			    [Total_Item_Count] = s.[Total_Item_Count],
			    [Material_Container_List] = s.[Material_Container_List]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([ID], [Request_Type], [Request_Name], [Requester_PRN], [Reason], [Cell_Culture_List], [Organism], [Biohazard_Level], [Campaign], [Number_of_Samples], [Sample_Name_List], [Sample_Type], [Prep_Method], [Prep_By_Robot], [Special_Instructions], [Sample_Naming_Convention], [Assigned_Personnel], [Work_Package_Number], [User_Proposal_Number], [Replicates_of_Samples], [Technical_Replicates], [Instrument_Group], [Instrument_Name], [Dataset_Type], [Instrument_Analysis_Specifications], [Comment], [Priority], [Created], [State], [Requested_Personnel], [StateChanged], [UseSingleLCColumn], [Internal_standard_ID], [Postdigest_internal_std_ID], [Estimated_Completion], [Estimated_MS_runs], [EUS_UsageType], [EUS_Proposal_ID], [EUS_User_List], [Project_Number], [Facility], [Separation_Type], [BlockAndRandomizeSamples], [BlockAndRandomizeRuns], [IOPSPermitsCurrent], [Reason_For_High_Priority], [Number_Of_Biomaterial_Reps_Received], [Sample_Submission_Item_Count], [Biomaterial_Item_Count], [Experiment_Item_Count], [Experiment_Group_Item_Count], [Material_Containers_Item_Count], [Requested_Run_Item_Count], [Dataset_Item_Count], [HPLC_Runs_Item_Count], [Total_Item_Count], [Material_Container_List])
			    VALUES(s.[ID], s.[Request_Type], s.[Request_Name], s.[Requester_PRN], s.[Reason], s.[Cell_Culture_List], s.[Organism], s.[Biohazard_Level], s.[Campaign], s.[Number_of_Samples], s.[Sample_Name_List], s.[Sample_Type], s.[Prep_Method], s.[Prep_By_Robot], s.[Special_Instructions], s.[Sample_Naming_Convention], s.[Assigned_Personnel], s.[Work_Package_Number], s.[User_Proposal_Number], s.[Replicates_of_Samples], s.[Technical_Replicates], s.[Instrument_Group], s.[Instrument_Name], s.[Dataset_Type], s.[Instrument_Analysis_Specifications], s.[Comment], s.[Priority], s.[Created], s.[State], s.[Requested_Personnel], s.[StateChanged], s.[UseSingleLCColumn], s.[Internal_standard_ID], s.[Postdigest_internal_std_ID], s.[Estimated_Completion], s.[Estimated_MS_runs], s.[EUS_UsageType], s.[EUS_Proposal_ID], s.[EUS_User_List], s.[Project_Number], s.[Facility], s.[Separation_Type], s.[BlockAndRandomizeSamples], s.[BlockAndRandomizeRuns], s.[IOPSPermitsCurrent], s.[Reason_For_High_Priority], s.[Number_Of_Biomaterial_Reps_Received], s.[Sample_Submission_Item_Count], s.[Biomaterial_Item_Count], s.[Experiment_Item_Count], s.[Experiment_Group_Item_Count], s.[Material_Containers_Item_Count], s.[Requested_Run_Item_Count], s.[Dataset_Item_Count], s.[HPLC_Runs_Item_Count], s.[Total_Item_Count], s.[Material_Container_List])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Sample_Prep_Request] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Sample_Submission'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Sample_Submission] ON;
			 
			MERGE [dbo].[T_Sample_Submission] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Sample_Submission]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[Campaign_ID] <> s.[Campaign_ID] OR
			    t.[Received_By_User_ID] <> s.[Received_By_User_ID] OR
			    t.[Created] <> s.[Created] OR
			    ISNULL( NULLIF(t.[Container_List], s.[Container_List]),
			            NULLIF(s.[Container_List], t.[Container_List])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Description], s.[Description]),
			            NULLIF(s.[Description], t.[Description])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Storage_Path], s.[Storage_Path]),
			            NULLIF(s.[Storage_Path], t.[Storage_Path])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Campaign_ID] = s.[Campaign_ID],
			    [Received_By_User_ID] = s.[Received_By_User_ID],
			    [Container_List] = s.[Container_List],
			    [Description] = s.[Description],
			    [Storage_Path] = s.[Storage_Path],
			    [Created] = s.[Created]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([ID], [Campaign_ID], [Received_By_User_ID], [Container_List], [Description], [Storage_Path], [Created])
			    VALUES(s.[ID], s.[Campaign_ID], s.[Received_By_User_ID], s.[Container_List], s.[Description], s.[Storage_Path], s.[Created])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Sample_Submission] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Cell_Culture'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Cell_Culture] ON;
			 
			MERGE [dbo].[T_Cell_Culture] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Cell_Culture]) as s
			ON ( t.[CC_ID] = s.[CC_ID])
			WHEN MATCHED AND (
			    t.[CC_Name] <> s.[CC_Name] OR
			    t.[CC_Container_ID] <> s.[CC_Container_ID] OR
			    t.[CC_Material_Active] <> s.[CC_Material_Active] OR
			    ISNULL( NULLIF(t.[CC_Source_Name], s.[CC_Source_Name]),
			            NULLIF(s.[CC_Source_Name], t.[CC_Source_Name])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CC_Contact_PRN], s.[CC_Contact_PRN]),
			            NULLIF(s.[CC_Contact_PRN], t.[CC_Contact_PRN])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CC_PI_PRN], s.[CC_PI_PRN]),
			            NULLIF(s.[CC_PI_PRN], t.[CC_PI_PRN])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CC_Type], s.[CC_Type]),
			            NULLIF(s.[CC_Type], t.[CC_Type])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CC_Reason], s.[CC_Reason]),
			            NULLIF(s.[CC_Reason], t.[CC_Reason])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CC_Comment], s.[CC_Comment]),
			            NULLIF(s.[CC_Comment], t.[CC_Comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CC_Campaign_ID], s.[CC_Campaign_ID]),
			            NULLIF(s.[CC_Campaign_ID], t.[CC_Campaign_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CC_Created], s.[CC_Created]),
			            NULLIF(s.[CC_Created], t.[CC_Created])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Gene_Name], s.[Gene_Name]),
			            NULLIF(s.[Gene_Name], t.[Gene_Name])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Gene_Location], s.[Gene_Location]),
			            NULLIF(s.[Gene_Location], t.[Gene_Location])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Mod_Count], s.[Mod_Count]),
			            NULLIF(s.[Mod_Count], t.[Mod_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Modifications], s.[Modifications]),
			            NULLIF(s.[Modifications], t.[Modifications])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Mass], s.[Mass]),
			            NULLIF(s.[Mass], t.[Mass])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Purchase_Date], s.[Purchase_Date]),
			            NULLIF(s.[Purchase_Date], t.[Purchase_Date])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Peptide_Purity], s.[Peptide_Purity]),
			            NULLIF(s.[Peptide_Purity], t.[Peptide_Purity])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Purchase_Quantity], s.[Purchase_Quantity]),
			            NULLIF(s.[Purchase_Quantity], t.[Purchase_Quantity])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [CC_Name] = s.[CC_Name],
			    [CC_Source_Name] = s.[CC_Source_Name],
			    [CC_Contact_PRN] = s.[CC_Contact_PRN],
			    [CC_PI_PRN] = s.[CC_PI_PRN],
			    [CC_Type] = s.[CC_Type],
			    [CC_Reason] = s.[CC_Reason],
			    [CC_Comment] = s.[CC_Comment],
			    [CC_Campaign_ID] = s.[CC_Campaign_ID],
			    [CC_Container_ID] = s.[CC_Container_ID],
			    [CC_Material_Active] = s.[CC_Material_Active],
			    [CC_Created] = s.[CC_Created],
			    [Gene_Name] = s.[Gene_Name],
			    [Gene_Location] = s.[Gene_Location],
			    [Mod_Count] = s.[Mod_Count],
			    [Modifications] = s.[Modifications],
			    [Mass] = s.[Mass],
			    [Purchase_Date] = s.[Purchase_Date],
			    [Peptide_Purity] = s.[Peptide_Purity],
			    [Purchase_Quantity] = s.[Purchase_Quantity]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([CC_Name], [CC_Source_Name], [CC_Contact_PRN], [CC_PI_PRN], [CC_Type], [CC_Reason], [CC_Comment], [CC_Campaign_ID], [CC_ID], [CC_Container_ID], [CC_Material_Active], [CC_Created], [Gene_Name], [Gene_Location], [Mod_Count], [Modifications], [Mass], [Purchase_Date], [Peptide_Purity], [Purchase_Quantity])
			    VALUES(s.[CC_Name], s.[CC_Source_Name], s.[CC_Contact_PRN], s.[CC_PI_PRN], s.[CC_Type], s.[CC_Reason], s.[CC_Comment], s.[CC_Campaign_ID], s.[CC_ID], s.[CC_Container_ID], s.[CC_Material_Active], s.[CC_Created], s.[Gene_Name], s.[Gene_Location], s.[Mod_Count], s.[Modifications], s.[Mass], s.[Purchase_Date], s.[Peptide_Purity], s.[Purchase_Quantity])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[CC_ID] as varchar(12)),
			       Cast(Deleted.[CC_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Cell_Culture] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Organisms'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Organisms] ON;
			 
			MERGE [dbo].[T_Organisms] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Organisms]) as s
			ON ( t.[Organism_ID] = s.[Organism_ID])
			WHEN MATCHED AND (
				t.[OG_name] <> s.[OG_name] OR
				ISNULL( NULLIF(t.[OG_organismDBName], s.[OG_organismDBName]),
						NULLIF(s.[OG_organismDBName], t.[OG_organismDBName])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_created], s.[OG_created]),
						NULLIF(s.[OG_created], t.[OG_created])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_description], s.[OG_description]),
						NULLIF(s.[OG_description], t.[OG_description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Short_Name], s.[OG_Short_Name]),
						NULLIF(s.[OG_Short_Name], t.[OG_Short_Name])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Storage_Location], s.[OG_Storage_Location]),
						NULLIF(s.[OG_Storage_Location], t.[OG_Storage_Location])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Domain], s.[OG_Domain]),
						NULLIF(s.[OG_Domain], t.[OG_Domain])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Kingdom], s.[OG_Kingdom]),
						NULLIF(s.[OG_Kingdom], t.[OG_Kingdom])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Phylum], s.[OG_Phylum]),
						NULLIF(s.[OG_Phylum], t.[OG_Phylum])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Class], s.[OG_Class]),
						NULLIF(s.[OG_Class], t.[OG_Class])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Order], s.[OG_Order]),
						NULLIF(s.[OG_Order], t.[OG_Order])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Family], s.[OG_Family]),
						NULLIF(s.[OG_Family], t.[OG_Family])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Genus], s.[OG_Genus]),
						NULLIF(s.[OG_Genus], t.[OG_Genus])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Species], s.[OG_Species]),
						NULLIF(s.[OG_Species], t.[OG_Species])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Strain], s.[OG_Strain]),
						NULLIF(s.[OG_Strain], t.[OG_Strain])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_DNA_Translation_Table_ID], s.[OG_DNA_Translation_Table_ID]),
						NULLIF(s.[OG_DNA_Translation_Table_ID], t.[OG_DNA_Translation_Table_ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Mito_DNA_Translation_Table_ID], s.[OG_Mito_DNA_Translation_Table_ID]),
						NULLIF(s.[OG_Mito_DNA_Translation_Table_ID], t.[OG_Mito_DNA_Translation_Table_ID])) IS NOT NULL OR
				ISNULL( NULLIF(t.[OG_Active], s.[OG_Active]),
						NULLIF(s.[OG_Active], t.[OG_Active])) IS NOT NULL OR
				ISNULL( NULLIF(t.[NEWT_Identifier], s.[NEWT_Identifier]),
						NULLIF(s.[NEWT_Identifier], t.[NEWT_Identifier])) IS NOT NULL OR
				ISNULL( NULLIF(t.[NEWT_ID_List], s.[NEWT_ID_List]),
						NULLIF(s.[NEWT_ID_List], t.[NEWT_ID_List])) IS NOT NULL
				)
			THEN UPDATE SET 
				[OG_name] = s.[OG_name],
				[OG_organismDBName] = s.[OG_organismDBName],
				[OG_created] = s.[OG_created],
				[OG_description] = s.[OG_description],
				[OG_Short_Name] = s.[OG_Short_Name],
				[OG_Storage_Location] = s.[OG_Storage_Location],
				[OG_Domain] = s.[OG_Domain],
				[OG_Kingdom] = s.[OG_Kingdom],
				[OG_Phylum] = s.[OG_Phylum],
				[OG_Class] = s.[OG_Class],
				[OG_Order] = s.[OG_Order],
				[OG_Family] = s.[OG_Family],
				[OG_Genus] = s.[OG_Genus],
				[OG_Species] = s.[OG_Species],
				[OG_Strain] = s.[OG_Strain],
				[OG_DNA_Translation_Table_ID] = s.[OG_DNA_Translation_Table_ID],
				[OG_Mito_DNA_Translation_Table_ID] = s.[OG_Mito_DNA_Translation_Table_ID],
				[OG_Active] = s.[OG_Active],
				[NEWT_Identifier] = s.[NEWT_Identifier],
				[NEWT_ID_List] = s.[NEWT_ID_List]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([OG_name], [Organism_ID], [OG_organismDBName], [OG_created], [OG_description], [OG_Short_Name], [OG_Storage_Location], [OG_Domain], [OG_Kingdom], [OG_Phylum], [OG_Class], [OG_Order], [OG_Family], [OG_Genus], [OG_Species], [OG_Strain], [OG_DNA_Translation_Table_ID], [OG_Mito_DNA_Translation_Table_ID], [OG_Active], [NEWT_Identifier], [NEWT_ID_List])
				VALUES(s.[OG_name], s.[Organism_ID], s.[OG_organismDBName], s.[OG_created], s.[OG_description], s.[OG_Short_Name], s.[OG_Storage_Location], s.[OG_Domain], s.[OG_Kingdom], s.[OG_Phylum], s.[OG_Class], s.[OG_Order], s.[OG_Family], s.[OG_Genus], s.[OG_Species], s.[OG_Strain], s.[OG_DNA_Translation_Table_ID], s.[OG_Mito_DNA_Translation_Table_ID], s.[OG_Active], s.[NEWT_Identifier], s.[NEWT_ID_List])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[Organism_ID] as varchar(12)),
				Cast(Deleted.[Organism_ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Organisms] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Experiments'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Experiments] ON;
			 
			MERGE [dbo].[T_Experiments] AS t
			USING (SELECT ExpSource.* 
			       FROM [DMS5].[dbo].[T_Experiments] ExpSource LEFT OUTER Join 
			                         [T_Experiments] ExpTarget ON ExpSource.Exp_ID = ExpTarget.Exp_ID
			       WHERE ExpSource.Ex_Created >= @importThreshold OR
			             Not ExpTarget.Exp_ID IS Null OR
			             ExpSource.Experiment_Num IN ('DMS_Pipeline_Data')) as s
			ON ( t.[Exp_ID] = s.[Exp_ID])
			WHEN MATCHED AND (
			    t.[Experiment_Num] <> s.[Experiment_Num] OR
			    t.[EX_organism_ID] <> s.[EX_organism_ID] OR
			    t.[EX_created] <> s.[EX_created] OR
			    t.[EX_campaign_ID] <> s.[EX_campaign_ID] OR
			    t.[EX_Container_ID] <> s.[EX_Container_ID] OR
			    t.[Ex_Material_Active] <> s.[Ex_Material_Active] OR
			    t.[EX_enzyme_ID] <> s.[EX_enzyme_ID] OR
			    t.[EX_sample_prep_request_ID] <> s.[EX_sample_prep_request_ID] OR
			    t.[EX_internal_standard_ID] <> s.[EX_internal_standard_ID] OR
			    t.[EX_postdigest_internal_std_ID] <> s.[EX_postdigest_internal_std_ID] OR
			    t.[EX_Alkylation] <> s.[EX_Alkylation] OR
			    t.[Last_Used] <> s.[Last_Used] OR
			    ISNULL( NULLIF(t.[EX_researcher_PRN], s.[EX_researcher_PRN]),
			            NULLIF(s.[EX_researcher_PRN], t.[EX_researcher_PRN])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_reason], s.[EX_reason]),
			            NULLIF(s.[EX_reason], t.[EX_reason])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_comment], s.[EX_comment]),
			            NULLIF(s.[EX_comment], t.[EX_comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_sample_concentration], s.[EX_sample_concentration]),
			            NULLIF(s.[EX_sample_concentration], t.[EX_sample_concentration])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_lab_notebook_ref], s.[EX_lab_notebook_ref]),
			            NULLIF(s.[EX_lab_notebook_ref], t.[EX_lab_notebook_ref])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_cell_culture_list], s.[EX_cell_culture_list]),
			            NULLIF(s.[EX_cell_culture_list], t.[EX_cell_culture_list])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_Labelling], s.[EX_Labelling]),
			            NULLIF(s.[EX_Labelling], t.[EX_Labelling])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_wellplate_num], s.[EX_wellplate_num]),
			            NULLIF(s.[EX_wellplate_num], t.[EX_wellplate_num])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_well_num], s.[EX_well_num]),
			            NULLIF(s.[EX_well_num], t.[EX_well_num])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[EX_Barcode], s.[EX_Barcode]),
			            NULLIF(s.[EX_Barcode], t.[EX_Barcode])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Experiment_Num] = s.[Experiment_Num],
			    [EX_researcher_PRN] = s.[EX_researcher_PRN],
			 [EX_organism_ID] = s.[EX_organism_ID],
			    [EX_reason] = s.[EX_reason],
			    [EX_comment] = s.[EX_comment],
			    [EX_created] = s.[EX_created],
			    [EX_sample_concentration] = s.[EX_sample_concentration],
			    [EX_lab_notebook_ref] = s.[EX_lab_notebook_ref],
			    [EX_campaign_ID] = s.[EX_campaign_ID],
			    [EX_cell_culture_list] = s.[EX_cell_culture_list],
			    [EX_Labelling] = s.[EX_Labelling],
			    [EX_Container_ID] = s.[EX_Container_ID],
			    [Ex_Material_Active] = s.[Ex_Material_Active],
			    [EX_enzyme_ID] = s.[EX_enzyme_ID],
			    [EX_sample_prep_request_ID] = s.[EX_sample_prep_request_ID],
			    [EX_internal_standard_ID] = s.[EX_internal_standard_ID],
			    [EX_postdigest_internal_std_ID] = s.[EX_postdigest_internal_std_ID],
			    [EX_wellplate_num] = s.[EX_wellplate_num],
			    [EX_well_num] = s.[EX_well_num],
			    [EX_Alkylation] = s.[EX_Alkylation],
			    [EX_Barcode] = s.[EX_Barcode],
			    [Last_Used] = s.[Last_Used]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Experiment_Num], [EX_researcher_PRN], [EX_organism_ID], [EX_reason], [EX_comment], [EX_created], [EX_sample_concentration], [EX_lab_notebook_ref], [EX_campaign_ID], [EX_cell_culture_list], [EX_Labelling], [Exp_ID], [EX_Container_ID], [Ex_Material_Active], [EX_enzyme_ID], [EX_sample_prep_request_ID], [EX_internal_standard_ID], [EX_postdigest_internal_std_ID], [EX_wellplate_num], [EX_well_num], [EX_Alkylation], [EX_Barcode], [Last_Used])
			    VALUES(s.[Experiment_Num], s.[EX_researcher_PRN], s.[EX_organism_ID], s.[EX_reason], s.[EX_comment], s.[EX_created], s.[EX_sample_concentration], s.[EX_lab_notebook_ref], s.[EX_campaign_ID], s.[EX_cell_culture_list], s.[EX_Labelling], s.[Exp_ID], s.[EX_Container_ID], s.[Ex_Material_Active], s.[EX_enzyme_ID], s.[EX_sample_prep_request_ID], s.[EX_internal_standard_ID], s.[EX_postdigest_internal_std_ID], s.[EX_wellplate_num], s.[EX_well_num], s.[EX_Alkylation], s.[EX_Barcode], s.[Last_Used])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[Exp_ID] as varchar(12)),
			       Cast(Deleted.[Exp_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Experiments] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End
		
	End -- </Experiments>

	If @datasets <> 0
	Begin -- <Datasets>

		Set @tableName = 'T_Separation_Group'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
 
			MERGE [dbo].[T_Separation_Group] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Separation_Group]) as s
			ON ( t.[Sep_Group] = s.[Sep_Group])
			WHEN MATCHED AND (
				t.[Active] <> s.[Active] OR
				ISNULL( NULLIF(t.[Comment], s.[Comment]),
						NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Comment] = s.[Comment],
				[Active] = s.[Active]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Sep_Group], [Comment], [Active])
				VALUES(s.[Sep_Group], s.[Comment], s.[Active])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Inserted.[Sep_Group],
				Deleted.[Sep_Group]
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
		
		Set @tableName = 'T_Secondary_Sep'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Secondary_Sep] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Secondary_Sep]) as s
			ON ( t.[SS_ID] = s.[SS_ID])
			WHEN MATCHED AND (
				t.[SS_name] <> s.[SS_name] OR
				t.[SS_comment] <> s.[SS_comment] OR
				t.[SS_active] <> s.[SS_active] OR
				t.[Sep_Group] <> s.[Sep_Group]
				)
			THEN UPDATE SET 
				[SS_name] = s.[SS_name],
				[SS_comment] = s.[SS_comment],
				[SS_active] = s.[SS_active],
				[Sep_Group] = s.[Sep_Group]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([SS_name], [SS_ID], [SS_comment], [SS_active], [Sep_Group])
				VALUES(s.[SS_name], s.[SS_ID], s.[SS_comment], s.[SS_active], s.[Sep_Group])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[SS_ID] as varchar(12)),
				Cast(Deleted.[SS_ID] as varchar(12))
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

		Set @tableName = 'T_LC_Column'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_LC_Column] ON;
			 
			MERGE [dbo].[T_LC_Column] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_LC_Column]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
				t.[SC_Column_Number] <> s.[SC_Column_Number] OR
				t.[SC_Packing_Mfg] <> s.[SC_Packing_Mfg] OR
				t.[SC_Packing_Type] <> s.[SC_Packing_Type] OR
				t.[SC_Particle_size] <> s.[SC_Particle_size] OR
				t.[SC_Particle_type] <> s.[SC_Particle_type] OR
				t.[SC_Column_Inner_Dia] <> s.[SC_Column_Inner_Dia] OR
				t.[SC_Column_Outer_Dia] <> s.[SC_Column_Outer_Dia] OR
				t.[SC_Length] <> s.[SC_Length] OR
				t.[SC_State] <> s.[SC_State] OR
				t.[SC_Operator_PRN] <> s.[SC_Operator_PRN] OR
				ISNULL( NULLIF(t.[SC_Comment], s.[SC_Comment]),
						NULLIF(s.[SC_Comment], t.[SC_Comment])) IS NOT NULL OR
				ISNULL( NULLIF(t.[SC_Created], s.[SC_Created]),
						NULLIF(s.[SC_Created], t.[SC_Created])) IS NOT NULL
				)
			THEN UPDATE SET 
				[SC_Column_Number] = s.[SC_Column_Number],
				[SC_Packing_Mfg] = s.[SC_Packing_Mfg],
				[SC_Packing_Type] = s.[SC_Packing_Type],
				[SC_Particle_size] = s.[SC_Particle_size],
				[SC_Particle_type] = s.[SC_Particle_type],
				[SC_Column_Inner_Dia] = s.[SC_Column_Inner_Dia],
				[SC_Column_Outer_Dia] = s.[SC_Column_Outer_Dia],
				[SC_Length] = s.[SC_Length],
				[SC_State] = s.[SC_State],
				[SC_Operator_PRN] = s.[SC_Operator_PRN],
				[SC_Comment] = s.[SC_Comment],
				[SC_Created] = s.[SC_Created]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([SC_Column_Number], [SC_Packing_Mfg], [SC_Packing_Type], [SC_Particle_size], [SC_Particle_type], [SC_Column_Inner_Dia], [SC_Column_Outer_Dia], [SC_Length], [SC_State], [SC_Operator_PRN], [SC_Comment], [SC_Created], [ID])
				VALUES(s.[SC_Column_Number], s.[SC_Packing_Mfg], s.[SC_Packing_Type], s.[SC_Particle_size], s.[SC_Particle_type], s.[SC_Column_Inner_Dia], s.[SC_Column_Outer_Dia], s.[SC_Length], s.[SC_State], s.[SC_Operator_PRN], s.[SC_Comment], s.[SC_Created], s.[ID])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[ID] as varchar(12)),
				Cast(Deleted.[ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_LC_Column] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End
		
		Set @tableName = 'T_LC_Cart'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_LC_cart] ON;
			 
			MERGE [dbo].[T_LC_cart] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_LC_cart]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
				t.[Cart_Name] <> s.[Cart_Name] OR
				t.[Cart_State_ID] <> s.[Cart_State_ID] OR
				ISNULL( NULLIF(t.[Cart_Description], s.[Cart_Description]),
						NULLIF(s.[Cart_Description], t.[Cart_Description])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Cart_Name] = s.[Cart_Name],
				[Cart_State_ID] = s.[Cart_State_ID],
				[Cart_Description] = s.[Cart_Description]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([ID], [Cart_Name], [Cart_State_ID], [Cart_Description])
				VALUES(s.[ID], s.[Cart_Name], s.[Cart_State_ID], s.[Cart_Description])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[ID] as varchar(12)),
				Cast(Deleted.[ID] as varchar(12))
				INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_LC_cart] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End
				
		Set @tableName = 'T_Dataset'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Dataset] ON;
			 
			MERGE [dbo].[T_Dataset] AS t
			USING (SELECT DSSource.* 
			       FROM [DMS5].[dbo].[T_Dataset] DSSource INNER JOIN 
			            [T_Experiments] E ON DSSource.Exp_ID = E.Exp_ID LEFT OUTER JOIN 
			            [T_Dataset] DSTarget ON DSSource.Dataset_ID = DSTarget.Dataset_ID
			       WHERE DSSource.DS_Created >= @importThreshold OR
			             Not DSTarget.Dataset_ID IS Null OR
			             DSSource.Dataset_Num Like 'DataPackage_[0-9]%') as s
			ON ( t.[Dataset_ID] = s.[Dataset_ID])
			WHEN MATCHED AND (
			    t.[Dataset_Num] <> s.[Dataset_Num] OR
			    t.[DS_Oper_PRN] <> s.[DS_Oper_PRN] OR
			    t.[DS_created] <> s.[DS_created] OR
			    t.[DS_state_ID] <> s.[DS_state_ID] OR
			    t.[Exp_ID] <> s.[Exp_ID] OR
			    t.[DS_rating] <> s.[DS_rating] OR
			    t.[DS_PrepServerName] <> s.[DS_PrepServerName] OR
			    t.[DateSortKey] <> s.[DateSortKey] OR
			    ISNULL( NULLIF(t.[DS_comment], s.[DS_comment]),
			            NULLIF(s.[DS_comment], t.[DS_comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_instrument_name_ID], s.[DS_instrument_name_ID]),
			            NULLIF(s.[DS_instrument_name_ID], t.[DS_instrument_name_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_LC_column_ID], s.[DS_LC_column_ID]),
			       NULLIF(s.[DS_LC_column_ID], t.[DS_LC_column_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_type_ID], s.[DS_type_ID]),
			            NULLIF(s.[DS_type_ID], t.[DS_type_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_wellplate_num], s.[DS_wellplate_num]),
			            NULLIF(s.[DS_wellplate_num], t.[DS_wellplate_num])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_well_num], s.[DS_well_num]),
			            NULLIF(s.[DS_well_num], t.[DS_well_num])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_sec_sep], s.[DS_sec_sep]),
			            NULLIF(s.[DS_sec_sep], t.[DS_sec_sep])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_folder_name], s.[DS_folder_name]),
			            NULLIF(s.[DS_folder_name], t.[DS_folder_name])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_storage_path_ID], s.[DS_storage_path_ID]),
			            NULLIF(s.[DS_storage_path_ID], t.[DS_storage_path_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_internal_standard_ID], s.[DS_internal_standard_ID]),
			            NULLIF(s.[DS_internal_standard_ID], t.[DS_internal_standard_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_Comp_State], s.[DS_Comp_State]),
			            NULLIF(s.[DS_Comp_State], t.[DS_Comp_State])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DS_Compress_Date], s.[DS_Compress_Date]),
			            NULLIF(s.[DS_Compress_Date], t.[DS_Compress_Date])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Acq_Time_Start], s.[Acq_Time_Start]),
			            NULLIF(s.[Acq_Time_Start], t.[Acq_Time_Start])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Acq_Time_End], s.[Acq_Time_End]),
			            NULLIF(s.[Acq_Time_End], t.[Acq_Time_End])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Scan_Count], s.[Scan_Count]),
			            NULLIF(s.[Scan_Count], t.[Scan_Count])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[File_Size_Bytes], s.[File_Size_Bytes]),
			            NULLIF(s.[File_Size_Bytes], t.[File_Size_Bytes])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[File_Info_Last_Modified], s.[File_Info_Last_Modified]),
			            NULLIF(s.[File_Info_Last_Modified], t.[File_Info_Last_Modified])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Interval_to_Next_DS], s.[Interval_to_Next_DS]),
			            NULLIF(s.[Interval_to_Next_DS], t.[Interval_to_Next_DS])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DeconTools_Job_for_QC], s.[DeconTools_Job_for_QC]),
			            NULLIF(s.[DeconTools_Job_for_QC], t.[DeconTools_Job_for_QC])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Capture_Subfolder], s.[Capture_Subfolder]),
			            NULLIF(s.[Capture_Subfolder], t.[Capture_Subfolder])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Dataset_Num] = s.[Dataset_Num],
			   [DS_Oper_PRN] = s.[DS_Oper_PRN],
			    [DS_comment] = s.[DS_comment],
			    [DS_created] = s.[DS_created],
			    [DS_instrument_name_ID] = s.[DS_instrument_name_ID],
			    [DS_LC_column_ID] = s.[DS_LC_column_ID],
			    [DS_type_ID] = s.[DS_type_ID],
			    [DS_wellplate_num] = s.[DS_wellplate_num],
			    [DS_well_num] = s.[DS_well_num],
			    [DS_sec_sep] = s.[DS_sec_sep],
			    [DS_state_ID] = s.[DS_state_ID],
			    [DS_Last_Affected] = s.[DS_Last_Affected],
			    [DS_folder_name] = s.[DS_folder_name],
			    [DS_storage_path_ID] = s.[DS_storage_path_ID],
			    [Exp_ID] = s.[Exp_ID],
			    [DS_internal_standard_ID] = s.[DS_internal_standard_ID],
			    [DS_rating] = s.[DS_rating],
			    [DS_Comp_State] = s.[DS_Comp_State],
			    [DS_Compress_Date] = s.[DS_Compress_Date],
			    [DS_PrepServerName] = s.[DS_PrepServerName],
			    [Acq_Time_Start] = s.[Acq_Time_Start],
			    [Acq_Time_End] = s.[Acq_Time_End],
			    [Scan_Count] = s.[Scan_Count],
			    [File_Size_Bytes] = s.[File_Size_Bytes],
			    [File_Info_Last_Modified] = s.[File_Info_Last_Modified],
			    [Interval_to_Next_DS] = s.[Interval_to_Next_DS],
			    [DateSortKey] = s.[DateSortKey],
			    [DeconTools_Job_for_QC] = s.[DeconTools_Job_for_QC],
			    [Capture_Subfolder] = s.[Capture_Subfolder]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Dataset_Num], [DS_Oper_PRN], [DS_comment], [DS_created], [DS_instrument_name_ID], [DS_LC_column_ID], [DS_type_ID], [DS_wellplate_num], [DS_well_num], [DS_sec_sep], [DS_state_ID], [DS_Last_Affected], [DS_folder_name], [DS_storage_path_ID], [Exp_ID], [Dataset_ID], [DS_internal_standard_ID], [DS_rating], [DS_Comp_State], [DS_Compress_Date], [DS_PrepServerName], [Acq_Time_Start], [Acq_Time_End], [Scan_Count], [File_Size_Bytes], [File_Info_Last_Modified], [Interval_to_Next_DS], [DateSortKey], [DeconTools_Job_for_QC], [Capture_Subfolder])
			    VALUES(s.[Dataset_Num], s.[DS_Oper_PRN], s.[DS_comment], s.[DS_created], s.[DS_instrument_name_ID], s.[DS_LC_column_ID], s.[DS_type_ID], s.[DS_wellplate_num], s.[DS_well_num], s.[DS_sec_sep], s.[DS_state_ID], s.[DS_Last_Affected], s.[DS_folder_name], s.[DS_storage_path_ID], s.[Exp_ID], s.[Dataset_ID], s.[DS_internal_standard_ID], s.[DS_rating], s.[DS_Comp_State], s.[DS_Compress_Date], s.[DS_PrepServerName], s.[Acq_Time_Start], s.[Acq_Time_End], s.[Scan_Count], s.[File_Size_Bytes], s.[File_Info_Last_Modified], s.[Interval_to_Next_DS], s.[DateSortKey], s.[DeconTools_Job_for_QC], s.[Capture_Subfolder])
			-- Delete using DeleteOldDataExperimentsJobsAndLogs
			-- WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			 Cast(Inserted.[Dataset_ID] as varchar(12)),
			       Cast(Deleted.[Dataset_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Dataset] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Dataset_Info'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Dataset_Info] AS t
			USING (SELECT DISource.* 
			       FROM [DMS5].[dbo].[T_Dataset_Info] DISource INNER JOIN 
			            [T_Dataset] DS ON DISource.Dataset_ID = DS.Dataset_ID) as s
			ON ( t.[Dataset_ID] = s.[Dataset_ID])
			WHEN MATCHED AND (
			    t.[ScanCountMS] <> s.[ScanCountMS] OR
			    t.[ScanCountMSn] <> s.[ScanCountMSn] OR
			    t.[Last_Affected] <> s.[Last_Affected] OR
			    ISNULL( NULLIF(t.[TIC_Max_MS], s.[TIC_Max_MS]),
			            NULLIF(s.[TIC_Max_MS], t.[TIC_Max_MS])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[TIC_Max_MSn], s.[TIC_Max_MSn]),
			            NULLIF(s.[TIC_Max_MSn], t.[TIC_Max_MSn])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[BPI_Max_MS], s.[BPI_Max_MS]),
			            NULLIF(s.[BPI_Max_MS], t.[BPI_Max_MS])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[BPI_Max_MSn], s.[BPI_Max_MSn]),
			            NULLIF(s.[BPI_Max_MSn], t.[BPI_Max_MSn])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[TIC_Median_MS], s.[TIC_Median_MS]),
			            NULLIF(s.[TIC_Median_MS], t.[TIC_Median_MS])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[TIC_Median_MSn], s.[TIC_Median_MSn]),
			            NULLIF(s.[TIC_Median_MSn], t.[TIC_Median_MSn])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[BPI_Median_MS], s.[BPI_Median_MS]),
			            NULLIF(s.[BPI_Median_MS], t.[BPI_Median_MS])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[BPI_Median_MSn], s.[BPI_Median_MSn]),
			            NULLIF(s.[BPI_Median_MSn], t.[BPI_Median_MSn])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Elution_Time_Max], s.[Elution_Time_Max]),
			            NULLIF(s.[Elution_Time_Max], t.[Elution_Time_Max])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Scan_Types], s.[Scan_Types]),
			            NULLIF(s.[Scan_Types], t.[Scan_Types])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[ProfileScanCount_MS], s.[ProfileScanCount_MS]),
			            NULLIF(s.[ProfileScanCount_MS], t.[ProfileScanCount_MS])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[ProfileScanCount_MSn], s.[ProfileScanCount_MSn]),
			            NULLIF(s.[ProfileScanCount_MSn], t.[ProfileScanCount_MSn])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CentroidScanCount_MS], s.[CentroidScanCount_MS]),
			            NULLIF(s.[CentroidScanCount_MS], t.[CentroidScanCount_MS])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[CentroidScanCount_MSn], s.[CentroidScanCount_MSn]),
			            NULLIF(s.[CentroidScanCount_MSn], t.[CentroidScanCount_MSn])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [ScanCountMS] = s.[ScanCountMS],
			    [ScanCountMSn] = s.[ScanCountMSn],
			    [TIC_Max_MS] = s.[TIC_Max_MS],
			    [TIC_Max_MSn] = s.[TIC_Max_MSn],
			    [BPI_Max_MS] = s.[BPI_Max_MS],
			    [BPI_Max_MSn] = s.[BPI_Max_MSn],
			    [TIC_Median_MS] = s.[TIC_Median_MS],
			    [TIC_Median_MSn] = s.[TIC_Median_MSn],
			    [BPI_Median_MS] = s.[BPI_Median_MS],
			    [BPI_Median_MSn] = s.[BPI_Median_MSn],
			    [Elution_Time_Max] = s.[Elution_Time_Max],
			    [Scan_Types] = s.[Scan_Types],
			    [Last_Affected] = s.[Last_Affected],
			    [ProfileScanCount_MS] = s.[ProfileScanCount_MS],
			    [ProfileScanCount_MSn] = s.[ProfileScanCount_MSn],
			 [CentroidScanCount_MS] = s.[CentroidScanCount_MS],
			    [CentroidScanCount_MSn] = s.[CentroidScanCount_MSn]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Dataset_ID], [ScanCountMS], [ScanCountMSn], [TIC_Max_MS], [TIC_Max_MSn], [BPI_Max_MS], [BPI_Max_MSn], [TIC_Median_MS], [TIC_Median_MSn], [BPI_Median_MS], [BPI_Median_MSn], [Elution_Time_Max], [Scan_Types], [Last_Affected], [ProfileScanCount_MS], [ProfileScanCount_MSn], [CentroidScanCount_MS], [CentroidScanCount_MSn])
			    VALUES(s.[Dataset_ID], s.[ScanCountMS], s.[ScanCountMSn], s.[TIC_Max_MS], s.[TIC_Max_MSn], s.[BPI_Max_MS], s.[BPI_Max_MSn], s.[TIC_Median_MS], s.[TIC_Median_MSn], s.[BPI_Median_MS], s.[BPI_Median_MSn], s.[Elution_Time_Max], s.[Scan_Types], s.[Last_Affected], s.[ProfileScanCount_MS], s.[ProfileScanCount_MSn], s.[CentroidScanCount_MS], s.[CentroidScanCount_MSn])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[Dataset_ID] as varchar(12)),
			       Cast(Deleted.[Dataset_ID] as varchar(12))
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

		Set @tableName = 'T_Dataset_QC'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
 
			MERGE [dbo].[T_Dataset_QC] AS t
			USING (SELECT QCSource.* 
			       FROM [DMS5].[dbo].[T_Dataset_QC] QCSource INNER JOIN 
				        [T_Dataset] DS ON QCSource.Dataset_ID = DS.Dataset_ID) as s
			ON ( t.[Dataset_ID] = s.[Dataset_ID])
			WHEN MATCHED AND (
			    ISNULL( NULLIF(t.[SMAQC_Job], s.[SMAQC_Job]),
			            NULLIF(s.[SMAQC_Job], t.[SMAQC_Job])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[PSM_Source_Job], s.[PSM_Source_Job]),
			            NULLIF(s.[PSM_Source_Job], t.[PSM_Source_Job])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Last_Affected], s.[Last_Affected]),
			            NULLIF(s.[Last_Affected], t.[Last_Affected])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Quameter_Job], s.[Quameter_Job]),
			            NULLIF(s.[Quameter_Job], t.[Quameter_Job])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Quameter_Last_Affected], s.[Quameter_Last_Affected]),
			            NULLIF(s.[Quameter_Last_Affected], t.[Quameter_Last_Affected])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[QCDM_Last_Affected], s.[QCDM_Last_Affected]),
			            NULLIF(s.[QCDM_Last_Affected], t.[QCDM_Last_Affected])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [SMAQC_Job] = s.[SMAQC_Job],
			    [PSM_Source_Job] = s.[PSM_Source_Job],
			    [Last_Affected] = s.[Last_Affected],
			    [C_1A] = s.[C_1A],
			    [C_1B] = s.[C_1B],
			    [C_2A] = s.[C_2A],
			    [C_2B] = s.[C_2B],
			    [C_3A] = s.[C_3A],
			    [C_3B] = s.[C_3B],
			    [C_4A] = s.[C_4A],
			    [C_4B] = s.[C_4B],
			    [C_4C] = s.[C_4C],
			    [DS_1A] = s.[DS_1A],
			    [DS_1B] = s.[DS_1B],
			    [DS_2A] = s.[DS_2A],
			    [DS_2B] = s.[DS_2B],
			    [DS_3A] = s.[DS_3A],
			    [DS_3B] = s.[DS_3B],
			    [IS_1A] = s.[IS_1A],
			    [IS_1B] = s.[IS_1B],
			    [IS_2] = s.[IS_2],
			    [IS_3A] = s.[IS_3A],
			    [IS_3B] = s.[IS_3B],
			    [IS_3C] = s.[IS_3C],
			    [MS1_1] = s.[MS1_1],
			    [MS1_2A] = s.[MS1_2A],
			    [MS1_2B] = s.[MS1_2B],
			    [MS1_3A] = s.[MS1_3A],
			    [MS1_3B] = s.[MS1_3B],
			    [MS1_5A] = s.[MS1_5A],
			    [MS1_5B] = s.[MS1_5B],
			    [MS1_5C] = s.[MS1_5C],
			    [MS1_5D] = s.[MS1_5D],
			    [MS2_1] = s.[MS2_1],
			    [MS2_2] = s.[MS2_2],
			    [MS2_3] = s.[MS2_3],
			    [MS2_4A] = s.[MS2_4A],
			    [MS2_4B] = s.[MS2_4B],
			    [MS2_4C] = s.[MS2_4C],
			    [MS2_4D] = s.[MS2_4D],
			    [P_1A] = s.[P_1A],
			    [P_1B] = s.[P_1B],
			    [P_2A] = s.[P_2A],
			    [P_2B] = s.[P_2B],
			    [P_2C] = s.[P_2C],
			    [P_3] = s.[P_3],
			    [Quameter_Job] = s.[Quameter_Job],
			    [Quameter_Last_Affected] = s.[Quameter_Last_Affected],
			    [XIC_WideFrac] = s.[XIC_WideFrac],
			    [XIC_FWHM_Q1] = s.[XIC_FWHM_Q1],
			    [XIC_FWHM_Q2] = s.[XIC_FWHM_Q2],
			    [XIC_FWHM_Q3] = s.[XIC_FWHM_Q3],
			    [XIC_Height_Q2] = s.[XIC_Height_Q2],
			    [XIC_Height_Q3] = s.[XIC_Height_Q3],
			    [XIC_Height_Q4] = s.[XIC_Height_Q4],
			    [RT_Duration] = s.[RT_Duration],
			    [RT_TIC_Q1] = s.[RT_TIC_Q1],
			    [RT_TIC_Q2] = s.[RT_TIC_Q2],
			    [RT_TIC_Q3] = s.[RT_TIC_Q3],
			    [RT_TIC_Q4] = s.[RT_TIC_Q4],
			    [RT_MS_Q1] = s.[RT_MS_Q1],
			    [RT_MS_Q2] = s.[RT_MS_Q2],
			    [RT_MS_Q3] = s.[RT_MS_Q3],
			    [RT_MS_Q4] = s.[RT_MS_Q4],
			    [RT_MSMS_Q1] = s.[RT_MSMS_Q1],
			    [RT_MSMS_Q2] = s.[RT_MSMS_Q2],
			    [RT_MSMS_Q3] = s.[RT_MSMS_Q3],
			    [RT_MSMS_Q4] = s.[RT_MSMS_Q4],
			    [MS1_TIC_Change_Q2] = s.[MS1_TIC_Change_Q2],
			    [MS1_TIC_Change_Q3] = s.[MS1_TIC_Change_Q3],
			    [MS1_TIC_Change_Q4] = s.[MS1_TIC_Change_Q4],
			    [MS1_TIC_Q2] = s.[MS1_TIC_Q2],
			    [MS1_TIC_Q3] = s.[MS1_TIC_Q3],
			    [MS1_TIC_Q4] = s.[MS1_TIC_Q4],
			    [MS1_Count] = s.[MS1_Count],
			    [MS1_Freq_Max] = s.[MS1_Freq_Max],
			    [MS1_Density_Q1] = s.[MS1_Density_Q1],
			    [MS1_Density_Q2] = s.[MS1_Density_Q2],
			    [MS1_Density_Q3] = s.[MS1_Density_Q3],
			    [MS2_Count] = s.[MS2_Count],
			    [MS2_Freq_Max] = s.[MS2_Freq_Max],
			    [MS2_Density_Q1] = s.[MS2_Density_Q1],
			    [MS2_Density_Q2] = s.[MS2_Density_Q2],
			    [MS2_Density_Q3] = s.[MS2_Density_Q3],
			    [MS2_PrecZ_1] = s.[MS2_PrecZ_1],
			    [MS2_PrecZ_2] = s.[MS2_PrecZ_2],
			    [MS2_PrecZ_3] = s.[MS2_PrecZ_3],
			    [MS2_PrecZ_4] = s.[MS2_PrecZ_4],
			    [MS2_PrecZ_5] = s.[MS2_PrecZ_5],
			    [MS2_PrecZ_more] = s.[MS2_PrecZ_more],
			    [MS2_PrecZ_likely_1] = s.[MS2_PrecZ_likely_1],
			    [MS2_PrecZ_likely_multi] = s.[MS2_PrecZ_likely_multi],
			    [QCDM_Last_Affected] = s.[QCDM_Last_Affected],
			    [QCDM] = s.[QCDM],
			    [MassErrorPPM] = s.[MassErrorPPM],
			    [MassErrorPPM_Refined] = s.[MassErrorPPM_Refined],
			    [MassErrorPPM_VIPER] = s.[MassErrorPPM_VIPER],
			    [AMTs_10pct_FDR] = s.[AMTs_10pct_FDR],
			    [Phos_2A] = s.[Phos_2A],
			    [Phos_2C] = s.[Phos_2C],
			    [Keratin_2A] = s.[Keratin_2A],
			    [Keratin_2C] = s.[Keratin_2C],
			    [P_4A] = s.[P_4A],
			    [P_4B] = s.[P_4B]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Dataset_ID], [SMAQC_Job], [PSM_Source_Job], [Last_Affected], [C_1A], [C_1B], [C_2A], [C_2B], [C_3A], [C_3B], [C_4A], [C_4B], [C_4C], [DS_1A], [DS_1B], [DS_2A], [DS_2B], [DS_3A], [DS_3B], [IS_1A], [IS_1B], [IS_2], [IS_3A], [IS_3B], [IS_3C], [MS1_1], [MS1_2A], [MS1_2B], [MS1_3A], [MS1_3B], [MS1_5A], [MS1_5B], [MS1_5C], [MS1_5D], [MS2_1], [MS2_2], [MS2_3], [MS2_4A], [MS2_4B], [MS2_4C], [MS2_4D], [P_1A], [P_1B], [P_2A], [P_2B], [P_2C], [P_3], [Quameter_Job], [Quameter_Last_Affected], 
			           [XIC_WideFrac], [XIC_FWHM_Q1], [XIC_FWHM_Q2], [XIC_FWHM_Q3], [XIC_Height_Q2], [XIC_Height_Q3], [XIC_Height_Q4], [RT_Duration], [RT_TIC_Q1], [RT_TIC_Q2], [RT_TIC_Q3], [RT_TIC_Q4], [RT_MS_Q1], [RT_MS_Q2], [RT_MS_Q3], [RT_MS_Q4], [RT_MSMS_Q1], [RT_MSMS_Q2], [RT_MSMS_Q3], [RT_MSMS_Q4], [MS1_TIC_Change_Q2], [MS1_TIC_Change_Q3], [MS1_TIC_Change_Q4], [MS1_TIC_Q2], [MS1_TIC_Q3], [MS1_TIC_Q4], [MS1_Count], [MS1_Freq_Max], [MS1_Density_Q1], [MS1_Density_Q2], [MS1_Density_Q3], 
			           [MS2_Count], [MS2_Freq_Max], [MS2_Density_Q1], [MS2_Density_Q2], [MS2_Density_Q3], [MS2_PrecZ_1], [MS2_PrecZ_2], [MS2_PrecZ_3], [MS2_PrecZ_4], [MS2_PrecZ_5], [MS2_PrecZ_more], [MS2_PrecZ_likely_1], [MS2_PrecZ_likely_multi], [QCDM_Last_Affected], [QCDM], [MassErrorPPM], [MassErrorPPM_Refined], [MassErrorPPM_VIPER], [AMTs_10pct_FDR], [Phos_2A], [Phos_2C], [Keratin_2A], [Keratin_2C], [P_4A], [P_4B])
			    VALUES(s.[Dataset_ID], s.[SMAQC_Job], s.[PSM_Source_Job], s.[Last_Affected], s.[C_1A], s.[C_1B], s.[C_2A], s.[C_2B], s.[C_3A], s.[C_3B], s.[C_4A], s.[C_4B], s.[C_4C], s.[DS_1A], s.[DS_1B], s.[DS_2A], s.[DS_2B], s.[DS_3A], s.[DS_3B], s.[IS_1A], s.[IS_1B], s.[IS_2], s.[IS_3A], s.[IS_3B], s.[IS_3C], s.[MS1_1], s.[MS1_2A], s.[MS1_2B], s.[MS1_3A], s.[MS1_3B], s.[MS1_5A], s.[MS1_5B], s.[MS1_5C], s.[MS1_5D], s.[MS2_1], s.[MS2_2], s.[MS2_3], s.[MS2_4A], s.[MS2_4B], s.[MS2_4C], s.[MS2_4D], s.[P_1A], s.[P_1B], s.[P_2A], s.[P_2B], s.[P_2C], s.[P_3], s.[Quameter_Job], s.[Quameter_Last_Affected], 
			           s.[XIC_WideFrac], s.[XIC_FWHM_Q1], s.[XIC_FWHM_Q2], s.[XIC_FWHM_Q3], s.[XIC_Height_Q2], s.[XIC_Height_Q3], s.[XIC_Height_Q4], s.[RT_Duration], s.[RT_TIC_Q1], s.[RT_TIC_Q2], s.[RT_TIC_Q3], s.[RT_TIC_Q4], s.[RT_MS_Q1], s.[RT_MS_Q2], s.[RT_MS_Q3], s.[RT_MS_Q4], s.[RT_MSMS_Q1], s.[RT_MSMS_Q2], s.[RT_MSMS_Q3], s.[RT_MSMS_Q4], s.[MS1_TIC_Change_Q2], s.[MS1_TIC_Change_Q3], s.[MS1_TIC_Change_Q4], s.[MS1_TIC_Q2], s.[MS1_TIC_Q3], s.[MS1_TIC_Q4], s.[MS1_Count], s.[MS1_Freq_Max], s.[MS1_Density_Q1], s.[MS1_Density_Q2], s.[MS1_Density_Q3], 
			           s.[MS2_Count], s.[MS2_Freq_Max], s.[MS2_Density_Q1], s.[MS2_Density_Q2], s.[MS2_Density_Q3], s.[MS2_PrecZ_1], s.[MS2_PrecZ_2], s.[MS2_PrecZ_3], s.[MS2_PrecZ_4], s.[MS2_PrecZ_5], s.[MS2_PrecZ_more], s.[MS2_PrecZ_likely_1], s.[MS2_PrecZ_likely_multi], s.[QCDM_Last_Affected], s.[QCDM], s.[MassErrorPPM], s.[MassErrorPPM_Refined], s.[MassErrorPPM_VIPER], s.[AMTs_10pct_FDR], s.[Phos_2A], s.[Phos_2C], s.[Keratin_2A], s.[Keratin_2C], s.[P_4A], s.[P_4B])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[Dataset_ID] as varchar(12)),
			       Cast(Deleted.[Dataset_ID] as varchar(12))
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

		Set @tableName = 'T_Archive_Path'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Archive_Path] ON;
			 
			MERGE [dbo].[T_Archive_Path] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Archive_Path]) as s
			ON ( t.[AP_path_ID] = s.[AP_path_ID])
			WHEN MATCHED AND (
			    t.[AP_instrument_name_ID] <> s.[AP_instrument_name_ID] OR
			    t.[AP_archive_path] <> s.[AP_archive_path] OR
			    t.[AP_Function] <> s.[AP_Function] OR
			    ISNULL( NULLIF(t.[Note], s.[Note]),
			            NULLIF(s.[Note], t.[Note])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AP_Server_Name], s.[AP_Server_Name]),
			            NULLIF(s.[AP_Server_Name], t.[AP_Server_Name])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AP_network_share_path], s.[AP_network_share_path]),
			            NULLIF(s.[AP_network_share_path], t.[AP_network_share_path])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AP_archive_URL], s.[AP_archive_URL]),
			            NULLIF(s.[AP_archive_URL], t.[AP_archive_URL])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AP_created], s.[AP_created]),
			            NULLIF(s.[AP_created], t.[AP_created])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [AP_instrument_name_ID] = s.[AP_instrument_name_ID],
			    [AP_archive_path] = s.[AP_archive_path],
			    [Note] = s.[Note],
			    [AP_Function] = s.[AP_Function],
			    [AP_Server_Name] = s.[AP_Server_Name],
			    [AP_network_share_path] = s.[AP_network_share_path],
			    [AP_archive_URL] = s.[AP_archive_URL],
			    [AP_created] = s.[AP_created]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([AP_instrument_name_ID], [AP_archive_path], [AP_path_ID], [Note], [AP_Function], [AP_Server_Name], [AP_network_share_path], [AP_archive_URL], [AP_created])
			    VALUES(s.[AP_instrument_name_ID], s.[AP_archive_path], s.[AP_path_ID], s.[Note], s.[AP_Function], s.[AP_Server_Name], s.[AP_network_share_path], s.[AP_archive_URL], s.[AP_created])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[AP_path_ID] as varchar(12)),
			       Cast(Deleted.[AP_path_ID] as varchar(12))
			 INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Archive_Path] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Dataset_Archive'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
 
			MERGE [dbo].[T_Dataset_Archive] AS t
			USING (SELECT DSArchSource.* 
			       FROM [DMS5].[dbo].[T_Dataset_Archive] DSArchSource INNER JOIN 
				        [T_Dataset] DS ON DSArchSource.AS_Dataset_ID = DS.Dataset_ID) as s
			ON ( t.[AS_Dataset_ID] = s.[AS_Dataset_ID])
			WHEN MATCHED AND (
			    t.[AS_state_ID] <> s.[AS_state_ID] OR
			    t.[AS_storage_path_ID] <> s.[AS_storage_path_ID] OR
			    t.[AS_instrument_data_purged] <> s.[AS_instrument_data_purged] OR
			    t.[AS_StageMD5_Required] <> s.[AS_StageMD5_Required] OR
			    t.[QC_Data_Purged] <> s.[QC_Data_Purged] OR
			    t.[Purge_Policy] <> s.[Purge_Policy] OR
			    t.[Purge_Priority] <> s.[Purge_Priority] OR
			    t.[MyEMSLState] <> s.[MyEMSLState] OR
			    ISNULL( NULLIF(t.[AS_state_Last_Affected], s.[AS_state_Last_Affected]),
			            NULLIF(s.[AS_state_Last_Affected], t.[AS_state_Last_Affected])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_datetime], s.[AS_datetime]),
			            NULLIF(s.[AS_datetime], t.[AS_datetime])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_last_update], s.[AS_last_update]),
			            NULLIF(s.[AS_last_update], t.[AS_last_update])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_last_verify], s.[AS_last_verify]),
			            NULLIF(s.[AS_last_verify], t.[AS_last_verify])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_update_state_ID], s.[AS_update_state_ID]),
			            NULLIF(s.[AS_update_state_ID], t.[AS_update_state_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_update_state_Last_Affected], s.[AS_update_state_Last_Affected]),
			            NULLIF(s.[AS_update_state_Last_Affected], t.[AS_update_state_Last_Affected])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_purge_holdoff_date], s.[AS_purge_holdoff_date]),
			            NULLIF(s.[AS_purge_holdoff_date], t.[AS_purge_holdoff_date])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_archive_processor], s.[AS_archive_processor]),
			            NULLIF(s.[AS_archive_processor], t.[AS_archive_processor])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_update_processor], s.[AS_update_processor]),
			            NULLIF(s.[AS_update_processor], t.[AS_update_processor])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_verification_processor], s.[AS_verification_processor]),
			            NULLIF(s.[AS_verification_processor], t.[AS_verification_processor])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AS_Last_Successful_Archive], s.[AS_Last_Successful_Archive]),
			            NULLIF(s.[AS_Last_Successful_Archive], t.[AS_Last_Successful_Archive])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [AS_state_ID] = s.[AS_state_ID],
			    [AS_state_Last_Affected] = s.[AS_state_Last_Affected],
			    [AS_storage_path_ID] = s.[AS_storage_path_ID],
			    [AS_datetime] = s.[AS_datetime],
			    [AS_last_update] = s.[AS_last_update],
			    [AS_last_verify] = s.[AS_last_verify],
			    [AS_update_state_ID] = s.[AS_update_state_ID],
			    [AS_update_state_Last_Affected] = s.[AS_update_state_Last_Affected],
			    [AS_purge_holdoff_date] = s.[AS_purge_holdoff_date],
			    [AS_archive_processor] = s.[AS_archive_processor],
			    [AS_update_processor] = s.[AS_update_processor],
			    [AS_verification_processor] = s.[AS_verification_processor],
			    [AS_instrument_data_purged] = s.[AS_instrument_data_purged],
			    [AS_Last_Successful_Archive] = s.[AS_Last_Successful_Archive],
			    [AS_StageMD5_Required] = s.[AS_StageMD5_Required],
			    [QC_Data_Purged] = s.[QC_Data_Purged],
			    [Purge_Policy] = s.[Purge_Policy],
			    [Purge_Priority] = s.[Purge_Priority],
			    [MyEMSLState] = s.[MyEMSLState]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([AS_Dataset_ID], [AS_state_ID], [AS_state_Last_Affected], [AS_storage_path_ID], [AS_datetime], [AS_last_update], [AS_last_verify], [AS_update_state_ID], [AS_update_state_Last_Affected], [AS_purge_holdoff_date], [AS_archive_processor], [AS_update_processor], [AS_verification_processor], [AS_instrument_data_purged], [AS_Last_Successful_Archive], [AS_StageMD5_Required], [QC_Data_Purged], [Purge_Policy], [Purge_Priority], [MyEMSLState])
			    VALUES(s.[AS_Dataset_ID], s.[AS_state_ID], s.[AS_state_Last_Affected], s.[AS_storage_path_ID], s.[AS_datetime], s.[AS_last_update], s.[AS_last_verify], s.[AS_update_state_ID], s.[AS_update_state_Last_Affected], s.[AS_purge_holdoff_date], s.[AS_archive_processor], s.[AS_update_processor], s.[AS_verification_processor], s.[AS_instrument_data_purged], s.[AS_Last_Successful_Archive], s.[AS_StageMD5_Required], s.[QC_Data_Purged], s.[Purge_Policy], s.[Purge_Priority], s.[MyEMSLState])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[AS_Dataset_ID] as varchar(12)),
			       Cast(Deleted.[AS_Dataset_ID] as varchar(12))
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

		Set @tableName = 'T_Prep_LC_Run_Dataset'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Prep_LC_Run_Dataset] AS t
			USING (SELECT PrepLCSource.* 
			       FROM [DMS5].[dbo].[T_Prep_LC_Run_Dataset] PrepLCSource INNER JOIN 
				        [T_Dataset] DS ON PrepLCSource.Dataset_ID = DS.Dataset_ID) as s
			ON ( t.[Dataset_ID] = s.[Dataset_ID] AND t.[Prep_LC_Run_ID] = s.[Prep_LC_Run_ID])
			-- Note: all of the columns in table T_Prep_LC_Run_Dataset are primary keys or identity columns; there are no updatable columns
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Prep_LC_Run_ID], [Dataset_ID])
				VALUES(s.[Prep_LC_Run_ID], s.[Dataset_ID])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
				Cast(Inserted.[Dataset_ID] as varchar(12)) + ', ' + Cast(Inserted.[Prep_LC_Run_ID] as varchar(12)),
				Cast(Deleted.[Dataset_ID] as varchar(12)) + ', ' + Cast(Deleted.[Prep_LC_Run_ID] as varchar(12))
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

		Set @tableName = 'T_Requested_Run_Batches'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Requested_Run_Batches] ON;
			 
			MERGE [dbo].[T_Requested_Run_Batches] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Requested_Run_Batches]) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[Batch] <> s.[Batch] OR
			    t.[Created] <> s.[Created] OR
			    t.[Locked] <> s.[Locked] OR
			    t.[Requested_Instrument] <> s.[Requested_Instrument] OR
			    ISNULL( NULLIF(t.[Description], s.[Description]),
			            NULLIF(s.[Description], t.[Description])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Owner], s.[Owner]),
			            NULLIF(s.[Owner], t.[Owner])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Last_Ordered], s.[Last_Ordered]),
			            NULLIF(s.[Last_Ordered], t.[Last_Ordered])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Requested_Batch_Priority], s.[Requested_Batch_Priority]),
			            NULLIF(s.[Requested_Batch_Priority], t.[Requested_Batch_Priority])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Actual_Batch_Priority], s.[Actual_Batch_Priority]),
			            NULLIF(s.[Actual_Batch_Priority], t.[Actual_Batch_Priority])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Requested_Completion_Date], s.[Requested_Completion_Date]),
			            NULLIF(s.[Requested_Completion_Date], t.[Requested_Completion_Date])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Justification_for_High_Priority], s.[Justification_for_High_Priority]),
			            NULLIF(s.[Justification_for_High_Priority], t.[Justification_for_High_Priority])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Comment], s.[Comment]),
			            NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Batch] = s.[Batch],
			    [Description] = s.[Description],
			    [Owner] = s.[Owner],
			    [Created] = s.[Created],
			    [Locked] = s.[Locked],
			    [Last_Ordered] = s.[Last_Ordered],
			    [Requested_Batch_Priority] = s.[Requested_Batch_Priority],
			    [Actual_Batch_Priority] = s.[Actual_Batch_Priority],
			    [Requested_Completion_Date] = s.[Requested_Completion_Date],
			    [Justification_for_High_Priority] = s.[Justification_for_High_Priority],
			    [Comment] = s.[Comment],
			    [Requested_Instrument] = s.[Requested_Instrument]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([ID], [Batch], [Description], [Owner], [Created], [Locked], [Last_Ordered], [Requested_Batch_Priority], [Actual_Batch_Priority], [Requested_Completion_Date], [Justification_for_High_Priority], [Comment], [Requested_Instrument])
			    VALUES(s.[ID], s.[Batch], s.[Description], s.[Owner], s.[Created], s.[Locked], s.[Last_Ordered], s.[Requested_Batch_Priority], s.[Actual_Batch_Priority], s.[Requested_Completion_Date], s.[Justification_for_High_Priority], s.[Comment], s.[Requested_Instrument])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Requested_Run_Batches] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Requested_Run'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Requested_Run] ON;
			 
			MERGE [dbo].[T_Requested_Run] AS t
			USING (SELECT RRSource.* 
			       FROM [DMS5].[dbo].[T_Requested_Run] RRSource INNER JOIN
			            T_Experiments E ON RRSource.Exp_ID = E.Exp_ID
			       WHERE RRSource.RDS_created > @importThreshold AND RRSource.DatasetID IS Null
			       UNION
			       SELECT RRSource.* 
			       FROM [DMS5].[dbo].[T_Requested_Run] RRSource INNER JOIN
			            T_Experiments E ON RRSource.Exp_ID = E.Exp_ID INNER Join 
						[T_Dataset] DS ON RRSource.DatasetID = DS.Dataset_ID
				   WHERE NOT RRSource.DatasetID IS Null
			       ) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[RDS_Name] <> s.[RDS_Name] OR
			    t.[RDS_Oper_PRN] <> s.[RDS_Oper_PRN] OR
			    t.[RDS_created] <> s.[RDS_created] OR
			    t.[Exp_ID] <> s.[Exp_ID] OR
			    t.[RDS_BatchID] <> s.[RDS_BatchID] OR
			    t.[RDS_EUS_UsageType] <> s.[RDS_EUS_UsageType] OR
			    t.[RDS_Cart_ID] <> s.[RDS_Cart_ID] OR
			    t.[RDS_Status] <> s.[RDS_Status] OR
			    ISNULL( NULLIF(t.[RDS_comment], s.[RDS_comment]),
			            NULLIF(s.[RDS_comment], t.[RDS_comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_instrument_name], s.[RDS_instrument_name]),
			            NULLIF(s.[RDS_instrument_name], t.[RDS_instrument_name])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_type_ID], s.[RDS_type_ID]),
			            NULLIF(s.[RDS_type_ID], t.[RDS_type_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_instrument_setting], s.[RDS_instrument_setting]),
			            NULLIF(s.[RDS_instrument_setting], t.[RDS_instrument_setting])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_special_instructions], s.[RDS_special_instructions]),
			            NULLIF(s.[RDS_special_instructions], t.[RDS_special_instructions])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Well_Plate_Num], s.[RDS_Well_Plate_Num]),
			            NULLIF(s.[RDS_Well_Plate_Num], t.[RDS_Well_Plate_Num])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Well_Num], s.[RDS_Well_Num]),
			            NULLIF(s.[RDS_Well_Num], t.[RDS_Well_Num])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_priority], s.[RDS_priority]),
			            NULLIF(s.[RDS_priority], t.[RDS_priority])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_note], s.[RDS_note]),
			            NULLIF(s.[RDS_note], t.[RDS_note])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Run_Start], s.[RDS_Run_Start]),
			            NULLIF(s.[RDS_Run_Start], t.[RDS_Run_Start])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Run_Finish], s.[RDS_Run_Finish]),
			            NULLIF(s.[RDS_Run_Finish], t.[RDS_Run_Finish])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_internal_standard], s.[RDS_internal_standard]),
			            NULLIF(s.[RDS_internal_standard], t.[RDS_internal_standard])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_WorkPackage], s.[RDS_WorkPackage]),
			        NULLIF(s.[RDS_WorkPackage], t.[RDS_WorkPackage])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Blocking_Factor], s.[RDS_Blocking_Factor]),
			            NULLIF(s.[RDS_Blocking_Factor], t.[RDS_Blocking_Factor])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Block], s.[RDS_Block]),
			            NULLIF(s.[RDS_Block], t.[RDS_Block])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Run_Order], s.[RDS_Run_Order]),
			            NULLIF(s.[RDS_Run_Order], t.[RDS_Run_Order])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_EUS_Proposal_ID], s.[RDS_EUS_Proposal_ID]),
			            NULLIF(s.[RDS_EUS_Proposal_ID], t.[RDS_EUS_Proposal_ID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Cart_Col], s.[RDS_Cart_Col]),
			            NULLIF(s.[RDS_Cart_Col], t.[RDS_Cart_Col])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Sec_Sep], s.[RDS_Sec_Sep]),
			        NULLIF(s.[RDS_Sec_Sep], t.[RDS_Sec_Sep])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_MRM_Attachment], s.[RDS_MRM_Attachment]),
			            NULLIF(s.[RDS_MRM_Attachment], t.[RDS_MRM_Attachment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[DatasetID], s.[DatasetID]),
			            NULLIF(s.[DatasetID], t.[DatasetID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_Origin], s.[RDS_Origin]),
			            NULLIF(s.[RDS_Origin], t.[RDS_Origin])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[RDS_NameCode], s.[RDS_NameCode]),
			            NULLIF(s.[RDS_NameCode], t.[RDS_NameCode])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Entered], s.[Entered]),
			            NULLIF(s.[Entered], t.[Entered])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Vialing_Conc], s.[Vialing_Conc]),
			            NULLIF(s.[Vialing_Conc], t.[Vialing_Conc])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[Vialing_Vol], s.[Vialing_Vol]),
			            NULLIF(s.[Vialing_Vol], t.[Vialing_Vol])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [RDS_Name] = s.[RDS_Name],
			    [RDS_Oper_PRN] = s.[RDS_Oper_PRN],
			    [RDS_comment] = s.[RDS_comment],
			    [RDS_created] = s.[RDS_created],
			    [RDS_instrument_name] = s.[RDS_instrument_name],
			    [RDS_type_ID] = s.[RDS_type_ID],
			    [RDS_instrument_setting] = s.[RDS_instrument_setting],
			    [RDS_special_instructions] = s.[RDS_special_instructions],
			    [RDS_Well_Plate_Num] = s.[RDS_Well_Plate_Num],
			    [RDS_Well_Num] = s.[RDS_Well_Num],
			    [RDS_priority] = s.[RDS_priority],
			    [RDS_note] = s.[RDS_note],
			    [Exp_ID] = s.[Exp_ID],
			    [RDS_Run_Start] = s.[RDS_Run_Start],
			    [RDS_Run_Finish] = s.[RDS_Run_Finish],
			    [RDS_internal_standard] = s.[RDS_internal_standard],
			    [RDS_WorkPackage] = s.[RDS_WorkPackage],
			    [RDS_BatchID] = s.[RDS_BatchID],
			    [RDS_Blocking_Factor] = s.[RDS_Blocking_Factor],
			    [RDS_Block] = s.[RDS_Block],
			    [RDS_Run_Order] = s.[RDS_Run_Order],
			    [RDS_EUS_Proposal_ID] = s.[RDS_EUS_Proposal_ID],
			    [RDS_EUS_UsageType] = s.[RDS_EUS_UsageType],
			    [RDS_Cart_ID] = s.[RDS_Cart_ID],
			    [RDS_Cart_Col] = s.[RDS_Cart_Col],
			    [RDS_Sec_Sep] = s.[RDS_Sec_Sep],
			    [RDS_MRM_Attachment] = s.[RDS_MRM_Attachment],
			    [DatasetID] = s.[DatasetID],
			    [RDS_Origin] = s.[RDS_Origin],
			    [RDS_Status] = s.[RDS_Status],
			    [RDS_NameCode] = s.[RDS_NameCode],
			    [Entered] = s.[Entered],
			    [Vialing_Conc] = s.[Vialing_Conc],
			    [Vialing_Vol] = s.[Vialing_Vol]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([RDS_Name], [RDS_Oper_PRN], [RDS_comment], [RDS_created], [RDS_instrument_name], [RDS_type_ID], [RDS_instrument_setting], [RDS_special_instructions], [RDS_Well_Plate_Num], [RDS_Well_Num], [RDS_priority], [RDS_note], [Exp_ID], [RDS_Run_Start], [RDS_Run_Finish], [RDS_internal_standard], [ID], [RDS_WorkPackage], [RDS_BatchID], [RDS_Blocking_Factor], [RDS_Block], [RDS_Run_Order], [RDS_EUS_Proposal_ID], [RDS_EUS_UsageType], [RDS_Cart_ID], [RDS_Cart_Col], [RDS_Sec_Sep], [RDS_MRM_Attachment], [DatasetID], [RDS_Origin], [RDS_Status], [RDS_NameCode], [Entered], [Vialing_Conc], [Vialing_Vol])
			    VALUES(s.[RDS_Name], s.[RDS_Oper_PRN], s.[RDS_comment], s.[RDS_created], s.[RDS_instrument_name], s.[RDS_type_ID], s.[RDS_instrument_setting], s.[RDS_special_instructions], s.[RDS_Well_Plate_Num], s.[RDS_Well_Num], s.[RDS_priority], s.[RDS_note], s.[Exp_ID], s.[RDS_Run_Start], s.[RDS_Run_Finish], s.[RDS_internal_standard], s.[ID], s.[RDS_WorkPackage], s.[RDS_BatchID], s.[RDS_Blocking_Factor], s.[RDS_Block], s.[RDS_Run_Order], s.[RDS_EUS_Proposal_ID], s.[RDS_EUS_UsageType], s.[RDS_Cart_ID], s.[RDS_Cart_Col], s.[RDS_Sec_Sep], s.[RDS_MRM_Attachment], s.[DatasetID], s.[RDS_Origin], s.[RDS_Status], s.[RDS_NameCode], s.[Entered], s.[Vialing_Conc], s.[Vialing_Vol])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Requested_Run] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End
		
		Set @tableName = 'T_Requested_Run_EUS_Users'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
 
			MERGE [dbo].[T_Requested_Run_EUS_Users] AS t
			USING (SELECT RRSource.* 
			       FROM [DMS5].[dbo].[T_Requested_Run_EUS_Users] RRSource INNER JOIN 
			            T_Requested_Run RR ON RRSource.Request_ID = RR.ID) as s
			ON ( t.[EUS_Person_ID] = s.[EUS_Person_ID] AND t.[Request_ID] = s.[Request_ID])
			-- Note: all of the columns in table T_Requested_Run_EUS_Users are primary keys or identity columns; there are no updatable columns
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([EUS_Person_ID], [Request_ID])
			    VALUES(s.[EUS_Person_ID], s.[Request_ID])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[EUS_Person_ID] as varchar(12)) + ', ' + Cast(Inserted.[Request_ID] as varchar(12)),
			       Cast(Deleted.[EUS_Person_ID] as varchar(12)) + ', ' + Cast(Deleted.[Request_ID] as varchar(12))
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

		Set @tableName = 'T_Requested_Run_Status_History'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Requested_Run_Status_History] ON;
			 
			MERGE [dbo].[T_Requested_Run_Status_History] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Requested_Run_Status_History]) as s
			ON ( t.[Entry_ID] = s.[Entry_ID])
			WHEN MATCHED AND (
			    t.[Posting_Time] <> s.[Posting_Time] OR
			    t.[State_ID] <> s.[State_ID] OR
			    t.[Origin] <> s.[Origin] OR
			    t.[Request_Count] <> s.[Request_Count] OR
			    ISNULL( NULLIF(t.[QueueTime_0Days], s.[QueueTime_0Days]),
			            NULLIF(s.[QueueTime_0Days], t.[QueueTime_0Days])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[QueueTime_1to6Days], s.[QueueTime_1to6Days]),
			            NULLIF(s.[QueueTime_1to6Days], t.[QueueTime_1to6Days])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[QueueTime_7to44Days], s.[QueueTime_7to44Days]),
			            NULLIF(s.[QueueTime_7to44Days], t.[QueueTime_7to44Days])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[QueueTime_45to89Days], s.[QueueTime_45to89Days]),
			            NULLIF(s.[QueueTime_45to89Days], t.[QueueTime_45to89Days])) IS NOT NULL OR
			   ISNULL( NULLIF(t.[QueueTime_90to179Days], s.[QueueTime_90to179Days]),
			            NULLIF(s.[QueueTime_90to179Days], t.[QueueTime_90to179Days])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[QueueTime_180DaysAndUp], s.[QueueTime_180DaysAndUp]),
			            NULLIF(s.[QueueTime_180DaysAndUp], t.[QueueTime_180DaysAndUp])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Posting_Time] = s.[Posting_Time],
			    [State_ID] = s.[State_ID],
			    [Origin] = s.[Origin],
			    [Request_Count] = s.[Request_Count],
			    [QueueTime_0Days] = s.[QueueTime_0Days],
			    [QueueTime_1to6Days] = s.[QueueTime_1to6Days],
			    [QueueTime_7to44Days] = s.[QueueTime_7to44Days],
			    [QueueTime_45to89Days] = s.[QueueTime_45to89Days],
			    [QueueTime_90to179Days] = s.[QueueTime_90to179Days],
			    [QueueTime_180DaysAndUp] = s.[QueueTime_180DaysAndUp]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Entry_ID], [Posting_Time], [State_ID], [Origin], [Request_Count], [QueueTime_0Days], [QueueTime_1to6Days], [QueueTime_7to44Days], [QueueTime_45to89Days], [QueueTime_90to179Days], [QueueTime_180DaysAndUp])
			    VALUES(s.[Entry_ID], s.[Posting_Time], s.[State_ID], s.[Origin], s.[Request_Count], s.[QueueTime_0Days], s.[QueueTime_1to6Days], s.[QueueTime_7to44Days], s.[QueueTime_45to89Days], s.[QueueTime_90to179Days], s.[QueueTime_180DaysAndUp])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[Entry_ID] as varchar(12)),
			       Cast(Deleted.[Entry_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Requested_Run_Status_History] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End
		
	End -- </Datasets>

	If @jobs <> 0
	Begin -- <Jobs>

		Set @tableName = 'T_Analysis_State_Name'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Analysis_State_Name] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Analysis_State_Name]) as s
			ON ( t.[AJS_stateID] = s.[AJS_stateID])
			WHEN MATCHED AND (
			    t.[AJS_name] <> s.[AJS_name] OR
			    ISNULL( NULLIF(t.[Comment], s.[Comment]),
			            NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [AJS_name] = s.[AJS_name],
			    [Comment] = s.[Comment]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([AJS_stateID], [AJS_name], [Comment])
			    VALUES(s.[AJS_stateID], s.[AJS_name], s.[Comment])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[AJS_stateID] as varchar(12)),
			       Cast(Deleted.[AJS_stateID] as varchar(12))
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

		Set @tableName = 'T_Predefined_Analysis'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Predefined_Analysis] ON;
			 
			MERGE [dbo].[T_Predefined_Analysis] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Predefined_Analysis]) as s
			ON ( t.[AD_ID] = s.[AD_ID])
			WHEN MATCHED AND (
			    t.[AD_level] <> s.[AD_level] OR
			    t.[AD_instrumentClassCriteria] <> s.[AD_instrumentClassCriteria] OR
			    t.[AD_campaignNameCriteria] <> s.[AD_campaignNameCriteria] OR
			    t.[AD_campaignExclCriteria] <> s.[AD_campaignExclCriteria] OR
			    t.[AD_experimentNameCriteria] <> s.[AD_experimentNameCriteria] OR
			    t.[AD_experimentExclCriteria] <> s.[AD_experimentExclCriteria] OR
			    t.[AD_instrumentNameCriteria] <> s.[AD_instrumentNameCriteria] OR
			    t.[AD_organismNameCriteria] <> s.[AD_organismNameCriteria] OR
			    t.[AD_datasetNameCriteria] <> s.[AD_datasetNameCriteria] OR
			    t.[AD_datasetExclCriteria] <> s.[AD_datasetExclCriteria] OR
			    t.[AD_datasetTypeCriteria] <> s.[AD_datasetTypeCriteria] OR
			    t.[AD_expCommentCriteria] <> s.[AD_expCommentCriteria] OR
			    t.[AD_labellingInclCriteria] <> s.[AD_labellingInclCriteria] OR
			    t.[AD_labellingExclCriteria] <> s.[AD_labellingExclCriteria] OR
			    t.[AD_separationTypeCriteria] <> s.[AD_separationTypeCriteria] OR
			    t.[AD_scanCountMinCriteria] <> s.[AD_scanCountMinCriteria] OR
			    t.[AD_scanCountMaxCriteria] <> s.[AD_scanCountMaxCriteria] OR
			    t.[AD_analysisToolName] <> s.[AD_analysisToolName] OR
			    t.[AD_parmFileName] <> s.[AD_parmFileName] OR
			    t.[AD_organism_ID] <> s.[AD_organism_ID] OR
			    t.[AD_organismDBName] <> s.[AD_organismDBName] OR
			    t.[AD_proteinCollectionList] <> s.[AD_proteinCollectionList] OR
			    t.[AD_proteinOptionsList] <> s.[AD_proteinOptionsList] OR
			    t.[AD_priority] <> s.[AD_priority] OR
			    t.[AD_enabled] <> s.[AD_enabled] OR
			    t.[AD_created] <> s.[AD_created] OR
			    t.[Trigger_Before_Disposition] <> s.[Trigger_Before_Disposition] OR
			    t.[Propagation_Mode] <> s.[Propagation_Mode] OR
			
			    ISNULL( NULLIF(t.[AD_sequence], s.[AD_sequence]),
			            NULLIF(s.[AD_sequence], t.[AD_sequence])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AD_settingsFileName], s.[AD_settingsFileName]),
			            NULLIF(s.[AD_settingsFileName], t.[AD_settingsFileName])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AD_specialProcessing], s.[AD_specialProcessing]),
			            NULLIF(s.[AD_specialProcessing], t.[AD_specialProcessing])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AD_description], s.[AD_description]),
			            NULLIF(s.[AD_description], t.[AD_description])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AD_creator], s.[AD_creator]),
			            NULLIF(s.[AD_creator], t.[AD_creator])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AD_nextLevel], s.[AD_nextLevel]),
			            NULLIF(s.[AD_nextLevel], t.[AD_nextLevel])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [AD_level] = s.[AD_level],
			    [AD_sequence] = s.[AD_sequence],
			    [AD_instrumentClassCriteria] = s.[AD_instrumentClassCriteria],
			    [AD_campaignNameCriteria] = s.[AD_campaignNameCriteria],
			    [AD_campaignExclCriteria] = s.[AD_campaignExclCriteria],
			    [AD_experimentNameCriteria] = s.[AD_experimentNameCriteria],
			    [AD_experimentExclCriteria] = s.[AD_experimentExclCriteria],
			    [AD_instrumentNameCriteria] = s.[AD_instrumentNameCriteria],
			    [AD_organismNameCriteria] = s.[AD_organismNameCriteria],
			    [AD_datasetNameCriteria] = s.[AD_datasetNameCriteria],
			    [AD_datasetExclCriteria] = s.[AD_datasetExclCriteria],
			    [AD_datasetTypeCriteria] = s.[AD_datasetTypeCriteria],
			    [AD_expCommentCriteria] = s.[AD_expCommentCriteria],
			    [AD_labellingInclCriteria] = s.[AD_labellingInclCriteria],
			    [AD_labellingExclCriteria] = s.[AD_labellingExclCriteria],
			    [AD_separationTypeCriteria] = s.[AD_separationTypeCriteria],
			    [AD_scanCountMinCriteria] = s.[AD_scanCountMinCriteria],
			    [AD_scanCountMaxCriteria] = s.[AD_scanCountMaxCriteria],
			    [AD_analysisToolName] = s.[AD_analysisToolName],
			    [AD_parmFileName] = s.[AD_parmFileName],
			    [AD_settingsFileName] = s.[AD_settingsFileName],
			    [AD_organism_ID] = s.[AD_organism_ID],
			    [AD_organismDBName] = s.[AD_organismDBName],
			    [AD_proteinCollectionList] = s.[AD_proteinCollectionList],
			    [AD_proteinOptionsList] = s.[AD_proteinOptionsList],
			    [AD_priority] = s.[AD_priority],
			    [AD_specialProcessing] = s.[AD_specialProcessing],
			    [AD_enabled] = s.[AD_enabled],
			    [AD_description] = s.[AD_description],
			    [AD_created] = s.[AD_created],
			    [AD_creator] = s.[AD_creator],
			    [AD_nextLevel] = s.[AD_nextLevel],
			    [Trigger_Before_Disposition] = s.[Trigger_Before_Disposition],
			    [Propagation_Mode] = s.[Propagation_Mode],
			    [Last_Affected] = s.[Last_Affected]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([AD_ID], [AD_level], [AD_sequence], [AD_instrumentClassCriteria], [AD_campaignNameCriteria], [AD_campaignExclCriteria], [AD_experimentNameCriteria], [AD_experimentExclCriteria], [AD_instrumentNameCriteria], [AD_organismNameCriteria], [AD_datasetNameCriteria], [AD_datasetExclCriteria], [AD_datasetTypeCriteria], [AD_expCommentCriteria], [AD_labellingInclCriteria], [AD_labellingExclCriteria], [AD_separationTypeCriteria], [AD_scanCountMinCriteria], [AD_scanCountMaxCriteria], [AD_analysisToolName], [AD_parmFileName], [AD_settingsFileName], [AD_organism_ID], [AD_organismDBName], [AD_proteinCollectionList], [AD_proteinOptionsList], [AD_priority], [AD_specialProcessing], [AD_enabled], [AD_description], [AD_created], [AD_creator], [AD_nextLevel], [Trigger_Before_Disposition], [Propagation_Mode], [Last_Affected])
			    VALUES(s.[AD_ID], s.[AD_level], s.[AD_sequence], s.[AD_instrumentClassCriteria], s.[AD_campaignNameCriteria], s.[AD_campaignExclCriteria], s.[AD_experimentNameCriteria], s.[AD_experimentExclCriteria], s.[AD_instrumentNameCriteria], s.[AD_organismNameCriteria], s.[AD_datasetNameCriteria], s.[AD_datasetExclCriteria], s.[AD_datasetTypeCriteria], s.[AD_expCommentCriteria], s.[AD_labellingInclCriteria], s.[AD_labellingExclCriteria], s.[AD_separationTypeCriteria], s.[AD_scanCountMinCriteria], s.[AD_scanCountMaxCriteria], s.[AD_analysisToolName], s.[AD_parmFileName], s.[AD_settingsFileName], s.[AD_organism_ID], s.[AD_organismDBName], s.[AD_proteinCollectionList], s.[AD_proteinOptionsList], s.[AD_priority], s.[AD_specialProcessing], s.[AD_enabled], s.[AD_description], s.[AD_created], s.[AD_creator], s.[AD_nextLevel], s.[Trigger_Before_Disposition], s.[Propagation_Mode], s.[Last_Affected])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[AD_ID] as varchar(12)),
			       Cast(Deleted.[AD_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Predefined_Analysis] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Analysis_Job_Request'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Analysis_Job_Request] ON;
			 
			MERGE [dbo].[T_Analysis_Job_Request] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Analysis_Job_Request]) as s
			ON ( t.[AJR_requestID] = s.[AJR_requestID])
			WHEN MATCHED AND (
			    t.[AJR_requestName] <> s.[AJR_requestName] OR
			    t.[AJR_created] <> s.[AJR_created] OR
			    t.[AJR_analysisToolName] <> s.[AJR_analysisToolName] OR
			    t.[AJR_parmFileName] <> s.[AJR_parmFileName] OR
			    t.[AJR_organism_ID] <> s.[AJR_organism_ID] OR
			    t.[AJR_datasets] <> s.[AJR_datasets] OR
			    t.[AJR_requestor] <> s.[AJR_requestor] OR
			    t.[AJR_state] <> s.[AJR_state] OR
			    t.[AJR_proteinCollectionList] <> s.[AJR_proteinCollectionList] OR
			    t.[AJR_proteinOptionsList] <> s.[AJR_proteinOptionsList] OR
			    ISNULL( NULLIF(t.[AJR_settingsFileName], s.[AJR_settingsFileName]),
			            NULLIF(s.[AJR_settingsFileName], t.[AJR_settingsFileName])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJR_organismDBName], s.[AJR_organismDBName]),
			            NULLIF(s.[AJR_organismDBName], t.[AJR_organismDBName])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJR_comment], s.[AJR_comment]),
			            NULLIF(s.[AJR_comment], t.[AJR_comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJR_workPackage], s.[AJR_workPackage]),
			            NULLIF(s.[AJR_workPackage], t.[AJR_workPackage])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJR_jobCount], s.[AJR_jobCount]),
			            NULLIF(s.[AJR_jobCount], t.[AJR_jobCount])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJR_specialProcessing], s.[AJR_specialProcessing]),
			            NULLIF(s.[AJR_specialProcessing], t.[AJR_specialProcessing])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [AJR_requestName] = s.[AJR_requestName],
			    [AJR_created] = s.[AJR_created],
			    [AJR_analysisToolName] = s.[AJR_analysisToolName],
			    [AJR_parmFileName] = s.[AJR_parmFileName],
			    [AJR_settingsFileName] = s.[AJR_settingsFileName],
			    [AJR_organismDBName] = s.[AJR_organismDBName],
			    [AJR_organism_ID] = s.[AJR_organism_ID],
			    [AJR_datasets] = s.[AJR_datasets],
			    [AJR_requestor] = s.[AJR_requestor],
			    [AJR_comment] = s.[AJR_comment],
			    [AJR_state] = s.[AJR_state],
			    [AJR_proteinCollectionList] = s.[AJR_proteinCollectionList],
			    [AJR_proteinOptionsList] = s.[AJR_proteinOptionsList],
			    [AJR_workPackage] = s.[AJR_workPackage],
			    [AJR_jobCount] = s.[AJR_jobCount],
			    [AJR_specialProcessing] = s.[AJR_specialProcessing]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([AJR_requestID], [AJR_requestName], [AJR_created], [AJR_analysisToolName], [AJR_parmFileName], [AJR_settingsFileName], [AJR_organismDBName], [AJR_organism_ID], [AJR_datasets], [AJR_requestor], [AJR_comment], [AJR_state], [AJR_proteinCollectionList], [AJR_proteinOptionsList], [AJR_workPackage], [AJR_jobCount], [AJR_specialProcessing])
			    VALUES(s.[AJR_requestID], s.[AJR_requestName], s.[AJR_created], s.[AJR_analysisToolName], s.[AJR_parmFileName], s.[AJR_settingsFileName], s.[AJR_organismDBName], s.[AJR_organism_ID], s.[AJR_datasets], s.[AJR_requestor], s.[AJR_comment], s.[AJR_state], s.[AJR_proteinCollectionList], s.[AJR_proteinOptionsList], s.[AJR_workPackage], s.[AJR_jobCount], s.[AJR_specialProcessing])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[AJR_requestID] as varchar(12)),
			       Cast(Deleted.[AJR_requestID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Analysis_Job_Request] OFF;
			
			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Analysis_Job_ID'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Analysis_Job_ID] ON;
			 
			MERGE [dbo].[T_Analysis_Job_ID] AS t
			USING (SELECT * 
			       FROM [DMS5].[dbo].[T_Analysis_Job_ID] 
			       WHERE [Created] >= @importThreshold OR 
			             [ID] IN ( SELECT AJSource.AJ_JobID
			                       FROM [DMS5].[dbo].[T_Analysis_Job] AJSource INNER JOIN 
				                  [T_Dataset] DS ON AJSource.AJ_DatasetID = DS.Dataset_ID)
				  ) as s
			ON ( t.[ID] = s.[ID])
			WHEN MATCHED AND (
			    t.[Created] <> s.[Created] OR
			    ISNULL( NULLIF(t.[Note], s.[Note]),
			            NULLIF(s.[Note], t.[Note])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Note] = s.[Note],
			    [Created] = s.[Created]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([ID], [Note], [Created])
			    VALUES(s.[ID], s.[Note], s.[Created])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[ID] as varchar(12)),
			       Cast(Deleted.[ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Analysis_Job_ID] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Analysis_Job_Batches'
		Print 'Updating ' + @tableName
		If @infoOnly = 0
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			SET IDENTITY_INSERT [dbo].[T_Analysis_Job_Batches] ON;
			 
			MERGE [dbo].[T_Analysis_Job_Batches] AS t
			USING (SELECT * FROM [DMS5].[dbo].[T_Analysis_Job_Batches]) as s
			ON ( t.[Batch_ID] = s.[Batch_ID])
			WHEN MATCHED AND (
			    t.[Batch_Created] <> s.[Batch_Created] OR
			    ISNULL( NULLIF(t.[Batch_Description], s.[Batch_Description]),
			            NULLIF(s.[Batch_Description], t.[Batch_Description])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [Batch_Created] = s.[Batch_Created],
			    [Batch_Description] = s.[Batch_Description]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([Batch_ID], [Batch_Created], [Batch_Description])
			    VALUES(s.[Batch_ID], s.[Batch_Created], s.[Batch_Description])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[Batch_ID] as varchar(12)),
			       Cast(Deleted.[Batch_ID] as varchar(12))
			       INTO #Tmp_SummaryOfChanges;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			 
			SET IDENTITY_INSERT [dbo].[T_Analysis_Job_Batches] OFF;

			If @myError <> 0 
			Begin
				Set @message = 'Error updating ' + @tableName
				Goto Done
			End
			
			If @myRowCount > 0
				exec SyncWithDMSShowStats @myRowCount, @ShowUpdateDetails
		End

		Set @tableName = 'T_Analysis_Job'
		Print 'Updating ' + @tableName
		If @infoOnly = 0 and 3 = 4
		Begin
			Truncate Table #Tmp_SummaryOfChanges
			 
			MERGE [dbo].[T_Analysis_Job] AS t
			USING (SELECT AJSource.* 
			       FROM [DMS5].[dbo].[T_Analysis_Job] AJSource INNER JOIN 
				        [T_Dataset] DS ON AJSource.AJ_DatasetID = DS.Dataset_ID) as s
			ON ( t.[AJ_jobID] = s.[AJ_jobID])
			WHEN MATCHED AND (
			    t.[AJ_priority] <> s.[AJ_priority] OR
			    t.[AJ_created] <> s.[AJ_created] OR
			    t.[AJ_analysisToolID] <> s.[AJ_analysisToolID] OR
			    t.[AJ_parmFileName] <> s.[AJ_parmFileName] OR
			    t.[AJ_organismID] <> s.[AJ_organismID] OR
			    t.[AJ_datasetID] <> s.[AJ_datasetID] OR
			    t.[AJ_StateID] <> s.[AJ_StateID] OR
			    t.[AJ_Last_Affected] <> s.[AJ_Last_Affected] OR
			    t.[AJ_proteinOptionsList] <> s.[AJ_proteinOptionsList] OR
			    t.[AJ_requestID] <> s.[AJ_requestID] OR
			    t.[AJ_Analysis_Manager_Error] <> s.[AJ_Analysis_Manager_Error] OR
			    t.[AJ_Data_Extraction_Error] <> s.[AJ_Data_Extraction_Error] OR
			    t.[AJ_propagationMode] <> s.[AJ_propagationMode] OR
			    t.[AJ_StateNameCached] <> s.[AJ_StateNameCached] OR
			    t.[AJ_DatasetUnreviewed] <> s.[AJ_DatasetUnreviewed] OR
			    t.[AJ_Purged] <> s.[AJ_Purged] OR
			    t.[AJ_MyEMSLState] <> s.[AJ_MyEMSLState] OR
			    ISNULL( NULLIF(t.[AJ_batchID], s.[AJ_batchID]),
			            NULLIF(s.[AJ_batchID], t.[AJ_batchID])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_start], s.[AJ_start]),
			            NULLIF(s.[AJ_start], t.[AJ_start])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_finish], s.[AJ_finish]),
			            NULLIF(s.[AJ_finish], t.[AJ_finish])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_settingsFileName], s.[AJ_settingsFileName]),
			            NULLIF(s.[AJ_settingsFileName], t.[AJ_settingsFileName])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_organismDBName], s.[AJ_organismDBName]),
			            NULLIF(s.[AJ_organismDBName], t.[AJ_organismDBName])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_comment], s.[AJ_comment]),
			            NULLIF(s.[AJ_comment], t.[AJ_comment])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_owner], s.[AJ_owner]),
			            NULLIF(s.[AJ_owner], t.[AJ_owner])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_assignedProcessorName], s.[AJ_assignedProcessorName]),
			            NULLIF(s.[AJ_assignedProcessorName], t.[AJ_assignedProcessorName])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_resultsFolderName], s.[AJ_resultsFolderName]),
			            NULLIF(s.[AJ_resultsFolderName], t.[AJ_resultsFolderName])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_proteinCollectionList], s.[AJ_proteinCollectionList]),
			            NULLIF(s.[AJ_proteinCollectionList], t.[AJ_proteinCollectionList])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_extractionProcessor], s.[AJ_extractionProcessor]),
			            NULLIF(s.[AJ_extractionProcessor], t.[AJ_extractionProcessor])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_extractionStart], s.[AJ_extractionStart]),
			            NULLIF(s.[AJ_extractionStart], t.[AJ_extractionStart])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_extractionFinish], s.[AJ_extractionFinish]),
			            NULLIF(s.[AJ_extractionFinish], t.[AJ_extractionFinish])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_ProcessingTimeMinutes], s.[AJ_ProcessingTimeMinutes]),
			            NULLIF(s.[AJ_ProcessingTimeMinutes], t.[AJ_ProcessingTimeMinutes])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_specialProcessing], s.[AJ_specialProcessing]),
			            NULLIF(s.[AJ_specialProcessing], t.[AJ_specialProcessing])) IS NOT NULL OR
			    ISNULL( NULLIF(t.[AJ_ToolNameCached], s.[AJ_ToolNameCached]),
			            NULLIF(s.[AJ_ToolNameCached], t.[AJ_ToolNameCached])) IS NOT NULL
			    )
			THEN UPDATE SET 
			    [AJ_batchID] = s.[AJ_batchID],
			    [AJ_priority] = s.[AJ_priority],
			    [AJ_created] = s.[AJ_created],
			    [AJ_start] = s.[AJ_start],
			    [AJ_finish] = s.[AJ_finish],
			    [AJ_analysisToolID] = s.[AJ_analysisToolID],
			    [AJ_parmFileName] = s.[AJ_parmFileName],
			    [AJ_settingsFileName] = s.[AJ_settingsFileName],
			    [AJ_organismDBName] = s.[AJ_organismDBName],
			    [AJ_organismID] = s.[AJ_organismID],
			    [AJ_datasetID] = s.[AJ_datasetID],
			    [AJ_comment] = s.[AJ_comment],
			    [AJ_owner] = s.[AJ_owner],
			    [AJ_StateID] = s.[AJ_StateID],
			    [AJ_Last_Affected] = s.[AJ_Last_Affected],
			    [AJ_assignedProcessorName] = s.[AJ_assignedProcessorName],
			    [AJ_resultsFolderName] = s.[AJ_resultsFolderName],
			    [AJ_proteinCollectionList] = s.[AJ_proteinCollectionList],
			    [AJ_proteinOptionsList] = s.[AJ_proteinOptionsList],
			    [AJ_requestID] = s.[AJ_requestID],
			    [AJ_extractionProcessor] = s.[AJ_extractionProcessor],
			    [AJ_extractionStart] = s.[AJ_extractionStart],
			    [AJ_extractionFinish] = s.[AJ_extractionFinish],
			    [AJ_Analysis_Manager_Error] = s.[AJ_Analysis_Manager_Error],
			    [AJ_Data_Extraction_Error] = s.[AJ_Data_Extraction_Error],
			    [AJ_propagationMode] = s.[AJ_propagationMode],
			    [AJ_StateNameCached] = s.[AJ_StateNameCached],
			    [AJ_ProcessingTimeMinutes] = s.[AJ_ProcessingTimeMinutes],
			    [AJ_specialProcessing] = s.[AJ_specialProcessing],
			    [AJ_DatasetUnreviewed] = s.[AJ_DatasetUnreviewed],
			    [AJ_Purged] = s.[AJ_Purged],
			    [AJ_MyEMSLState] = s.[AJ_MyEMSLState],
			    [AJ_ToolNameCached] = s.[AJ_ToolNameCached]
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT([AJ_jobID], [AJ_batchID], [AJ_priority], [AJ_created], [AJ_start], [AJ_finish], [AJ_analysisToolID], [AJ_parmFileName], [AJ_settingsFileName], [AJ_organismDBName], [AJ_organismID], [AJ_datasetID], [AJ_comment], [AJ_owner], [AJ_StateID], [AJ_Last_Affected], [AJ_assignedProcessorName], [AJ_resultsFolderName], [AJ_proteinCollectionList], [AJ_proteinOptionsList], [AJ_requestID], [AJ_extractionProcessor], [AJ_extractionStart], [AJ_extractionFinish], [AJ_Analysis_Manager_Error], [AJ_Data_Extraction_Error], [AJ_propagationMode], [AJ_StateNameCached], [AJ_ProcessingTimeMinutes], [AJ_specialProcessing], [AJ_DatasetUnreviewed], [AJ_Purged], [AJ_MyEMSLState], [AJ_ToolNameCached])
			    VALUES(s.[AJ_jobID], s.[AJ_batchID], s.[AJ_priority], s.[AJ_created], s.[AJ_start], s.[AJ_finish], s.[AJ_analysisToolID], s.[AJ_parmFileName], s.[AJ_settingsFileName], s.[AJ_organismDBName], s.[AJ_organismID], s.[AJ_datasetID], s.[AJ_comment], s.[AJ_owner], s.[AJ_StateID], s.[AJ_Last_Affected], s.[AJ_assignedProcessorName], s.[AJ_resultsFolderName], s.[AJ_proteinCollectionList], s.[AJ_proteinOptionsList], s.[AJ_requestID], s.[AJ_extractionProcessor], s.[AJ_extractionStart], s.[AJ_extractionFinish], s.[AJ_Analysis_Manager_Error], s.[AJ_Data_Extraction_Error], s.[AJ_propagationMode], s.[AJ_StateNameCached], s.[AJ_ProcessingTimeMinutes], s.[AJ_specialProcessing], s.[AJ_DatasetUnreviewed], s.[AJ_Purged], s.[AJ_MyEMSLState], s.[AJ_ToolNameCached])
			WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE
			OUTPUT @tableName, $action,
			       Cast(Inserted.[AJ_jobID] as varchar(12)),
			       Cast(Deleted.[AJ_jobID] as varchar(12))
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

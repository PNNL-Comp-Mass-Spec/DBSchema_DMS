/****** Object:  StoredProcedure [dbo].[GetJobParamTable] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetJobParamTable
/****************************************************
**
**	Desc:	Returns a table filled with the parameters for the
**			given job in Section/Name/Value rows.
**
**	Note:	This table of parameters comes from the DMS5 database, and
**			not from the T_Job_Parameters table local to this DB
**
**	Return values: 
**
**	Parameters:
**	
**
**	Auth:	grk
**	Date:	08/21/2008 grk - Initial release
**			01/14/2009 mem - Increased maximum parameter length to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**			04/10/2009 grk - Added DTA folder name override (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**			06/02/2009 mem - Updated to run within the DMS_Pipeline DB and to use view V_DMS_PipelineJobParameters (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**			07/29/2009 mem - Updated to look in T_Jobs.Comment for the 'DTA:' tag when 'ExternalDTAFolderName' is defined in the script
**			01/05/2010 mem - Added parameter @SettingsFileOverride
**			02/23/2010 mem - Updated to not return any debug info using SELECT statements; required since CreateParametersForJob calls this SP using the notation: INSERT INTO ... exec GetJobParamTable ...
**			04/04/2011 mem - Updated to support V_DMS_SettingsFiles returning true XML for the Contents column (using S_DMS_V_GetPipelineSettingsFiles)
**						   - Added support for field Special_Processing
**			04/20/2011 mem - Now calling CheckAddSpecialProcessingParam to look for an AMTDB entry in the Special_Processing parameter
**						   - Additionally, adding parameter AMTDBServer if the AMTDB entry is present
**			08/01/2011 mem - Now filtering on Analysis_Tool when querying V_DMS_SettingsFiles
**			05/07/2012 mem - Now including DatasetType
**			05/07/2012 mem - Now including Experiment
**			08/23/2012 mem - Now calling CheckAddSpecialProcessingParam to look for a DataImportFolder entry
**			04/23/2013 mem - Now including Instrument and InstrumentGroup
**			01/30/2014 mem - Now using S_DMS_V_Settings_File_Lookup when a match is not found in V_DMS_SettingsFiles for the given settings file and analysis tool
**    
*****************************************************/
(
	@job int,
	@SettingsFileOverride varchar(256) = '',	-- When defined, then will use this settings file name instead of the one obtained with V_DMS_PipelineJobParameters
	@DebugMode tinyint = 0						-- When non-zero, then will print "debug" statements
)
AS
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @message varchar(512)
	set @message  = ''

	Set @SettingsFileOverride = IsNull(@SettingsFileOverride, '')
	Set @DebugMode = IsNull(@DebugMode, 0)
	
	---------------------------------------------------
	-- Table variable to hold job parameters
	---------------------------------------------------
	--
	CREATE TABLE #T_Tmp_ParamTab
	(
		[Step_Number] Varchar(24),
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(2000)
	)

	---------------------------------------------------
	-- Get job parameters that are table columns
	-- Note that V_DMS_PipelineJobParameters uses S_DMS_V_GetPipelineJobParameters which uses V_GetPipelineJobParameters in DMS5
	---------------------------------------------------
	--
	INSERT INTO #T_Tmp_ParamTab ([Step_Number], [Section], [Name], [Value])
	SELECT NULL as Step_Number, 'JobParameters' as [Section], TP.Name, TP.Value
	FROM
	(
		SELECT 
		  CONVERT(VarChar(2000),Dataset)                        AS DatasetNum,
		  CONVERT(VarChar(2000),Dataset_ID )                    AS DatasetID,
		  CONVERT(VarChar(2000),Dataset_Folder_Name)            AS DatasetFolderName,
		  CONVERT(VarChar(2000),Archive_Folder_Path)            AS DatasetArchivePath,
		  CONVERT(VarChar(2000),Dataset_Storage_Path)           AS DatasetStoragePath,
		  CONVERT(VarChar(2000),Transfer_Folder_Path)           AS transferFolderPath,
		  CONVERT(VarChar(2000),ParamFileName)                  AS ParmFileName,
		  CONVERT(VarChar(2000),SettingsFileName)               AS SettingsFileName,
		  CONVERT(VarChar(2000),Special_Processing)             AS Special_Processing,
		  CONVERT(VarChar(2000),ParamFileStoragePath)           AS ParmFileStoragePath,
		  CONVERT(VarChar(2000),OrganismDBName)                 AS legacyFastaFileName,
		  CONVERT(VarChar(2000),ProteinCollectionList)          AS ProteinCollectionList,
		  CONVERT(VarChar(2000),ProteinOptionsList)             AS ProteinOptions,
		  CONVERT(VarChar(2000),InstrumentClass)                AS InstClass,
		  CONVERT(VarChar(2000),InstrumentGroup)                AS InstrumentGroup,
		  CONVERT(VarChar(2000),Instrument)                     AS Instrument,
		  CONVERT(VarChar(2000),RawDataType)                    AS RawDataType,
		  CONVERT(VarChar(2000),DatasetType)                    AS DatasetType,
		  CONVERT(VarChar(2000),Experiment)                     AS Experiment,
		  CONVERT(VarChar(2000),SearchEngineInputFileFormats)   AS SearchEngineInputFileFormats,
		  CONVERT(VarChar(2000),Organism)  AS OrganismName,
		  CONVERT(VarChar(2000),OrgDBRequired)                  AS OrgDbReqd,
		  CONVERT(VarChar(2000),ToolName)                       AS ToolName,
		  CONVERT(VarChar(2000),ResultType)                     AS ResultType
		FROM V_DMS_PipelineJobParameters
		WHERE Job = @job
	) TD
	UNPIVOT (Value For [Name] In (
		DatasetNum,
		DatasetID,
		DatasetFolderName,
		DatasetStoragePath,
		DatasetArchivePath,
		transferFolderPath,
		ParmFileName,
		SettingsFileName,
		Special_Processing,
		ParmFileStoragePath,
		legacyFastaFileName,
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
	-- FUTURE: Do tool also <section name="Search" tool="Sequest" category="basic">'
	--
	UPDATE #T_Tmp_ParamTab
	SET [Section] = 'PeptideSearch'
	WHERE [Name] in ('ParmFileName', 'ParmFileStoragePath', 'OrganismName',  'legacyFastaFileName',  'ProteinCollectionList',  'ProteinOptions')
		
	---------------------------------------------------
	-- Possibly override the settings file name
	---------------------------------------------------
	--
	If @SettingsFileOverride <> ''
	Begin
		UPDATE #T_Tmp_ParamTab
		SET [Value] = @SettingsFileOverride
		WHERE [Name] = 'SettingsFileName'
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount >= 1
		Begin
			If @DebugMode <> 0
				Print 'Updated settings file to be "' + @SettingsFileOverride
		End
		Else
		Begin
			INSERT INTO #T_Tmp_ParamTab ([Step_Number], [Section], [Name], [Value])
			SELECT	NULL as Step_Number, 
					'JobParameters' AS [Section], 
					'SettingsFileName' AS Name, 
					@SettingsFileOverride AS Value

			If @DebugMode <> 0
				Print 'Settings file was not defined; defined it to be "' + @SettingsFileOverride
		End
	End
	
  	---------------------------------------------------
	-- Get settings file parameters from DMS
	---------------------------------------------------
	--
	declare @paramXML xml
	declare @settingsFileName varchar(128)
	declare @AnalysisToolName varchar(128)
	
	-- Lookup the settings file name
	--
	set @settingsFileName = ''
	SELECT @settingsFileName = [Value] 
	FROM #T_Tmp_ParamTab 
	WHERE [Name] = 'SettingsFileName'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0 Or @settingsFileName Is Null
	Begin
		Set @settingsFileName = 'na'
		
		If @DebugMode <> 0
			Print 'Warning: Settings file was not defined in the job parameters; assuming "na"'
	End
	
	-- Lookup the analysis tool name
	--
	set @AnalysisToolName = ''
	SELECT @AnalysisToolName = [Value] 
	FROM #T_Tmp_ParamTab 
	WHERE [Name] = 'ToolName'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0 Or @AnalysisToolName Is Null
	Begin
		Set @AnalysisToolName = ''
		
		If @DebugMode <> 0
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
		declare @AnalysisToolNameMappedTool varchar(128)
		
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
		If @DebugMode <> 0
			Print 'Warning: Settings file "' + @settingsFileName + '" not defined in V_DMS_SettingsFiles'
	End
	Else
	Begin
		If @DebugMode <> 0
			Print 'XML for settings file "' + @settingsFileName + '": ' + Convert(varchar(max), @paramXML)
			
		INSERT INTO #T_Tmp_ParamTab
		SELECT 
			xmlNode.value('../@id', 'nvarchar(50)') [Step_Number],
			xmlNode.value('../@name', 'nvarchar(256)') [Section],
			xmlNode.value('@key', 'nvarchar(256)') [Name], 
			xmlNode.value('@value', 'nvarchar(4000)') [Value]
		FROM   @paramXML.nodes('//item') AS R(xmlNode)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @DebugMode <> 0
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


/*
  	-- Old code to backfill any missing parameters from global set
	set @settingsFileName = 'global_defaults'
	--
	SELECT @paramXML = Contents
	FROM V_DMS_SettingsFiles 
	WHERE File_Name = @settingsFileName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		If @DebugMode <> 0
			Print 'Note: the global defaults settings file ("' + @settingsFileName + '") is not defined in V_DMS_SettingsFiles'
	End
	Else
	Begin
		If @DebugMode <> 0
			Print 'XML for settings file "' + @settingsFileName + '": ' + Convert(varchar(max), @paramXML)

		INSERT INTO #T_Tmp_ParamTab
		SELECT * FROM
		(
		SELECT 
			xmlNode.value('../@id', 'nvarchar(50)') [Step_Number],
			xmlNode.value('../@name', 'nvarchar(256)') [Section],
			xmlNode.value('@key', 'nvarchar(256)') [Name], 
			xmlNode.value('@value', 'nvarchar(2000)') [Value]
		FROM   @paramXML.nodes('//item') AS R(xmlNode)
		) VG
		WHERE NOT EXISTS
		(
			SELECT *
			FROM   
				#T_Tmp_ParamTab VS
			WHERE 
				VS.Section = VG.Section AND VS.Name = VG.Name
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @DebugMode <> 0
			Print 'Added ' + Convert(varchar(12), @myRowCount) + ' new entries using the global defaults settings file ("' + @settingsFileName + '")'
	End
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
		-- If one exists, then look for the DTA: tag
		-- Otherwise, look in the job's comment for the DTA: tag
		-- If the DTA: tag is found, the name after the column represents an external DTA folder name
		--  to override the external DTA folder name defined in the settings file
		---------------------------------------------------
		--
		declare @extDTA varchar(128)
		set @extDTA = ''

		SELECT @extDTA = dbo.ExtractTaggedName('DTA:', Value) 
		FROM #T_Tmp_ParamTab 
		WHERE [Name] = 'Special_Processing'
		--		
		If @extDTA = ''
			SELECT @extDTA = dbo.ExtractTaggedName('DTA:', Comment) 
			FROM T_Jobs
			WHERE Job = @job
		--
		If @extDTA <> ''
		Begin
			UPDATE #T_Tmp_ParamTab
			SET [Value] = @extDTA
			WHERE [Name] = 'ExternalDTAFolderName'
			
			If @DebugMode <> 0
				Print 'External DTA Folder Name parameter has been overridden to "' + @extDTA + '" using the DTA: tag in the job comment'
		End
		Else
		Begin
			SELECT @extDTA = Value
			FROM #T_Tmp_ParamTab
			WHERE [Name] = 'ExternalDTAFolderName'
			
			If @DebugMode <> 0
				Print 'Note: ExternalDTAFolderName is  "' + @extDTA + '", as defined in the settings file'
		End
	end

  	---------------------------------------------------
	-- Check whether the Special_Processing field has an AMT DB defined
	-- If it does, then add this as a new parameter in the JobParameters section
	---------------------------------------------------
	--		
	exec CheckAddSpecialProcessingParam 'AMTDB'
	
	-- If AMTDB is defined, then we need to lookup the name of the server on which the MT DB resides
	Declare @AMTDB varchar(256) = ''
	
	SELECT @AMTDB = Value
	FROM #T_Tmp_ParamTab
	WHERE [Section] = 'JobParameters' AND [Name] = 'AMTDB'
	
	If Len(IsNull(@AMTDB, '')) > 0
	Begin
		Declare @AMTDBServer varchar(128) = ''
		
		SELECT @AMTDBServer = Server_Name
		FROM S_DMS_V_MTS_MT_DBs
		WHERE State_ID < 100 AND MT_DB_Name = @AMTDB
		
		If Len(IsNull(@AMTDB, '')) = 0
		Begin
			-- DB not found in S_DMS_V_MTS_MT_DBs
			-- Try directly querying MTS (via the appropriate synonym in DMS5)
			SELECT @AMTDBServer = Server_Name
			FROM DMS5.dbo.S_MTS_MT_DBs
			WHERE State_ID < 100 AND MT_DB_Name = @AMTDB
			
		End
		
		If Len(IsNull(@AMTDBServer, '')) = 0
		Begin
			Set @message = 'Unable to resolve MTS server for database ' + @AMTDB + '; not listed in DMS5.dbo.S_MTS_MT_DBs'
			exec PostLogEntry 'Error', @message, 'GetJobParamTable'
			set @message = ''
		End
		
		-- Add entry 'AMTDBServer' to #T_Tmp_ParamTab
		exec AddUpdateTmpParamTabEntry 'JobParameters', 'AMTDBServer', @AMTDBServer
	End
	
	--------------------------------------------------
	-- Check whether the Special_Processing field has a Data Import Folder defined
	-- If it does, then add this as a new parameter in the JobParameters section
	---------------------------------------------------
	--		
	exec CheckAddSpecialProcessingParam 'DataImportFolder'
	

  	---------------------------------------------------
	-- output the table of parameters
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
GRANT VIEW DEFINITION ON [dbo].[GetJobParamTable] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetJobParamTable] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetJobParamTable] TO [PNL\D3M580] AS [dbo]
GO

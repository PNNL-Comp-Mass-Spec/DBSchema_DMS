/****** Object:  StoredProcedure [dbo].[GetJobParamTable] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetJobParamTable
/****************************************************
**
**	Desc: 
**  Returns a table filled with the parameters for the
**  given job in Section/Name/Value rows
**
**	Return values: 
**
**	Parameters:
**	
**
**		Auth: grk
**		Date: 8/21/2008
**      
**    
*****************************************************/
(
	@job int
)
AS
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	declare @message varchar(512)
	set @message  = ''

	---------------------------------------------------
	-- Table variable to hold job parameters
	---------------------------------------------------
	--
	declare @paramTab TABLE(
		[Step_Number] Varchar(24),
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(256)
	)

	---------------------------------------------------
	-- Get job parameters that are table columns
	---------------------------------------------------
	--
	INSERT INTO @paramTab
	SELECT NULL as Step_Number, 'JobParameters' as [Section], TP.Name, TP.Value
	FROM
	(
		SELECT 
		  CONVERT(VARCHAR(256),Dataset_Num)                        AS DatasetNum,
		  CONVERT(VARCHAR(256),Dataset_ID )                        AS DatasetID,
		  CONVERT(VARCHAR(256),DS_folder_name)                     AS DatasetFolderName,
		  CONVERT(VARCHAR(256),AP_network_share_path)              AS DatasetArchivePath,
		  CONVERT(VARCHAR(256),DatasetStoragePathLocal)            AS DatasetStoragePath,
		  CONVERT(VARCHAR(256),transferFolderPath)                 AS transferFolderPath,
		  CONVERT(VARCHAR(256),AJ_parmFileName)                    AS ParmFileName,
		  CONVERT(VARCHAR(256),AJ_settingsFileName)                AS SettingsFileName,
		  CONVERT(VARCHAR(256),AJT_parmFileStoragePath)            AS ParmFileStoragePath,
		  CONVERT(VARCHAR(256),AJ_organismDBName)                  AS legacyFastaFileName,
		  CONVERT(VARCHAR(256),AJ_proteinCollectionList)           AS ProteinCollectionList,
		  CONVERT(VARCHAR(256),AJ_proteinOptionsList)              AS ProteinOptions,
		  CONVERT(VARCHAR(256),IN_class)                           AS InstClass,
		  CONVERT(VARCHAR(256),raw_data_type)                      AS RawDataType,
		  CONVERT(VARCHAR(256),AJT_searchEngineInputFileFormats)   AS SearchEngineInputFileFormats,
		  CONVERT(VARCHAR(256),OG_name)                            AS OrganismName,
		  CONVERT(VARCHAR(256),AJT_orgDbReqd)                      AS OrgDbReqd,
		  CONVERT(VARCHAR(256),AJT_toolName)                       AS ToolName
		FROM
		(
		SELECT 
		  DS.Dataset_Num,
		  DS.DS_folder_name,
		  ArchPath.AP_network_share_path,
		  AJ.AJ_parmFileName,
		  AJ.AJ_settingsFileName,
		  Tool.AJT_parmFileStoragePath,
		  AJ.AJ_organismDBName,
		  AJ.AJ_proteinCollectionList,
		  AJ.AJ_proteinOptionsList,
		  Inst.IN_class,
		  InstClass.raw_data_type,
		  Tool.AJT_searchEngineInputFileFormats,
		  Org.OG_name,
		  Tool.AJT_orgDbReqd,
		  Tool.AJT_toolName,
		  DS.Dataset_ID,
		  SP.SP_vol_name_client + SP.SP_path AS DatasetStoragePathLocal,
		  SP.SP_vol_name_client + (SELECT 
									Client
								   FROM   
									dbo.T_MiscPaths
								   WHERE  ([Function] = 'AnalysisXfer')) AS transferFolderPath
		FROM   
		  dbo.T_Analysis_Job AS AJ
		  INNER JOIN dbo.T_Dataset AS DS
			ON AJ.AJ_datasetID = DS.Dataset_ID
		  INNER JOIN dbo.T_Organisms AS Org
			ON AJ.AJ_organismID = Org.Organism_ID
		  INNER JOIN dbo.t_storage_path AS SP
			ON DS.DS_storage_path_ID = SP.SP_path_ID
		  INNER JOIN dbo.T_Analysis_Tool AS Tool
			ON AJ.AJ_analysisToolID = Tool.AJT_toolID
		  INNER JOIN dbo.T_Instrument_Name AS Inst
			ON DS.DS_instrument_name_ID = Inst.Instrument_ID
		  INNER JOIN dbo.T_Instrument_Class AS InstClass
			ON Inst.IN_class = InstClass.IN_class
		  INNER JOIN dbo.T_Dataset_Archive AS DSArch
			ON DS.Dataset_ID = DSArch.AS_Dataset_ID
		  INNER JOIN dbo.T_Archive_Path AS ArchPath
			ON DSArch.AS_storage_path_ID = ArchPath.AP_path_ID
		WHERE AJ.AJ_jobID = @job
		) TA
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
		ParmFileStoragePath,
		legacyFastaFileName,
		ProteinCollectionList,
		ProteinOptions,
		InstClass,
		RawDataType,
		SearchEngineInputFileFormats,
		OrganismName,
		OrgDbReqd,
		ToolName
	)) as TP
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

  	---------------------------------------------------
	-- Simulate section association for step tool
	---------------------------------------------------
	-- FUTURE: Do tool also <section name="Search" tool="Sequest" category="basic">'
	--
	UPDATE @paramTab
	SET [Section] = 'PeptideSearch'
	WHERE [Name] in ('ParmFileName', 'ParmFileStoragePath', 'OrganismName',  'legacyFastaFileName',  'ProteinCollectionList',  'ProteinOptions')

  	---------------------------------------------------
	-- Get settings file parameters from DMS
	---------------------------------------------------
	--
	declare @paramXML xml
	declare @settingsFileName varchar(128)
	
	set @settingsFileName = ''
	SELECT @settingsFileName =  [Value] FROM @paramTab WHERE [Name] = 'SettingsFileName'
	--
	SELECT @paramXML = Contents FROM T_Settings_Files WHERE File_Name = @settingsFileName

/* -- alternate way to extract XML into rowset
	DECLARE @hDoc int
	--
	--
	EXEC sp_xml_preparedocument @hDoc OUTPUT, @paramXML
	--
	INSERT INTO @paramTab
	SELECT * FROM OPENXML(@hDoc, N'//item', 2) 
	with (
		[Step_Number] varchar(22) '../@id', 
		[Section] varchar(22) '../@name', 
		[Name] varchar(64) '@key' , 
		[Value] varchar(512) '@value' 
	)
	--
	EXEC sp_xml_removedocument @hDoc
*/
	INSERT INTO @paramTab
	SELECT 
		xmlNode.value('../@id', 'nvarchar(50)') [Step_Number],
		xmlNode.value('../@name', 'nvarchar(50)') [Section],
		xmlNode.value('@key', 'nvarchar(50)') [Name], 
		xmlNode.value('@value', 'nvarchar(50)') [Value]
	FROM   @paramXML.nodes('//item') AS R(xmlNode)

	

  	---------------------------------------------------
	-- Backfill any missing parameters from global set
	---------------------------------------------------
	--
	set @settingsFileName = 'global_defaults'
	--
	SELECT @paramXML = Contents FROM T_Settings_Files WHERE File_Name = @settingsFileName

/* -- alternate way to extract XML into rowset
	EXEC sp_xml_preparedocument @hDoc OUTPUT, @paramXML
	--
	INSERT INTO @paramTab
	SELECT NULL as Step_Number, * FROM OPENXML(@hDoc, N'//item', 2) 
	with (
		[Section] varchar(22) '../@name', 
		[Name] varchar(64) '@key' , 
		[Value] varchar(512) '@value' 
	) XT WHERE NOT EXISTS (
		SELECT * FROM @paramTab PT 
		WHERE 
			XT.[Section] = PT.[Section] AND 
			XT.[Name] = PT.[Name]
	)
	--
	EXEC sp_xml_removedocument @hDoc
*/
	INSERT INTO @paramTab
	SELECT * FROM
	(
	SELECT 
		xmlNode.value('../@id', 'nvarchar(50)') [Step_Number],
		xmlNode.value('../@name', 'nvarchar(50)') [Section],
		xmlNode.value('@key', 'nvarchar(50)') [Name], 
		xmlNode.value('@value', 'nvarchar(50)') [Value]
	FROM   @paramXML.nodes('//item') AS R(xmlNode)
	) VG
	WHERE NOT EXISTS
	(
		SELECT *
		FROM   
			@paramTab VS
		WHERE 
			VS.Section = VG.Section AND VS.Name = VG.Name
	)


	select @job, * from @paramTab
	order by [Section]

	RETURN

GO

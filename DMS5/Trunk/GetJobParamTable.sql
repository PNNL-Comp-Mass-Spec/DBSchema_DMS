/****** Object:  StoredProcedure [dbo].[GetJobParamTable] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetJobParamTable
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
**	Auth:	grk
**	Date:	08/21/2008
**			01/14/2009 mem - Increased maximum parameter length to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**			04/10/2009 grk - Added DTA folder name override (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
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
		[Value] Varchar(2000)
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
		  CONVERT(VarChar(2000),Dataset_Num)                        AS DatasetNum,
		  CONVERT(VarChar(2000),Dataset_ID )                        AS DatasetID,
		  CONVERT(VarChar(2000),DS_folder_name)                     AS DatasetFolderName,
		  CONVERT(VarChar(2000),AP_network_share_path)              AS DatasetArchivePath,
		  CONVERT(VarChar(2000),DatasetStoragePathLocal)            AS DatasetStoragePath,
		  CONVERT(VarChar(2000),transferFolderPath)                 AS transferFolderPath,
		  CONVERT(VarChar(2000),AJ_parmFileName)                    AS ParmFileName,
		  CONVERT(VarChar(2000),AJ_settingsFileName)                AS SettingsFileName,
		  CONVERT(VarChar(2000),AJT_parmFileStoragePath)            AS ParmFileStoragePath,
		  CONVERT(VarChar(2000),AJ_organismDBName)                  AS legacyFastaFileName,
		  CONVERT(VarChar(2000),AJ_proteinCollectionList)           AS ProteinCollectionList,
		  CONVERT(VarChar(2000),AJ_proteinOptionsList)              AS ProteinOptions,
		  CONVERT(VarChar(2000),IN_class)                           AS InstClass,
		  CONVERT(VarChar(2000),raw_data_type)                      AS RawDataType,
		  CONVERT(VarChar(2000),AJT_searchEngineInputFileFormats)   AS SearchEngineInputFileFormats,
		  CONVERT(VarChar(2000),OG_name)                            AS OrganismName,
		  CONVERT(VarChar(2000),AJT_orgDbReqd)                      AS OrgDbReqd,
		  CONVERT(VarChar(2000),AJT_toolName)                       AS ToolName,
		  CONVERT(VarChar(2000),AJT_resultType)                     AS ResultType
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
		  Tool.AJT_resultType,
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
		[Section] varchar(128) '../@name', 
		[Name] varchar(128) '@key' , 
		[Value] varchar(4000) '@value' 
	)
	--
	EXEC sp_xml_removedocument @hDoc
*/
	INSERT INTO @paramTab
	SELECT 
		xmlNode.value('../@id', 'nvarchar(50)') [Step_Number],
		xmlNode.value('../@name', 'nvarchar(256)') [Section],
		xmlNode.value('@key', 'nvarchar(256)') [Name], 
		xmlNode.value('@value', 'nvarchar(4000)') [Value]
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
		[Name] varchar(128) '@key' , 
		[Value] varchar(4000) '@value' 
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
		xmlNode.value('../@name', 'nvarchar(256)') [Section],
		xmlNode.value('@key', 'nvarchar(256)') [Name], 
		xmlNode.value('@value', 'nvarchar(2000)') [Value]
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

  	---------------------------------------------------
	-- Look in the comment field for an for a tagged
	-- value representing an external DTA folder name.
	-- If one is found, override the external DTA folder 
	-- that is defined in the settings file, if one is
	-- present
	---------------------------------------------------
	--
	if exists (SELECT * FROM @paramTab WHERE [Name] = 'ExternalDTAFolderName')
	begin
		declare @extDTA varchar(128)
		set @extDTA = ''
		SELECT @extDTA = dbo.ExtractTaggedName('DTA:', AJ_comment) 
		FROM T_Analysis_Job 
		WHERE AJ_jobID = @job
		--
		if @extDTA <> ''
		begin
			UPDATE @paramTab
			SET [Value] = @extDTA
			WHERE [Name] = 'ExternalDTAFolderName'
		end
	end

  	---------------------------------------------------
	-- output the table of parameters
	---------------------------------------------------

	select @job, * from @paramTab
	order by [Section]

	RETURN

GO
GRANT VIEW DEFINITION ON [dbo].[GetJobParamTable] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetJobParamTable] TO [PNL\D3M580] AS [dbo]
GO

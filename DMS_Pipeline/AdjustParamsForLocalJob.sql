/****** Object:  StoredProcedure [dbo].[AdjustParamsForLocalJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AdjustParamsForLocalJob]
/****************************************************
**
**	Desc: 
**    Create analysis job directly in broker database 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			10/16/2010 grk - Initial release
**			01/19/2012 mem - Added parameter @DataPackageID
**			01/03/2014 grk - added logic for CacheFolderRootPath
**
*****************************************************/
(
	@scriptName varchar(64),
    @datasetNum varchar(128) = 'na',
	@DataPackageID int,
	@jobParamXML xml output, 
	@message varchar(512) OUTPUT 
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0
	
	DECLARE @changed TINYINT = 0
	
	Set @DataPackageID = IsNull(@DataPackageID, 0)

	---------------------------------------------------
	-- convert job params from XML to temp table
	---------------------------------------------------
	CREATE TABLE #PARAMS (
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(max)
	)

	INSERT INTO #PARAMS
			(Name, Value, Section)
	select
			xmlNode.value('@Name', 'nvarchar(256)') [Name],
			xmlNode.value('@Value', 'nvarchar(256)') VALUE,
			xmlNode.value('@Section', 'nvarchar(256)') [Section]
	FROM @jobParamXML.nodes('//Param') AS R(xmlNode)
	
	
	---------------------------------------------------
	-- do processing for certain parameters
	---------------------------------------------------
	DECLARE @id int
	DECLARE @path VARCHAR(260) = ''
	DECLARE @dataPkgName VARCHAR(128) = ''
	DECLARE @dataPkgSharePath VARCHAR(260) = ''
	DECLARE @xferPath VARCHAR(260) = ''

	---------------------------------------------------
	-- get data package info (if one is specified)
	---------------------------------------------------
	IF @DataPackageID <> 0 
	BEGIN 
		SELECT 
			@dataPkgSharePath = [Share Path],
			@dataPkgName = Name
		FROM S_Data_Package_Details 
		WHERE ID = @DataPackageID
	END 
		
	---------------------------------------------------
	-- is there a repo cache root folder path defined for job?
	---------------------------------------------------
	
	DECLARE @cacheFolderPath VARCHAR(260) = ''
	--
	DECLARE @cacheRootFolderPath VARCHAR(260) = ''
	SELECT @cacheRootFolderPath = Value
	FROM #PARAMS
	WHERE Name = 'CacheFolderRootPath'
	--
	
	---------------------------------------------------
	-- adjust path parameter if @DataPackageID > 0
	---------------------------------------------------
	--
	--
	IF @DataPackageID <> 0
	BEGIN 
		IF IsNull(@cacheRootFolderPath, '') = '' 
		BEGIN
			SET @xferPath = @dataPkgSharePath
		END
		ELSE
		BEGIN
			SET @cacheFolderPath = @cacheRootFolderPath + '\' + CONVERT(VARCHAR(12), @DataPackageID) + '_' + REPLACE(@dataPkgName, ' ', '_')
			SET @xferPath = @cacheRootFolderPath
			--
			DELETE FROM #PARAMS
			WHERE Name = 'CacheFolderPath'
			--
			INSERT INTO #PARAMS
				( Section, Name, Value )
			VALUES    
				( 'JobParameters', 'CacheFolderPath', @cacheFolderPath )
		END
		--
		DELETE FROM #PARAMS
		WHERE Name = 'transferFolderPath'
		--
		INSERT INTO #PARAMS
			( Section, Name, Value )
		VALUES    
			( 'JobParameters', 'transferFolderPath', @xferPath )
		--
		SET @changed = 1
	END 
	
	
	---------------------------------------------------
	-- add path to source job
	---------------------------------------------------
	Set @id = 0
	--
	SELECT @id = Value FROM #PARAMS WHERE Name = 'sourceJob'
	--
	IF @id <> 0
	BEGIN 
		-- PRINT 'sourceJob:' + CONVERT(VARCHAR(12), @id)
		-- look up path to results folder for job given by @id and add it to temp parameters table
		DECLARE @dataset VARCHAR(128) = ''
		DECLARE @rawDataType VARCHAR(128) = ''
		DECLARE @sourceResultsFolder VARCHAR(128) = ''
		DECLARE @datasetStoragePath VARCHAR(260) = ''
		DECLARE @transferFolderPath VARCHAR(260) = ''

		--
		SELECT @path = [Archive Folder Path],
		       @dataset = Dataset,
		       @datasetStoragePath = [Dataset Storage Path],
		       @rawDataType = RawDataType,
		       @sourceResultsFolder = [Results Folder],
		       @transferFolderPath = transferFolderPath
		FROM S_DMS_V_Analysis_Job_Info
		WHERE Job = @id
		
		
		IF @dataset <> ''
		BEGIN		
			-- UPDATE Input_Folder_Name for job steps
			-- (in the future, we may want to be more selective about which steps are not updated)
			UPDATE #Job_Steps
			SET Input_Folder_Name = @sourceResultsFolder
			WHERE NOT Step_Tool IN ('Results_Transfer')
		END
		
		IF @dataset <> ''
		BEGIN
			DELETE FROM #PARAMS
			WHERE Name IN ('DatasetArchivePath',
			               'DatasetNum',
			               'RawDataType', 
			               'DatasetStoragePath', 
			               'transferFolderPath', 
			               'DatasetFolderName')
			--
						
			INSERT INTO #PARAMS ( Section, Name, Value )
			SELECT 'JobParameters', 'DatasetArchivePath', @path
			UNION
			SELECT 'JobParameters', 'DatasetNum', @dataset
			UNION
			SELECT 'JobParameters', 'RawDataType', @rawDataType
			UNION
			SELECT 'JobParameters', 'DatasetStoragePath', @datasetStoragePath
			UNION
			SELECT 'JobParameters', 'transferFolderPath', @transferFolderPath
			UNION
			SELECT 'JobParameters', 'DatasetFolderName', @dataset
			
			SET @changed = 1
		END 
	END 
		

	---------------------------------------------------
	-- convert job params from temp table to XML, 
	-- if there were changes made
	---------------------------------------------------
	IF @changed <> 0
	BEGIN 
		SET @jobParamXML = ( SELECT * FROM #PARAMS AS Param FOR XML AUTO, TYPE)
	END


GO
GRANT VIEW DEFINITION ON [dbo].[AdjustParamsForLocalJob] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[MakePrepLCCaptureJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakePrepLCCaptureJob
/****************************************************
**
**	Desc: 
**    Create capture job directly in broker database 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			05/08/2010 grk - Initial release
**			05/22/2010 grk - added capture method
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**
*****************************************************/
(
	@ID INT,
	@instrument VARCHAR(128),
	@SourceFolderName VARCHAR(128),
	@Comment varchar(512),
	@Job int OUTPUT,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	DECLARE @priority int
	SET @priority = 1

	declare @DebugMode tinyint
	SET @DebugMode = 0

	BEGIN TRY

	---------------------------------------------------
	-- get canonical name for storage folder
	---------------------------------------------------
	--
	DECLARE @storageFolderName VARCHAR(128)
	SET @storageFolderName = dbo.S_GetDMSFileStoragePath('', @ID, 'prep_lc')

	---------------------------------------------------
	-- Table variable to hold job parameters
	---------------------------------------------------
	--
	DECLARE @paramTab TABLE
    (
      [Section] VARCHAR(128),
      [Name] VARCHAR(128),
      [Value] VARCHAR(2000)
    )

	---------------------------------------------------
	-- remember prep LC run ID
	---------------------------------------------------
	--
	INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'ID', @ID)


	---------------------------------------------------
	-- get prep LC parameters into temp table
	---------------------------------------------------
	--
	INSERT INTO @paramTab
	SELECT
	  'JobParameters' AS [Section],
	  TP.Name,
	  TP.Value
	FROM
	  ( SELECT
		  CONVERT(VARCHAR(2000), Instrument) AS Instrument_Name,
		  CONVERT(VARCHAR(2000), Capture_Method) AS Method,
		  CONVERT(VARCHAR(2000), sourceVol) AS Source_Vol,
		  CONVERT(VARCHAR(2000), sourcePath) AS Source_Path,
		  CONVERT(VARCHAR(2000), Storage_Vol) AS Storage_Vol,
		  CONVERT(VARCHAR(2000), Storage_Path) AS Storage_Path,
		  CONVERT(VARCHAR(2000), Storage_Vol_External) AS Storage_Vol_External,
		  CONVERT(VARCHAR(2000), Storage_Path_ID) AS Storage_Path_ID
		FROM
			V_DMS_PrepLC_Job_Parameters
		WHERE
			ID = @ID
	  ) TD UNPIVOT ( Value FOR [Name] IN ( Instrument_Name, Method, Source_Vol, Source_Path, Storage_Vol, Storage_Path, Storage_Vol_External, Storage_Path_ID
	) ) as TP

	---------------------------------------------------
	-- add source and storage folders to temp table
	---------------------------------------------------
	--
	INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'Source_Folder_Name', @SourceFolderName)
	INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'Storage_Folder_Name', @storageFolderName)
		
	---------------------------------------------------
	-- get xml for contents of temp table
	---------------------------------------------------
	DECLARE @jobParamXML xml
	--
	SET @jobParamXML = (SELECT * FROM @paramTab Param ORDER BY [Name], [Value] FOR XML AUTO )

	---------------------------------------------------
	-- create the job (or dump debug information)
	---------------------------------------------------
	IF @DebugMode = 0
	BEGIN 
		declare @scriptName varchar(64)
		SET @scriptName = 'HPLCSequenceCapture'
		--
		DECLARE @resultsFolderName varchar(128)
		/**/
		exec @myError = MakeLocalJobInBroker
					@scriptName,
					@priority,
					@jobParamXML,
					@Comment,
					@DebugMode,	
					@Job OUTPUT,
					@resultsFolderName OUTPUT,
					@message output
	END 
	ELSE IF @DebugMode = 1
	BEGIN 
		PRINT CONVERT(VARCHAR(max), @jobParamXML)
	END
	ELSE IF @DebugMode = 2
	BEGIN 
		SET @Job = 666
	END

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		Exec PostLogEntry 'Error', @message, 'MakePrepLCCaptureJob'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[MakePrepLCCaptureJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MakePrepLCCaptureJob] TO [DMS_SP_User] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[AddMACJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddMACJob
/****************************************************
**
**  Desc: 
**  Add a MAC job from job template 
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	10/27/2012 grk - Initial release
**			11/01/2012 grk - eliminated job template
**			12/11/2012 jds - added DataPackageID to MapMACJobParameters
**			01/11/2013 mem - Now aborting if MapMACJobParameters returns an error code
**			04/10/2013 mem - Now passing @callingUser to MakeLocalJobInBroker
**			02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
	@job int OUTPUT,
	@DataPackageID int,
	@jobParam VARCHAR(8000),
	@comment VARCHAR(512),
	@ownerPRN VARCHAR(64),
	@scriptName VARCHAR(64),
	@mode VARCHAR(12) = 'add', 
	@message VARCHAR(512) output,
	@callingUser VARCHAR(128) = ''
)
AS
	Set XACT_ABORT, nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0

	Set @DataPackageID = IsNull(@DataPackageID, 0)
	
	DECLARE @DebugMode tinyint = 0

	BEGIN TRY                
		---------------------------------------------------
		-- does data package exist?
		---------------------------------------------------
		
		DECLARE 
			@pkgName VARCHAR(128),
			@pkgJobCount int			
						   
		SELECT    
			@pkgName = Name ,
			@pkgJobCount = [Analysis Job Item Count]
		FROM S_Data_Package_Details TPKG
		WHERE TPKG.ID = @DataPackageID
		
		IF @pkgName IS Null
				RAISERROR('Data package does not exist', 11, 20)
	 
		IF @pkgJobCount = 0	 			
				RAISERROR('Data package has no analysis jobs', 11, 21)
												
		---------------------------------------------------
		-- get script
		---------------------------------------------------
		
		DECLARE 
			@scriptId int,
			@scriptEnabled char(1),
			@scriptParameters xml  

		SELECT 
			@scriptId = ID, 
			@scriptEnabled = Enabled, 
			@scriptParameters = Parameters 
		FROM T_Scripts	
		WHERE Script = @scriptName
		
		IF @scriptID IS NULL
			 RAISERROR('Scrit "%s" could not be found', 11, 22, @scriptName)
		
		IF @scriptEnabled = 'N'
			 RAISERROR('Script "%s" is not enabled', 11, 23, @scriptName)

		---------------------------------------------------
		-- is data package set up correctly for the job?
		---------------------------------------------------
		
		DECLARE 
			@tool VARCHAR(64) = '',			-- PSM analysis tool used by jobs in the data package; only used by scripts 'Isobaric_Labeling' and 'MAC_iTRAQ'
			@msg VARCHAR(512) = '',	                 
			@valid INT = 0

		EXEC @valid = dbo.ValidateDataPackageForMACJob
								@DataPackageID,
								@scriptName,						
								@tool output,
								'validate', 
								@msg output
		IF @valid <> 0
			RAISERROR('%s', 11, 24, @msg)
		
		---------------------------------------------------
		-- get default job parameters from script
		---------------------------------------------------

		CREATE TABLE  #MACJobParams  (
			[Section] varchar(64),
			[Name] varchar(128),
			[Value] varchar(4000),
			Reqd VARCHAR(6) NULL,
			Step varchar(6) NULL
		)

		INSERT INTO #MACJobParams
			([Section], [Name], Value, Reqd, Step)
		SELECT 
			xmlNode.value('@Section', 'varchar(64)') as [Section],
			xmlNode.value('@Name', 'varchar(64)') as [Name],
			xmlNode.value('@Value', 'varchar(4000)') as [Value],
			xmlNode.value('@Reqd', 'varchar(6)') as [Reqd],
			xmlNode.value('@Step', 'varchar(6)') as [Step]
		FROM
			@scriptParameters.nodes('//Param') AS R(xmlNode)

		---------------------------------------------------
		-- parameter overrides for job
		-- (directly modifies #MACJobParams)
		---------------------------------------------------
		
		DECLARE @result INT = 0
		SET @msg = ''		
		
		EXEC @result = MapMACJobParameters
						@scriptName,				
						@jobParam,
						@tool,  
						@DataPackageID,  
						'map',					   
						@msg output
		
		if @result <> 0
			RAISERROR(@msg, 11, 25)
						
		---------------------------------------------------
		-- build final job param XML for creating job
		---------------------------------------------------
		
		DECLARE @jobParamXML XML
		SELECT @jobParamXML = ( 
				SELECT [Section],
					[Name],
					[Value],
					[Reqd],
					[Step]
				FROM #MACJobParams Param
				ORDER BY [Section]
				FOR XML AUTO )
		
		IF @mode = 'debug'	
		BEGIN --<debug>
			DECLARE @s VARCHAR(8000) = convert(varchar(8000), @jobParamXML)
			PRINT 	@s	 
			
			SELECT * FROM #MACJobParams
									
		END --<debug>               

		---------------------------------------------------
		-- add mode
		---------------------------------------------------

		IF @mode = 'add'
		BEGIN --<add>

			DECLARE 
					@datasetNum VARCHAR(256) = 'Aggregation',
					@priority int = 3,
					@resultsFolderName VARCHAR(256)
						
--			DECLARE @x VARCHAR(8000) = 	'<code>' + CONVERT(varchar(8000), @jobParamXML) + '</code>'		                                                                     
--			RAISERROR('Debug:%s', 11, 42, @x)
--			RAISERROR('Debug:%s', 11, 42, 'The call to "MakeLocalJobInBroker" is temporarily disabled')
							 
			exec MakeLocalJobInBroker
					@scriptName,
					@datasetNum,
					@priority,
					@jobParamXML,
					@comment,
					@ownerPRN,
					@DataPackageID,
					@DebugMode,
					@job OUTPUT,
					@resultsFolderName OUTPUT,
					@message output,
					@callingUser

		END --<add>

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddMACJob] TO [DMS_SP_User] AS [dbo]
GO

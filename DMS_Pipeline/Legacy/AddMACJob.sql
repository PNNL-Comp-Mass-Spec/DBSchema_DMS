/****** Object:  StoredProcedure [dbo].[AddMACJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddMACJob]
/****************************************************
**
**  Desc: 
**      Add a MAC job from job template; used by the mac_jobs page family on the DMS website
**
**      Deprecated in December 2022 when the mac_jobs page family was deprecated,
**      since superseded by https://dms2.pnl.gov/pipeline_jobs/create
**	
**  Return values: 0: success, otherwise, error code
**
**  Auth:	grk
**  Date:	10/27/2012 grk - Initial release
**			11/01/2012 grk - eliminated job template
**			12/11/2012 jds - added DataPackageID to MapMACJobParameters
**			01/11/2013 mem - Now aborting if MapMACJobParameters returns an error code
**			04/10/2013 mem - Now passing @callingUser to MakeLocalJobInBroker
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**			11/15/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          03/09/2021 mem - Rename variable
**
*****************************************************/
(
	@job int OUTPUT,
	@DataPackageID int,
	@jobParam varchar(8000),
	@comment varchar(512),
	@ownerPRN varchar(64),
	@scriptName varchar(64),
	@mode varchar(12) = 'add', 
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
AS
	Set XACT_ABORT, nocount on
	
	Declare @myError int = 0
	Declare @myRowCount int = 0

	Set @DataPackageID = IsNull(@DataPackageID, 0)
	
	Declare @DebugMode tinyint = 0
	Declare @logErrors tinyint = 1
    Declare @result int = 0

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddMACJob', @raiseError = 1;
	If @authorized = 0
	Begin;
		THROW 51000, 'Access denied', 1;
	End;

	Begin TRY

		---------------------------------------------------
		-- Does data package exist?
		---------------------------------------------------
		
		Declare 
			@pkgName varchar(128),
			@pkgJobCount int			
						   
		SELECT    
			@pkgName = Name ,
			@pkgJobCount = [Analysis Job Item Count]
		FROM S_Data_Package_Details TPKG
		WHERE TPKG.ID = @DataPackageID
		
		If @pkgName IS Null
			RAISERROR('Data package does not exist', 11, 20)
	 
		If @pkgJobCount = 0	 			
			RAISERROR('Data package has no analysis jobs', 11, 21)
											
		---------------------------------------------------
		-- Get script
		---------------------------------------------------
		
		Declare 
			@scriptId int,
			@scriptEnabled char(1),
			@scriptParameters xml  

		SELECT 
			@scriptId = ID, 
			@scriptEnabled = Enabled, 
			@scriptParameters = Parameters 
		FROM T_Scripts	
		WHERE Script = @scriptName
		
		If @scriptID IS NULL
			 RAISERROR('Script "%s" could not be found', 11, 22, @scriptName)
		
		If @scriptEnabled = 'N'
			 RAISERROR('Script "%s" is not enabled', 11, 23, @scriptName)

		---------------------------------------------------
		-- Is data package set up correctly for the job?
		---------------------------------------------------
		
		Declare 
			@tool varchar(64) = '',			-- PSM analysis tool used by jobs in the data package; only used by scripts 'Isobaric_Labeling' and 'MAC_iTRAQ'
			@msg varchar(512) = ''

		EXEC @result = dbo.ValidateDataPackageForMACJob
								@DataPackageID,
								@scriptName,						
								@tool output,
								'validate', 
								@msg output

		If @result <> 0
		Begin
			-- Change @logErrors to 0 since the error was already logged to T_Log_Entries by ValidateDataPackageForMACJob
			Set @logErrors = 0
			
			RAISERROR('%s', 11, 24, @msg)
		End
		
		---------------------------------------------------
		-- Get default job parameters from script
		---------------------------------------------------

		CREATE TABLE  #MACJobParams  (
			[Section] varchar(64),
			[Name] varchar(128),
			[Value] varchar(4000),
			Reqd varchar(6) NULL,
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
		-- Parameter overrides for job
		-- (directly modifies #MACJobParams)
        --
        -- @jobParam should be of the form:
        -- <Param Name="Experiment_Labelling" Value="8plex" /><Param Name="Ape_Workflow_FDR" Value="default" />
		---------------------------------------------------
		
		Set @result = 0

		Set @msg = ''		
		
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
		-- Build final job param XML for creating job
        --
        -- Example XML in @jobParamXML:
        --   <Param Section="1_AScore" Name="AScoreParamFilename" Value="" Reqd="No" Step="1"/>
        --   <Param Section="1_AScore" Name="AScoreSearchType" Value="msgfplus" Reqd="No" Step="1"/>
        --   <Param Section="1_AScore" Name="ExtractionType" Value="MSGF+ Synopsis All Proteins" Reqd="No" Step="1"/>
        --   <Param Section="2_Mage" Name="MageOperations" Value="GetFactors, ImportDataPackageFiles, ImportRawFileList, ImportJobList, GetFDRTables, ExtractFromJobs, ImportReporterIons" Reqd="Yes" Step="2"/>
        --   <Param Section="2_Mage" Name="DataPackageSourceFolderName" Value="ImportFiles" Reqd="Yes" Step="2"/>
        --   <Param Section="2_Mage" Name="ExtractionSource" Value="JobsFromDataPackageID" Reqd="Yes" Step="2"/>
        --   <Param Section="2_Mage" Name="ExtractionType" Value="MSGF+ Synopsis All Proteins" Reqd="No" Step="2"/>
        --   <Param Section="2_Mage" Name="KeepAllResults" Value="Yes" Reqd="No" Step="2"/>
        --   <Param Section="2_Mage" Name="MSGFcutoff" Value="All Pass" Reqd="No" Step="2"/>
        --   <Param Section="2_Mage" Name="ResultFilterSetID" Value="All Pass" Reqd="No" Step="2"/>
        --   <Param Section="2_Mage" Name="FactorsSource" Value="FactorsFromDataPackageID" Reqd="Yes" Step="2"/>
        --   <Param Section="2_Mage" Name="ReporterIonSource" Value="JobsFromDataPackageIDForTool" Reqd="Yes" Step="2"/>
        --   <Param Section="2_Mage" Name="MageFDRFiles" Value="t_iteration1.txt, t_iteration2_1.txt" Reqd="No" Step="2"/>
        --   <Param Section="4_Ape" Name="ApeOperations" Value="RunWorkflow" Reqd="Yes" Step="4"/>
        --   <Param Section="4_Ape" Name="ApeWorkflowName" Value="MasterWorkflowSyn.xml" Reqd="Yes" Step="4"/>
        --   <Param Section="4_Ape" Name="ApeWorkflowStepList" Value="msgfplus, 8plex, 1pctFDR, default, no_ascore, no_precursor_filter, keep_nonquant" Reqd="Yes" Step="4"/>
        --   <Param Section="4_Ape" Name="ApeCompactDatabase" Value="True" Reqd="Yes" Step="4"/>
        --   <Param Section="5_Cyclops" Name="CyclopsWorkflowName" Value="ITQ_ExportOperation.xml" Reqd="Yes" Step="5"/>
        --   <Param Section="5_Cyclops" Name="RunProteinProphet" Value="False" Reqd="Yes" Step="5"/>
        --   <Param Section="5_Cyclops" Name="Consolidation_Factor" Value="" Reqd="No" Step="5"/>
        --   <Param Section="5_Cyclops" Name="Fixed_Effect" Value="" Reqd="No" Step="5"/>
        --   <Param Section="JobParameters" Name="transferFolderPath" Value=""/>
        --   <Param Section="JobParameters" Name="AnalysisType" Value="iTRAQ" Reqd="Yes"/>
        --   <Param Section="JobParameters" Name="ResultsBaseName" Value="Results" Reqd="Yes"/>
		---------------------------------------------------
		
		Declare @jobParamXML XML
		SELECT @jobParamXML = ( 
				SELECT [Section],
					[Name],
					[Value],
					[Reqd],
					[Step]
				FROM #MACJobParams Param
				ORDER BY [Section]
				FOR XML AUTO )

		If @mode = 'debug'	
		Begin -- <debug>

            Declare @s varchar(8000)

            Set @s = '@jobParam: ' + @jobParam
			Print @s	 

            -- Uncomment to log the contents of @jobParam
            -- Exec PostLogEntry 'Debug', @s, 'AddMACJob'		

            Set @s = 'XML: ' + convert(varchar(8000), @jobParamXML)
			Print @s	 

            -- Uncomment to log the contents of @jobParamXML
            -- Exec PostLogEntry 'Debug', @s, 'AddMACJob'		
			
			SELECT * FROM #MACJobParams
									
		End -- </debug>               

		---------------------------------------------------
		-- Add mode
		---------------------------------------------------

		If @mode = 'add'
		Begin -- <add>

			Declare 
					@datasetNum varchar(256) = 'Aggregation',
					@priority int = 3,
					@resultsFolderName varchar(256)
						
--			Declare @x varchar(8000) = 	'<code>' + CONVERT(varchar(8000), @jobParamXML) + '</code>'		                                                                     
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

		End -- </add>

	End TRY
	Begin CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		If @logErrors > 0
		Begin
			Exec PostLogEntry 'Error', @message, 'AddMACJob'		
		End
	End CATCH

Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddMACJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddMACJob] TO [DMS_SP_User] AS [dbo]
GO

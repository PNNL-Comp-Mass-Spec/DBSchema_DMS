/****** Object:  StoredProcedure [dbo].[MakePhosphoFdrAggregateRequestJobInBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[MakePhosphoFdrAggregateRequestJobInBroker]
/****************************************************
**
**	Desc: 
**    Create phosphoproteomics AScore job directly in broker database 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			06/02/2010 jds - Initial release
**			08/25/2010 jds - Added @targetFileSpecs as a parameter
*****************************************************/
(
	@DataPackageID INT,
	@AScoreHCDParamFile VARCHAR(128),
	@AScoreCIDParamFile VARCHAR(128),
	@AScoreETDParamFile VARCHAR(128),
	@Comment varchar(512),
	@Job int OUTPUT,
	@targetFileSpecs VARCHAR(512),
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
	
	declare @scriptName varchar(64)
	SET @scriptName = 'Phospho_FDR_Aggregator'

	DECLARE @datasetNum VARCHAR(128)
	SET @datasetNum = 'Aggregation'

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY
		---------------------------------------------------
		-- verify that package datasets have package jobs
		---------------------------------------------------
		DECLARE @hits INT
		SET @hits = 0
		--
		SELECT @hits = @hits + COUNT(*) FROM dbo.CheckDataPackageJobs(@DataPackageID, 'Sequest', 'DatasetsWithoutJobs')
		--
		IF @hits > 0
			RAISERROR('There were datasets in package that did not have associated jobs in package', 11, 12)

		---------------------------------------------------
		-- get canonical name for storage folder
		---------------------------------------------------
		--
		DECLARE @DataPackageDirectory VARCHAR(128)
		SET @DataPackageDirectory = ''
		--
	
		SELECT
			-- [Web Path], [Analysis Job Item Count], Name, [Package Type], Description, Comment, State,[Package File Folder]
			@DataPackageDirectory = [Share Path]
		FROM
			S_Data_Package_Details
		WHERE 
			ID = @DataPackageID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @myRowCount = 0
			RAISERROR('Could not find data package', 11, 14)
		
		IF @DataPackageDirectory = ''
			RAISERROR('Data package directory was blank', 11, 15)
			
		---------------------------------------------------
		-- target file specs
		---------------------------------------------------
		--
		--DECLARE @targetFileSpecs VARCHAR(512)
		--
		IF @targetFileSpecs = '' 
		    BEGIN
				SELECT
					@targetFileSpecs = Aggregation_Targets
				FROM
					T_Scripts
				WHERE
					Script = @scriptName
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				IF @myRowCount = 0
					RAISERROR('Could not get aggregation specs for script', 11, 16)
			END

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
		-- parameters
		---------------------------------------------------
		--
		INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'DataPackageID', @DataPackageID)
		INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'transferFolderPath', @DataPackageDirectory)
		INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'AScoreHCDParamFile', @AScoreHCDParamFile)
		INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'AScoreCIDParamFile', @AScoreCIDParamFile)
		INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'AScoreETDParamFile', @AScoreETDParamFile)
		INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'TargetJobFileList', @targetFileSpecs)
		INSERT INTO @paramTab ([Section], [Name], [Value]) VALUES ('JobParameters', 'DatasetNum', @datasetNum)

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
			--
			DECLARE @resultsFolderName varchar(128)
			--
			exec @myError = MakeLocalJobInBroker
								@scriptName,
								@datasetNum,
								@priority,
								@jobParamXML,
								@comment,
								@DebugMode,
								@job OUTPUT,
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

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

	END CATCH

	return @myError


GO
GRANT EXECUTE ON [dbo].[MakePhosphoFdrAggregateRequestJobInBroker] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakePhosphoFdrAggregateRequestJobInBroker] TO [Limited_Table_Write] AS [dbo]
GO

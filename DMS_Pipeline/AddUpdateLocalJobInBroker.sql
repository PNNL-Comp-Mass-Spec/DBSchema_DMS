/****** Object:  StoredProcedure [dbo].[AddUpdateLocalJobInBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateLocalJobInBroker
/****************************************************
**
**  Desc: 
**  Create or edit analysis job directly in broker database 
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	08/29/2010 grk - Initial release
**			08/31/2010 grk - reset job
**			10/06/2010 grk - check @jobParam against parameters for script
**			10/25/2010 grk - Removed creation prohibition all jobs except aggregation jobs
**			11/25/2010 mem - Added parameter @DebugMode
**			07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**			01/09/2012 mem - Added parameter @ownerPRN
**			01/19/2012 mem - Added parameter @DataPackageID
**			02/07/2012 mem - Now updating Transfer_Folder_Path after updating T_Job_Parameters
**			03/20/2012 mem - Now calling UpdateJobParamOrgDbInfoUsingDataPkg
**			03/07/2013 mem - Now calling ResetAggregationJob to reset jobs; supports resetting a job that succeeded
**						   - No longer changing job state to 20; ResetAggregationJob will update the job state
**
*****************************************************/
(
	@job int OUTPUT,
	@scriptName varchar(64),
	@datasetNum varchar(128) = 'na',
	@priority int,
	@jobParam varchar(8000),
	@comment varchar(512),
	@ownerPRN varchar(64),
	@DataPackageID int,
	@resultsFolderName varchar(128) OUTPUT,
	@mode varchar(12) = 'add', -- or 'update' or 'reset'
	@message varchar(512) output,
	@callingUser varchar(128) = '',
	@DebugMode tinyint = 0
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0
	
	Set @DataPackageID = IsNull(@DataPackageID, 0)
	
	DECLARE @reset CHAR(1) = 'N'
	IF @mode = 'reset'
	BEGIN 
		SET @mode = 'update'
		SET @reset = 'Y'
	END 

	BEGIN TRY

		---------------------------------------------------
		-- does job exist
		---------------------------------------------------
		
		DECLARE 
			@id INT = 0,
			@state int = 0
		--
		SELECT
			@id = Job ,
			@state = State
		FROM dbo.T_Jobs
		WHERE Job = @job
		
		IF @mode = 'update' AND @id = 0
			RAISERROR ('Cannot update nonexistent job', 11, 2)

		IF @mode = 'update' AND NOT @state IN (1, 4, 5) -- new, complete, failed
			RAISERROR ('Cannot update job in state %d', 11, 3, @state)

		IF @mode = 'update' AND @datasetNum <> 'Aggregation'
			RAISERROR ('Currently only aggregation jobs can be updated', 11, 4)
			
		---------------------------------------------------
		-- verify parameters
		---------------------------------------------------

		If @jobParam Is Null
			RAISERROR('Web page bug: @jobParam is null', 11, 30)

		If @jobParam = ''
			RAISERROR('Web page bug: @jobParam is empty', 11, 30)
		
		--Declare @DebugMessage varchar(4096) = 'Contents of @jobParam: ' + @jobParam			
		--exec PostLogEntry 'Debug', @DebugMessage, 'AddUpdateLocalJobInBroker'

		exec @myError = VerifyJobParameters @jobParam, @scriptName, @message output
		IF @myError > 0
			RAISERROR(@message, 11, @myError)

		---------------------------------------------------
		-- update mode 
		-- restricted to certain job states and limited to certain fields
		-- force reset of job?
		---------------------------------------------------
		
		IF @mode = 'update'
		BEGIN --<update>
			BEGIN TRANSACTION
			
			-- Update job and params
			--
			UPDATE   dbo.T_Jobs
			SET      Priority = @priority ,
					 Comment = @comment ,
					 Owner = @ownerPRN ,
					 DataPkgID = @DataPackageID
			WHERE    Job = @job
			
			UPDATE   dbo.T_Job_Parameters
			SET      Parameters = CONVERT(XML, @jobParam)
			WHERE    job = @job


			---------------------------------------------------
			-- Lookup the transfer folder path from the job parameters
			---------------------------------------------------
			--
			Declare @TransferFolderPath varchar(512) = ''
			
			SELECT @TransferFolderPath = [Value]
			FROM dbo.GetJobParamTableLocal ( @Job )
			WHERE [Name] = 'transferFolderPath'
			
			If IsNull(@TransferFolderPath, '') <> ''
				UPDATE T_Jobs
				SET Transfer_Folder_Path = @TransferFolderPath
				WHERE Job = @Job

			
			---------------------------------------------------
			-- If a data package is defined, then update entries for 
			-- OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList in T_Job_Parameters
			---------------------------------------------------
			--
			If @DataPackageID > 0
			Begin
				Exec UpdateJobParamOrgDbInfoUsingDataPkg @Job, @DataPackageID, @deleteIfInvalid=0, @message=@message output, @callingUser=@callingUser
			End
			
			
			IF @reset = 'Y'
			BEGIN --<reset>
			
				exec ResetAggregationJob @job, @InfoOnly=0, @message=@message output							
				
			END --<reset>

			COMMIT

		END --<update>
		

		---------------------------------------------------
		-- add mode
		---------------------------------------------------

		IF @mode = 'add'
		BEGIN --<add>

			DECLARE @jobParamXML XML = CONVERT(XML, @jobParam)
			
			if @DebugMode <> 0
				Print 'JobParamXML: ' + Convert(varchar(max), @jobParamXML)
				
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
					@message output

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
GRANT EXECUTE ON [dbo].[AddUpdateLocalJobInBroker] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLocalJobInBroker] TO [Limited_Table_Write] AS [dbo]
GO

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
			
			-- update job and params
			--
			UPDATE   dbo.T_Jobs
			SET      Priority = @priority ,
					 Comment = @comment ,
					 Owner = @ownerPRN ,
					 DataPkgID = @DataPackageID,
					 State = CASE WHEN @reset = 'Y' THEN 20 ELSE State END -- 20=resuming (UpdateJobState will handle final job state update)
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
				-- set any failed or holding job steps to waiting
				--
				UPDATE T_Job_Steps
				SET State = 1,					-- 1=waiting
				    Tool_Version_ID = 1			-- 1=Unknown
				WHERE
					State IN (6, 7) AND			-- 6=Failed, 7=Holding
					Job  = @job

				-- Reset the entries in T_Job_Step_Dependencies for any steps with state 1
				--
				UPDATE T_Job_Step_Dependencies
				SET Evaluated = 0,
					Triggered = 0
				FROM T_Job_Step_Dependencies JSD INNER JOIN
					T_Job_Steps JS ON 
					JSD.Job_ID = JS.Job AND 
					JSD.Step_Number = JS.Step_Number
				WHERE
					JS.State = 1 AND			-- 1=Waiting
					JS.Job  = @job
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

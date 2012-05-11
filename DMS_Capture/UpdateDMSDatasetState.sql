/****** Object:  StoredProcedure [dbo].[UpdateDMSDatasetState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDMSDatasetState
/****************************************************
**
**  Desc:
**  Update dataset state
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	01/05/2010 grk - Initial Veresion
**			01/14/2010 grk - removed path ID fields
**			05/05/2010 grk - added handling for dataset info XML
**			09/01/2010 mem - Now calling UpdateDMSFileInfoXML
**			03/16/2011 grk - Now recognizes IMSDatasetCapture
**			04/04/2012 mem - Now passing @FailureMessage to S_SetCaptureTaskComplete when the job is failed in the broker
**    
*****************************************************/
(
	@job INT,
	@datasetNum VARCHAR(128),
	@datasetID INT,
	@Script varchar(64),
	@storageServerName VARCHAR(128),
	@newJobStateInBroker int,
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Dataset Capture
	---------------------------------------------------
	--
	IF @Script = 'DatasetCapture' OR @Script = 'IMSDatasetCapture'
	BEGIN
		IF @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
		BEGIN 
			EXEC @myError = S_SetCaptureTaskBusy @datasetNum, '(broker)', @message output
		END

		IF @newJobStateInBroker = 3
		BEGIN 
			---------------------------------------------------
			-- Success
			---------------------------------------------------
			
			EXEC @myError = S_SetCaptureTaskComplete @datasetNum, 100, @message OUTPUT -- using special completion code of 100
			
			EXEC @myError = UpdateDMSFileInfoXML @DatasetID, @DeleteFromTableOnSuccess=1, @message=@message output
		END

		IF @newJobStateInBroker = 5
		BEGIN 
			---------------------------------------------------
			-- Failure
			---------------------------------------------------
			
			Declare @FailureMessage varchar(256)
			
			-- Look for any failure messages in T_Job_Steps for this job
			-- First check the Evaluation_Message column
			SELECT @FailureMessage = JS.Evaluation_Message
			FROM T_Job_Steps JS INNER JOIN
				T_Jobs J ON JS.Job = J.Job
			WHERE (JS.Job = @job) AND IsNull(JS.Evaluation_Message, '') <> ''

			If IsNull(@FailureMessage, '') = ''
			Begin
				-- Next check the Completion_Message column
				SELECT @FailureMessage = JS.Completion_Message
				FROM T_Job_Steps JS INNER JOIN
					T_Jobs J ON JS.Job = J.Job
				WHERE (JS.Job = @job) AND IsNull(JS.Completion_Message, '') <> ''
			End
			
			EXEC @myError = S_SetCaptureTaskComplete @datasetNum, 1, @message output, @FailureMessage=@FailureMessage
		END
	END

	---------------------------------------------------
	-- Dataset Archive
	---------------------------------------------------
	--
	IF @Script = 'DatasetArchive'
	BEGIN
		IF @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
		BEGIN 
			EXEC @myError = S_SetArchiveTaskBusy @datasetNum, @storageServerName, @message  output
		END

		IF @newJobStateInBroker = 3
		BEGIN 
			EXEC @myError = S_SetArchiveTaskComplete @datasetNum, 100, @message OUTPUT -- using special completion code of 100
		END

		IF @newJobStateInBroker = 5
		BEGIN 
			EXEC @myError = S_SetArchiveTaskComplete @datasetNum, 1, @message output
		END
	END

	---------------------------------------------------
	-- Archive Update
	---------------------------------------------------
	--
	IF @Script = 'ArchiveUpdate'
	BEGIN
		IF @newJobStateInBroker in (2, 3, 5) -- always call in case job completes too quickly for normal update cycle
		BEGIN 
			EXEC @myError = S_SetArchiveUpdateTaskBusy @datasetNum, @storageServerName, @message output
		END

		IF @newJobStateInBroker = 3
		BEGIN 
			EXEC @myError = S_SetArchiveUpdateTaskComplete @datasetNum, 0, @message output
		END

		IF @newJobStateInBroker = 5
		BEGIN 
			EXEC @myError = S_SetArchiveUpdateTaskComplete @datasetNum, 1, @message output
		END
	END

	return @myError
GO

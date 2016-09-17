/****** Object:  StoredProcedure [dbo].[UpdateFailedJobNowInProgress] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateFailedJobNowInProgress
/****************************************************
**
**	Desc:	Updates job state to 2 for an analysis job that is now in-progress in the DMS_Pipeline database
**			Typically used to update jobs listed as Failed in DMS5, but
**			occasionally updates jobs listed as New
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	02/21/2013 mem - Initial version
**    
*****************************************************/
(
	@Job int,
	@NewBrokerJobState int,
	@JobStart datetime,
	@UpdateCode int,					-- Safety feature to prevent unauthorized job updates
	@infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	Declare @DatasetName varchar(128)
	Set @DatasetName = ''
	
	Declare @UpdateCodeExpected int
		
   	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	If @Job Is Null
	Begin
		Set @message = 'Invalid job'
		Set @myError = 50000
		Goto Done
	End

	-- Confirm that @UpdateCode is valid for this job
	If @Job % 2 = 0
		Set @UpdateCodeExpected = (@Job % 220) + 14
	Else
		Set @UpdateCodeExpected = (@Job % 125) + 11
	
	If IsNull(@UpdateCode, 0) <> @UpdateCodeExpected
	Begin
		Set @message = 'Invalid Update Code'
		Set @myError = 50002
		Goto Done
	End
	
	If @infoOnly <> 0
	Begin
		-- Display the old and new values
		SELECT AJ_JobID,
		       AJ_StateID,
		       2 AS AJ_StateID_New,
		       AJ_Start,
		       CASE
		           WHEN @NewBrokerJobState >= 2 THEN IsNull(@JobStart, GetDate())
		           ELSE AJ_start
		       END AS AJ_Start_New
		FROM T_Analysis_Job
		WHERE AJ_jobID = @job
	End
	Else
	Begin
		-- Perform the update
		UPDATE T_Analysis_Job
		SET AJ_StateID = 2,
		    AJ_start = CASE WHEN @NewBrokerJobState >= 2 
		                    THEN IsNull(@JobStart, GetDate())
		                    ELSE AJ_start
		               END,
		    AJ_AssignedProcessorName = 'Job_Broker'
		WHERE AJ_jobID = @job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	
	
   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateFailedJobNowInProgress] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateFailedJobNowInProgress] TO [PNL\D3M580] AS [dbo]
GO

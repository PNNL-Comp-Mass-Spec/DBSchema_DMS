/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobProcessingStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure dbo.UpdateAnalysisJobProcessingStats
/****************************************************
**
**	Desc: Updates job state, start, and finish in T_Analysis_Job
**
**		  Sets archive status of dataset to update required
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	06/02/2009 mem - Initial version
**			09/02/2011 mem - Now setting AJ_Purged to 0 when job is complete, no-export, or failed
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			04/18/2012 mem - Now preventing addition of @JobCommentAddnl to the comment field if it already contains @JobCommentAddnl
**    
*****************************************************/
(
	@Job int,
	@NewDMSJobState int,
	@NewBrokerJobState int,
	@JobStart datetime,
	@JobFinish datetime,
	@ResultsFolderName varchar(128),
	@AssignedProcessor varchar(64),
	@JobCommentAddnl varchar(512),		-- Additional text to append to the comment (direct append; no separator character is used when appending @JobCommentAddnl)
	@OrganismDBName varchar(128),
	@ProcessingTimeMinutes real,
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
	
	Set @JobCommentAddnl = LTrim(RTrim(IsNull(@JobCommentAddnl, '')))
	
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
	
	If @NewDMSJobState Is Null Or @NewBrokerJobState Is Null
	Begin
		Set @message = 'Job and Broker state cannot be null'
		Set @myError = 50001
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
	
	---------------------------------------------------
	-- Perform (or preview) the update
	-- Note: Comment is not updated if @NewBrokerJobState = 2
	---------------------------------------------------
	-- 
	If @infoOnly <> 0
	Begin
		-- Display the old and new values
		SELECT AJ_StateID,
		       @NewDMSJobState AS AJ_StateID_New,
		       AJ_start,
		       CASE
		           WHEN @NewBrokerJobState >= 2 THEN IsNull(@JobStart, GetDate())
		           ELSE AJ_start
		       END AS AJ_start_New,
		       AJ_finish,
		       CASE
		           WHEN @NewBrokerJobState IN (4, 5) THEN @JobFinish
		           ELSE AJ_finish
		       END AS AJ_finish_New,
		       AJ_resultsFolderName,
		       @resultsFolderName AS AJ_resultsFolderName_New,
		       AJ_AssignedProcessorName,
		       @AssignedProcessor AS AJ_AssignedProcessorName_New,
		       CASE
		           WHEN @NewBrokerJobState = 2 THEN AJ_Comment
		           ELSE IsNull(AJ_comment, '') + @JobCommentAddnl
		       END AS Comment_New,
		       AJ_organismDBName,
		       IsNull(@OrganismDBName, AJ_organismDBName) AS AJ_organismDBName_New,
		       AJ_ProcessingTimeMinutes,
		       CASE
		           WHEN @NewBrokerJobState <> 2 THEN @ProcessingTimeMinutes
		           ELSE AJ_ProcessingTimeMinutes
		       END AS AJ_ProcessingTimeMinutes_New
		FROM T_Analysis_Job
		WHERE AJ_jobID = @job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	Else
	Begin
		-- Update the values
		UPDATE T_Analysis_Job
		SET AJ_StateID = @NewDMSJobState,
		    AJ_start = CASE WHEN @NewBrokerJobState >= 2 
		                    THEN IsNull(@JobStart, GetDate())
		                    ELSE AJ_start
		               END,
		    AJ_finish = CASE WHEN @NewBrokerJobState IN (4, 5) 
		                     THEN @JobFinish
		                     ELSE AJ_finish
		                END,
		    AJ_resultsFolderName = @resultsFolderName,
		    AJ_AssignedProcessorName = 'Job_Broker',
		    AJ_comment = CASE WHEN @NewBrokerJobState = 2 
		                      THEN AJ_Comment
		                      ELSE 
		                           CASE WHEN CHARINDEX(@JobCommentAddnl, IsNull(AJ_comment, '')) > 0 
		                                THEN IsNull(AJ_comment, '')
		                                ELSE IsNull(AJ_comment, '') + @JobCommentAddnl
		                           END
		                 END,
		    AJ_organismDBName = IsNull(@OrganismDBName, AJ_organismDBName),
		    AJ_ProcessingTimeMinutes = CASE WHEN @NewBrokerJobState <> 2 
		                                    THEN @ProcessingTimeMinutes
		                                    ELSE AJ_ProcessingTimeMinutes
		                               END,
		    -- Note: setting AJ_Purged to 0 even if job failed since admin might later manually set job to complete and we want AJ_Purged to be 0 in that case
		    AJ_Purged = CASE WHEN @NewBrokerJobState IN (4, 5, 14) 
		                     THEN 0
		                     ELSE AJ_Purged
		                END
		WHERE AJ_jobID = @job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	
	-------------------------------------------------------------------
	-- If Job is Complete or No Export, then schedule an archive update
	-------------------------------------------------------------------
	If @NewDMSJobState in (4, 14)
	Begin				
		SELECT @DatasetName = DS.Dataset_Num
		FROM dbo.T_Analysis_Job AJ
		     INNER JOIN dbo.T_Dataset DS
		       ON AJ.AJ_datasetID = DS.Dataset_ID
		WHERE (AJ.AJ_jobID = @job)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount > 0
			Exec SetArchiveUpdateRequired @DatasetName, @Message output
	End

   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	return @myError


GO
GRANT ALTER ON [dbo].[UpdateAnalysisJobProcessingStats] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobProcessingStats] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobProcessingStats] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobProcessingStats] TO [DMSReader] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobProcessingStats] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobProcessingStats] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobProcessingStats] TO [PNL\D3M580] AS [dbo]
GO

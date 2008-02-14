/****** Object:  StoredProcedure [dbo].[SetDataExtractionTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetDataExtractionTaskComplete
/****************************************************
**
**	Desc: Sets status of analysis job to successful
**        completion and processes analysis results
**        or sets status to failed (according to
**        value of input argument).
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@jobNum				unique identifier for analysis job
**	@processorName			name of caller's computer
**      @completionCode			0->success, 1->failure, anything else ->no intermediate files
**      @resultsFolderName		name of folder that contains analysis results
**      @comment			text to be appended to comment field
**		  @message			output message for debugging
**
**	Auth: jds
**	Date: 01/6/2006
**            07/10/2006 grk - added code for completion code 2
**            07/28/2006 grk - save completion code to job table
**            10/13/2006 jds - removed parameters @processorName and @resultsFolderName
**                             since they are not needed
**				  06/29/2007 dac - added @message output parameter
**
*****************************************************/
    @jobNum varchar(32),
    @completionCode int = 0,
    @comment varchar(255),
	 @message varchar(512) = '' output

As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

--	declare @message varchar(512)

	declare @jobID int

	set @jobID = convert(int, @jobNum)

	if @completionCode > 0 and @completionCode < 10   
		begin -- Data extration failed 
			UPDATE T_Analysis_Job 
			SET AJ_finish = GETDATE(), 
			AJ_extractionFinish = GETDATE(),
			AJ_StateID = 18, -- "Failed" 
			AJ_Data_Extraction_Error = @completionCode,
			AJ_comment = @comment
			WHERE (AJ_jobID = @jobID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to set failed completion'
				RAISERROR (@message, 10, 1)
				return 53100
			end
		end
	else
		begin -- Data extraction succeeded
			UPDATE T_Analysis_Job 
			SET AJ_finish = GETDATE(),
			AJ_extractionFinish = GETDATE(),
			AJ_StateID = 3, -- "Results Received"
			AJ_Data_Extraction_Error = @completionCode,
			AJ_comment = @comment
			WHERE (AJ_jobID = @jobID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to set successful completion'
				RAISERROR (@message, 10, 1)
				return 53100
			end
		end

	return 0

GO

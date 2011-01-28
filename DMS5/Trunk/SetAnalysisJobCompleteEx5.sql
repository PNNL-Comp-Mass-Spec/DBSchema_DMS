/****** Object:  StoredProcedure [dbo].[SetAnalysisJobCompleteEx5] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.SetAnalysisJobCompleteEx5
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
**	@completionCode			0->success, 1->failure, anything else ->no intermediate files
**	@resultsFolderName		name of folder that contains analysis results
**	@comment			text to be appended to comment field
**
**	Auth:	grk
**	Date:	02/28/2001
**			10/01/2001 dac - Changed to accept failure in creation of intermediate files and comment modification
**						   - NOTE: completion codes 2, 3, and 4 have special uses for Sequest manager
**			11/18/2002 grk - Changed to work with new DMS storage architecture
**			03/22/2006 jds - Added support for data extraction based on AJT_extractionRequired in T_Analysis_Tool
**			06/13/2006 grk - Added argument for generated organism DB file name
**			02/19/2009 mem - Now updating AJ_ProcessingTimeMinutes in T_Analysis_Job
**			02/27/2009 mem - Expanded @comment to varchar(512)
**    
*****************************************************/
(
    @jobNum varchar(32),
    @processorName varchar(64),
    @completionCode int = 0,
    @resultsFolderName varchar(64),
    @comment varchar(512),
    @organismDBName varchar(64) = ''
)
As
	-- set nocount on

	declare @jobID int


	set @jobID = convert(int, @jobNum)
	-- future: this could get more complicated

	-- future: get job and verify @processorName 

	-- future: check job state for "in progress"

    --Check to see if a Data Extraction is required
    declare @extractionFlag Char(1)
    set @extractionFlag = 'N' --set default to N
    --
	declare @orgDBName varchar(64)
	set @orgDBName = ''
	--
	declare @protCollList varchar(512)
	set @protCollList = ''

    SELECT    
		@extractionFlag = AJT_extractionRequired,
		@orgDBName = AJ_organismDBName,
		@protCollList = AJ_proteinCollectionList
    FROM  T_Analysis_Job A 
            INNER JOIN T_Analysis_Tool T ON A.AJ_analysisToolID = T.AJT_toolID 
    WHERE AJ_JobID = @jobNum
    
    -- decide on the fasta file name to save in job
    --
    if @protCollList <> 'na'
    begin
		set @orgDBName = @organismDBName
    end

	-- update analysis job according to completion parameters
	--
	if @completionCode = 0  -- Job completed successfully
		begin
			if @extractionFlag = 'Y' 
				begin
					UPDATE T_Analysis_Job 
					SET AJ_finish = GETDATE(), 
					AJ_resultsFolderName = @resultsFolderName, 
					AJ_StateID = 16, -- "Data Extraction Required"
					AJ_comment = @comment,
				    AJ_organismDBName = @orgDBName,
				    AJ_ProcessingTimeMinutes = DateDiff(second, AJ_Start, GETDATE()) / 60.0
					WHERE (AJ_jobID = @jobID)
				end
			else
				begin
					UPDATE T_Analysis_Job 
					SET AJ_finish = GETDATE(), 
					AJ_resultsFolderName = @resultsFolderName, 
					AJ_StateID = 3, -- "Results Received"
					AJ_comment = @comment,
				    AJ_organismDBName = @orgDBName,
				    AJ_ProcessingTimeMinutes = DateDiff(second, AJ_Start, GETDATE()) / 60.0
					WHERE (AJ_jobID = @jobID)
				end
		end
	else
		if @completionCode = 1  -- Job failed for unknown reasons
			begin
				UPDATE T_Analysis_Job 
				SET AJ_finish = GETDATE(), 
				AJ_StateID = 5, -- "Failed" 
				AJ_comment = @comment,
				AJ_organismDBName = @orgDBName,
				AJ_ProcessingTimeMinutes = DateDiff(second, AJ_Start, GETDATE()) / 60.0
				WHERE (AJ_jobID = @jobID)
			end
		else	-- Job failed due to lack of intermediate files
			begin
				UPDATE T_Analysis_Job 
				SET AJ_finish = GETDATE(), 
				AJ_StateID = 7, -- "No intermediate files created" 
				AJ_comment = @comment,
				AJ_organismDBName = @orgDBName,
				    AJ_ProcessingTimeMinutes = DateDiff(second, AJ_Start, GETDATE()) / 60.0
				WHERE (AJ_jobID = @jobID)
			end
	-- end of completion code test
			
	if @@rowcount <> 1
	begin
		RAISERROR ('Update operation failed',
			10, 1)
		return 53100
	end
	

	return 0 



GO
GRANT EXECUTE ON [dbo].[SetAnalysisJobCompleteEx5] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetAnalysisJobCompleteEx5] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetAnalysisJobCompleteEx5] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetAnalysisJobCompleteEx5] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetAnalysisJobCompleteEx5] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetAnalysisJobCompleteEx5] TO [PNL\D3M580] AS [dbo]
GO

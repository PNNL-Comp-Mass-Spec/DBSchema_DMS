/****** Object:  StoredProcedure [dbo].[SetAnalysisJobComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SetAnalysisJobComplete
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
**		Auth: grk
**		Date: 02/28/2001
**    
**		Mod: DAC  
**		Date: 10/1/2001
**		Changed to accept failure in creation of intermediate files and comment modification
**    
**		NOTE: completion codes 2, 3, and 4 have special uses for Sequest manager
**    
**		Mod: GRK 
**		Date: 11/18/2002
**		Changed to work with new DMS storage architecture
**    
**		Mod: JDS
**		Date: 3/22/2006
**		added support for data extraction based on AJT_extractionRequired in T_Analysis_Tool
**    
**		Mod: GRK 
**		Date: 6/13/2006
**		Added argument for generated organism DB file name
**       
**		Mod: DAC 
**		Date: 3/22/2007
**		Procedure SetAnalysisJobComplete created by copying SetAnalysisJobCompleteEx5 as part of ticket #413 resolution
**       
*****************************************************/
    @jobNum varchar(32),
    @processorName varchar(64),
    @completionCode int = 0,
    @resultsFolderName varchar(64),
    @comment varchar(255),
    @organismDBName varchar(64) = ''
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
	if @completionCode = 0  -- Job completed sat
		begin
			if @extractionFlag = 'Y' 
				begin
					UPDATE T_Analysis_Job 
					SET AJ_finish = GETDATE(), 
					AJ_resultsFolderName = @resultsFolderName, 
					AJ_StateID = 16, -- "Data Extraction Required"
					AJ_comment = @comment,
				    AJ_organismDBName = @orgDBName
					WHERE (AJ_jobID = @jobID)
				end
			else
				begin
					UPDATE T_Analysis_Job 
					SET AJ_finish = GETDATE(), 
					AJ_resultsFolderName = @resultsFolderName, 
					AJ_StateID = 3, -- "Results Received"
					AJ_comment = @comment,
				    AJ_organismDBName = @orgDBName
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
				AJ_organismDBName = @orgDBName
				WHERE (AJ_jobID = @jobID)
			end
		else	-- Job failed due to lack of intermediate files
			begin
				UPDATE T_Analysis_Job 
				SET AJ_finish = GETDATE(), 
				AJ_StateID = 7, -- "No intermediate files created" 
				AJ_comment = @comment,
				AJ_organismDBName = @orgDBName
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
GRANT VIEW DEFINITION ON [dbo].[SetAnalysisJobComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetAnalysisJobComplete] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetAnalysisJobComplete] TO [PNL\D3M580] AS [dbo]
GO

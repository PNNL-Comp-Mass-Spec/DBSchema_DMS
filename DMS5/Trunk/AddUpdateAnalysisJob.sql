/****** Object:  StoredProcedure [dbo].[AddUpdateAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateAnalysisJob
/****************************************************
**
**	Desc: Adds new analysis job to job table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	01/10/2002
**			01/30/2004 fixed @@identity problem with insert
**			05/06/2004 grk - allowed analysis processor preset
**			11/05/2004 grk - added parameter for assigned processor
**							 removed batchID parameter
**			02/10/2005 grk - fixed update to include assigned processor
**			03/28/2006 grk - added protein collection fields
**			04/04/2006 grk - increased size of param file name
**			04/07/2006 grk - revised valiation logic to use ValidateAnalysisJobParameters
**			04/11/2006 grk - added state field and reset mode
**			04/21/2006 grk - reset now allowed even if job not in "new" state
**			06/01/2006 grk - added code to handle '(default)' organism
**			11/30/2006 mem - Added column Dataset_Type to #TD (Ticket #335)
**			12/20/2006 mem - Added column DS_rating to #TD (Ticket #339)
**          1/13/2007  grk - switched to organism ID instead of organism name (Ticket #360)
**    
*****************************************************/
(
    @datasetNum varchar(128),
    @priority int = 2,
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(64),
    @organismName varchar(64),
    @protCollNameList varchar(512),
    @protCollOptionsList varchar(256),
	@organismDBName varchar(64),
    @ownerPRN varchar(32),
    @comment varchar(255) = null,
	@assignedProcessor varchar(64),
	@stateName varchar(32),
    @jobNum varchar(32) = "0" output,
	@mode varchar(12) = 'add', -- or 'update' or 'reset'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @msg varchar(256)

    declare @batchID int
	set @batchID = 0


	---------------------------------------------------
	-- Is entry already in database? (only applies to updates and resets)
	---------------------------------------------------

	declare @jobID int
	declare @stateID int
	set @jobID = 0
	set @stateID = 0

	if @mode = 'update' or @mode = 'reset'
	begin
		-- cannot update a non-existent entry
		--
		SELECT 
			@jobID = AJ_jobID,
			@stateID = AJ_StateID
		FROM T_Analysis_Job
		WHERE (AJ_jobID = convert(int, @jobNum))

		if @jobID = 0
		begin	
			set @msg = 'Cannot update:  Analysis Job "' + @jobNum + '" is not in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end

	if @mode = 'update'
	begin
		-- changes only allowed to jobs in 'new' state
		--
		if @stateID <> 1
		begin
				set @msg = 'Cannot update:  Analysis Job "' + @jobNum + '" is not in "new" state '
				RAISERROR (@msg, 10, 1)
				return 51005
		end
	end

	---------------------------------------------------
	-- Create temporary table to hold "list" of the dataset
	---------------------------------------------------

	CREATE TABLE #TD (
		Dataset_Num varchar(128),
		Dataset_ID int,
		IN_class varchar(64), 
		DS_state_ID int, 
		AS_state_ID int,
		Dataset_Type varchar(64),
		DS_rating smallint
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Failed to create temporary table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- Add dataset to table  
	---------------------------------------------------
	--
	INSERT INTO #TD
		(Dataset_Num)
	VALUES
		(@datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error populating temporary table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- handle '(default)' organism  
	---------------------------------------------------

	if @organismName = '(default)'
	begin
		SELECT 
			@organismName = T_Organisms.OG_name
		FROM
			T_Experiments INNER JOIN
			T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID INNER JOIN
			T_Organisms ON T_Experiments.Ex_organism_ID = T_Organisms.Organism_ID
		WHERE     
			(T_Dataset.Dataset_Num = @datasetNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error resolving default organism name'
			RAISERROR (@msg, 10, 1)
			return 51012
		end
	end

	---------------------------------------------------
	-- validate job parameters
	---------------------------------------------------
	--
	declare @userID int
	declare @analysisToolID int
	declare @organismID int
	--
	declare @result int
	set @result = 0
	--
	exec @result = ValidateAnalysisJobParameters
							@toolName,
							@parmFileName,
							@settingsFileName,
							@organismDBName output,
							@organismName,
							@protCollNameList output,
							@protCollOptionsList output,
							@ownerPRN,
							@mode, 
							@userID output,
							@analysisToolID output, 
							@organismID output,
							@msg output
	--
	if @result <> 0
	begin
		RAISERROR (@msg, 10, 1)
		return 53108
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	declare @archiveState int		
	declare @datasetID int
	--
	SELECT TOP 1 @datasetID = Dataset_ID FROM #TD
	SELECT TOP 1 @archiveState = AS_state_ID FROM #TD

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	if @mode = 'add'
	begin
		declare @newJobNum int
		--
		INSERT INTO T_Analysis_Job (
			AJ_priority, 
			AJ_created, 
			AJ_analysisToolID, 
			AJ_parmFileName, 
			AJ_settingsFileName,
			AJ_organismDBName, 
			AJ_proteinCollectionList, 
			AJ_proteinOptionsList,
			AJ_organismID, 
			AJ_datasetID, 
			AJ_comment,
			AJ_owner,
			AJ_batchID,
			AJ_StateID,
			AJ_assignedProcessorName
		) VALUES (
			@priority, 
			getdate(), 
			@analysisToolID, 
			@parmFileName, 
			@settingsFileName,
			@organismDBName, 
			@protCollNameList,
			@protCollOptionsList,
			@organismID, 
			@datasetID, 
			@comment,
			@ownerPRN,
			@batchID,
			CASE WHEN @archiveState = 4 THEN 10 ELSE 1 END,
			@assignedProcessor
		)			
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert new job operation failed'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		
		-- return job number of newly created job
		--
		set @jobNum = cast(IDENT_CURRENT('T_Analysis_Job') as varchar(32))

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @mode = 'update' or @mode = 'reset' 
	begin
		set @myError = 0

		---------------------------------------------------
		-- Resolve state ID according to mode and state name
		--
		set @stateID = 0
		--
		if @mode = 'reset' 
		begin
			set @stateID = 1
		end
		else
		begin
			--
			SELECT @stateID =  AJS_stateID
			FROM T_Analysis_State_Name
			WHERE (AJS_name = @stateName)		
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error looking up state name'
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end		
		---------------------------------------------------
		-- make changes to database
		--
		UPDATE T_Analysis_Job 
		SET 
			AJ_priority = @priority, 
			AJ_analysisToolID = @analysisToolID, 
			AJ_parmFileName = @parmFileName, 
			AJ_settingsFileName = @settingsFileName, 
			AJ_organismDBName = @organismDBName, 
			AJ_proteinCollectionList = @protCollNameList, 
			AJ_proteinOptionsList = @protCollOptionsList,
			AJ_organismID = @organismID, 
			AJ_datasetID = @datasetID, 
			AJ_comment = @comment,
			AJ_owner = @ownerPRN,
			AJ_assignedProcessorName = @assignedProcessor,
			AJ_StateID = @stateID,
			AJ_start = CASE WHEN @mode <> 'reset' THEN AJ_start ELSE NULL END, 
			AJ_finish = CASE WHEN @mode <> 'reset' THEN AJ_finish ELSE NULL END
		WHERE (AJ_jobID = @jobID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @jobNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode

	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS_Analysis]
GO

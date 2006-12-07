/****** Object:  StoredProcedure [dbo].[AddAnalysisJobGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddAnalysisJobGroup
/****************************************************
**
**	Desc: Adds new analysis jobs for list of datasets
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	01/29/2004
**			04/1/04 grk -- fixed error return
**			06/7/04 to 4/04/2006 -- multiple updates
**			4/05/2006 grk - major rewrite
**			04/10/2006 grk - widened size of list argument to 6000 characters
**			11/30/2006 mem - Added column Dataset_Type to #TD (Ticket #335)
**    
*****************************************************/
(
    @datasetList varchar(6000),
    @priority int = 2,
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(64),
    @organismDBName varchar(64),
    @organismName varchar(64),
	@protCollNameList varchar(512),
	@protCollOptionsList varchar(256),
    @ownerPRN varchar(32),
    @comment varchar(255) = null,
    @requestID int,
	@assignedProcessor varchar(64),
	@mode varchar(12), 
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @msg varchar(512)
	declare @list varchar(1024)

	---------------------------------------------------
	-- list shouldn't be empty
	---------------------------------------------------
	if @datasetList = ''
	begin
		set @msg = 'Dataset list is empty'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- Create temporary table to hold list of datasets
	---------------------------------------------------

	CREATE TABLE #TD (
		Dataset_Num varchar(128),
		Dataset_ID int,
		IN_class varchar(64), 
		DS_state_ID int, 
		AS_state_ID int,
		Dataset_Type varchar(64)
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
	-- Populate table from dataset list  
	---------------------------------------------------
	--
	INSERT INTO #TD
		(Dataset_Num)
	SELECT
		Item
	FROM
		MakeTableFromList(@datasetList)
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
	
	if @mode = 'add'
	begin
		---------------------------------------------------
		-- start transaction
		---------------------------------------------------
		--
		declare @transName varchar(32)
		set @transName = 'AddAnalysisJobGroup'
		begin transaction @transName

		---------------------------------------------------
		-- create a new batch if multiple jobs being created
		---------------------------------------------------
		declare @batchID int
		set @batchID = 0
		--
		declare @n int
		set @n = 0
		SELECT @n = count(*) FROM #TD
		--
		if @n > 1
		begin
			INSERT INTO T_Analysis_Job_Batches
				(Batch_Description)
			VALUES ('Auto')	
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error trying to create new batch'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51007
			end
			
			-- return ID of newly created batch
			--
			set @batchID = IDENT_CURRENT('T_Analysis_Job_Batches')
		end

		---------------------------------------------------
		-- Deal with request
		---------------------------------------------------
		
		if @requestID = 0
		begin
			set @requestID = 1 -- for the default request
		end
		else
		begin

			-- make sure @requestID is in state 1=new
			declare @requestState int
			set @requestState = 0
			
			SELECT	@requestState = AJR_State
			FROM	T_Analysis_Job_Request
			WHERE	(AJR_RequestID = @requestID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error looking up request state in T_Analysis_Job_Request'
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51007
			end
			
			set @requestState = IsNull(@requestState,0)
			
			if @requestState = 1
			begin
				if @mode in ('add', 'update')
				begin
					-- mark request as used
					--
					UPDATE	T_Analysis_Job_Request
					SET		AJR_state = 2
					WHERE	(AJR_requestID = @requestID)	
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
					--
					if @myError <> 0
					begin
						set @msg = 'Update operation failed'
						rollback transaction @transName
						RAISERROR (@msg, 10, 1)
						return 51008
					end
				end
			end
			else
			begin
				-- request is not in state 1 and request ID is not 0
				set @msg = 'Request is not in state New; cannot create jobs'
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51009
			end
		end

		---------------------------------------------------
		-- insert a new job in analysis job table for
		-- every dataset in temporary table
		---------------------------------------------------
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
			AJ_assignedProcessorName,
			AJ_requestID
		) SELECT 
			@priority, 
			getdate(), 
			@analysisToolID, 
			@parmFileName, 
			@settingsFileName,
			@organismDBName, 
			@protCollNameList,
			@protCollOptionsList,
			@organismID, 
			#TD.Dataset_ID, 
			@comment,
			@ownerPRN,
			@batchID,
			CASE WHEN #TD.AS_State_ID = 4 THEN 10 ELSE 1 END,
			@assignedProcessor,
			@requestID
		FROM #TD		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			-- set request status to 'incomplete'
			if @requestID > 0
			begin
				UPDATE	T_Analysis_Job_Request
				SET		AJR_state = 4
				WHERE	AJR_requestID = @requestID
			end
			--
			set @msg = 'Insert new job operation failed'
			rollback transaction @transName
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	
		commit transaction @transName
	END -- mode 'add'

	set @message = 'Number of jobs created:' + cast(@myRowCount as varchar(12))

	---------------------------------------------------
	-- 
	---------------------------------------------------
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddAnalysisJobGroup] TO [DMS_Analysis]
GO

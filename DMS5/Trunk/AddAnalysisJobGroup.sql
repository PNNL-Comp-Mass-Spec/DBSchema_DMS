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
**			04/01/2004 grk - fixed error return
**			06/07/2004 to 4/04/2006 -- multiple updates
**			04/05/2006 grk - major rewrite
**			04/10/2006 grk - widened size of list argument to 6000 characters
**			11/30/2006 mem - Added column Dataset_Type to #TD (Ticket #335)
**			12/19/2006 grk - Added propagation mode (Ticket #348)
**			12/20/2006 mem - Added column DS_rating to #TD (Ticket #339)
**          02/07/2007 grk - eliminated "Spectra Required" states (Ticket #249)
**          02/15/2007 grk - added associated processor group (Ticket #383)
**          02/21/2007 grk - removed @assignedProcessor  (Ticket #383)
**			10/11/2007 grk - Expand protein collection list size to 4000 characters (https://prismtrac.pnl.gov/trac/ticket/545)
**			02/19/2008 grk - add explicit NULL column attribute to #TD
**			02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser or AlterEventLogEntryUserMultiID (Ticket #644)
**			05/27/2008 mem - Increased @EntryTimeWindowSeconds value to 45 seconds when calling AlterEventLogEntryUserMultiID
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
	@protCollNameList varchar(4000),
	@protCollOptionsList varchar(256),
    @ownerPRN varchar(32),
    @comment varchar(255) = null,
    @requestID int,
	@associatedProcessorGroup varchar(64),
    @propagationMode varchar(24),
	@mode varchar(12), 
	@message varchar(512) output,
	@callingUser varchar(128) = ''
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
	declare @jobID int
	
	declare @stateID int
	Set @stateID = 1

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
	-- resolve processor group ID
	---------------------------------------------------
	--
	declare @gid int
	set @gid = 0
	--
	if @associatedProcessorGroup <> ''
	begin
		SELECT @gid = ID
		FROM T_Analysis_Job_Processor_Group
		WHERE (Group_Name = @associatedProcessorGroup)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to resolve processor group name'
			RAISERROR (@msg, 10, 1)
			return 51008
		end
		--
		if @gid = 0
		begin
			set @msg = 'Processor group name not found'
			RAISERROR (@msg, 10, 1)
			return 51009
		end
	end

	---------------------------------------------------
	-- Create temporary table to hold list of datasets
	---------------------------------------------------

	CREATE TABLE #TD (
		Dataset_Num varchar(128),
		Dataset_ID int NULL,
		IN_class varchar(64) NULL, 
		DS_state_ID int NULL, 
		AS_state_ID int NULL,
		Dataset_Type varchar(64) NULL,
		DS_rating smallint NULL
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
	-- Resolve propagation mode 
	---------------------------------------------------
	declare @propMode smallint
	set @propMode = CASE @propagationMode 
						WHEN 'Export' THEN 0 
						WHEN 'No Export' THEN 1 
						ELSE 0 
					END 
	
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
		declare @numDatasets int
		set @numDatasets = 0
		SELECT @numDatasets = count(*) FROM #TD
		--
		if @numDatasets = 0
		begin
			set @msg = 'No datasets in list to create jobs for.'
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return 51017
		end
		--
		if @numDatasets > 1
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
			AJ_requestID,
			AJ_propagationMode
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
			@stateID,
			@requestID,
			@propMode
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


		if @batchID = 0 AND @myRowCount = 1
		begin
			-- Added a single job; cache the jobID value
			set @jobID = IDENT_CURRENT('T_Analysis_Job')
		end
			
		---------------------------------------------------
		-- create associations with processor group for new
		-- jobs, if group ID is given
		---------------------------------------------------

		if @gid <> 0
		begin
			-- if single job was created, get its identity directly
			--
			if @batchID = 0 AND @myRowCount = 1
			begin
				INSERT INTO T_Analysis_Job_Processor_Group_Associations
					(Job_ID, Group_ID)
				VALUES
					(@jobID, @gid)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end
			
			--
			-- if multiple jobs were created, get job identities
			-- from all jobs using new batch ID
			--
			if @batchID <> 0 AND @myRowCount >= 1
			begin
				INSERT INTO T_Analysis_Job_Processor_Group_Associations
					(Job_ID, Group_ID)
				SELECT
					AJ_jobID, @gid
				FROM
					T_Analysis_Job
				WHERE
					(AJ_batchID = @batchID)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end
			--
			if @myError <> 0
			begin
				set @msg = 'Error Associating job with processor group'
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51007
			end
		end

		commit transaction @transName
		
		If Len(@callingUser) > 0
		Begin
			-- @callingUser is defined; call AlterEventLogEntryUser or AlterEventLogEntryUserMultiID
			-- to alter the Entered_By field in T_Event_Log
			--
			If @batchID = 0
				Exec AlterEventLogEntryUser 5, @jobID, @stateID, @callingUser
			Else
			Begin
				-- Populate a temporary table with the list of Job IDs just created
				CREATE TABLE #TmpIDUpdateList (
					TargetID int NOT NULL
				)
				
				CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
				
				INSERT INTO #TmpIDUpdateList (TargetID)
				SELECT DISTINCT AJ_jobID
				FROM T_Analysis_Job
				WHERE AJ_batchID = @batchID
					
				Exec AlterEventLogEntryUserMultiID 5, @stateID, @callingUser, @EntryTimeWindowSeconds=45
			End
		End

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
GRANT EXECUTE ON [dbo].[AddAnalysisJobGroup] TO [DMS2_SP_User]
GO

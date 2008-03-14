/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateAnalysisJobs
/****************************************************
**
**	Desc:
**   Updates parameters to new values for jobs in list
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	04/06/2006
**			04/10/2006 grk - widened size of list argument to 6000 characters
**			04/12/2006 grk - eliminated forcing null for blank assigned processor
**			06/20/2006 jds - added support to find/replace text in the comment field
**			08/02/2006 grk - clear the AJ_ResultsFolderName, AJ_extractionProcessor, 
**                           AJ_extractionStart, and AJ_extractionFinish fields when resetting a job
**			11/15/2006 grk - add logic for propagation mode (ticket #328)
**			03/02/2007 grk - add @associatedProcessorGroup (ticket #393)
**			03/18/2007 grk - make @associatedProcessorGroup viable for reset mode (ticket #418)
**			05/07/2007 grk - corrected spelling of sproc name
**			02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUserMultiID (Ticket #644)
**			03/14/2008 grk - Fixed problem with null arguments (Ticket #655)
**    
*****************************************************/
(
    @JobList varchar(6000),
    @state varchar(32) = '',
    @priority varchar(12) = '',
    @comment varchar(255) = '',
    @findText varchar(255) = '',
    @replaceText varchar(255) = '',
    @assignedProcessor varchar(64),
    @associatedProcessorGroup varchar(64),
    @propagationMode varchar(24),
    @mode varchar(12) = 'update',			-- update or reset to change data; otherwise, will simply validate parameters
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

	declare @AlterEventLogRequired tinyint
	set @AlterEventLogRequired = 0

	declare @transName varchar(32)
	set @transName = ''
	
	---------------------------------------------------
	-- Clean up null arguments
	---------------------------------------------------
	
	set @state = isnull(@state, '')
	set @priority = isnull(@priority, '')
	set @comment = isnull(@comment, '')
	set @findText = isnull(@findText, '')
	set @replaceText = isnull(@replaceText, '')
	set @assignedProcessor = isnull(@assignedProcessor, '')
	set @associatedProcessorGroup = isnull(@associatedProcessorGroup, '')
	set @propagationMode = isnull(@propagationMode, '')

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	if @JobList = ''
	begin
		set @msg = 'Job list is empty'
		RAISERROR (@msg, 10, 1)
		return 51001
	end


	if (@findText = '[no change]' and @replaceText <> '[no change]') OR (@findText <> '[no change]' and @replaceText = '[no change]')
	begin
		set @msg = 'The Find In Comment and Replace In Comment enabled flags must both be enabled or disabled'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	---------------------------------------------------
	--  Create temporary table to hold list of jobs
	---------------------------------------------------
 
 	CREATE TABLE #TAJ (
		Job int
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Failed to create temporary job table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Populate table from job list  
	---------------------------------------------------

	INSERT INTO #TAJ
	(Job)
	SELECT DISTINCT Convert(int, Item)
	FROM MakeTableFromList(@JobList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error populating temporary job table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Verify that all jobs exist 
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN cast(Job as varchar(12))
		ELSE ', ' + cast(Job as varchar(12))
		END
	FROM
		#TAJ
	WHERE 
		NOT Job IN (SELECT AJ_jobID FROM T_Analysis_Job)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking job existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following jobs from list were not in database:"' + @list + '"'
		return 51007
	end
	
	declare @jobCount int
	SELECT @jobCount = count(*) FROM #TAJ
	set @message = 'Number of affected jobs:' + cast(@jobCount as varchar(12))

	---------------------------------------------------
	-- Resolve state name
	---------------------------------------------------
	declare @stateID int
	set @stateID = 0
	--
	if @state <> '[no change]'
	begin
		--
		SELECT @stateID = AJS_stateID
		FROM  T_Analysis_State_Name
		WHERE (AJS_name = @state)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up state name'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		--
		if @stateID = 0
		begin
			set @msg = 'Could not find state'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- if @state

	
 	---------------------------------------------------
	-- Update jobs from temporary table
	-- in cases where parameter has changed
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0

		---------------------------------------------------
		set @transName = 'UpadateAnalysisJobs'
		begin transaction @transName

		-----------------------------------------------
		if @state <> '[no change]'
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_StateID = @stateID
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end

			Set @AlterEventLogRequired = 1
		end

		-----------------------------------------------
		if @priority <> '[no change]'
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_priority =  CAST(@priority AS int) 
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @comment <> '[no change]'
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_comment = AJ_comment + ' ' + @comment
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @findText <> '[no change]' and @replaceText <> '[no change]'
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_comment = replace(AJ_comment, @findText, @replaceText)
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @assignedProcessor <> '[no change]'
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_assignedProcessorName =  @assignedProcessor
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @propagationMode <> '[no change]'
		begin
			declare @propMode smallint
			set @propMode = CASE @propagationMode 
								WHEN 'Export' THEN 0 
								WHEN 'No Export' THEN 1 
								ELSE 0 
							END 
			--
			UPDATE T_Analysis_Job 
			SET 
				AJ_propagationMode =  @propMode
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51009
			end
		end

-- future: append/replace comments

-- future: clear run times

	end -- update mode

 	---------------------------------------------------
	-- Reset job to New state
	---------------------------------------------------
	--
	if @Mode = 'reset' 
	begin

		---------------------------------------------------
		set @transName = 'UpadateAnalysisJobs'
		begin transaction @transName
		set @myError = 0
		
		Set @stateID = 1
		
		UPDATE T_Analysis_Job 
		SET 
			AJ_StateID = @stateID, 
			AJ_start = NULL, 
			AJ_finish = NULL,
			AJ_resultsFolderName = '',
			AJ_extractionProcessor = '', 
			AJ_extractionStart = NULL, 
			AJ_extractionFinish = NULL,
			AJ_priority =  CASE WHEN @priority = '[no change]' THEN AJ_priority ELSE CAST(@priority AS int) END, 
			AJ_comment = AJ_comment + CASE WHEN @comment = '[no change]' THEN '' ELSE ' ' + @comment END,
			AJ_assignedProcessorName = CASE WHEN @assignedProcessor = '[no change]' THEN AJ_assignedProcessorName ELSE @assignedProcessor END
		WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed'
			rollback transaction @transName
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		
		Set @AlterEventLogRequired = 1
	end -- reset mode
 
 	If Len(@callingUser) > 0 And @AlterEventLogRequired <> 0
	Begin
		-- @callingUser is defined; call AlterEventLogEntryUserMultiID
		-- to alter the Entered_By field in T_Event_Log
		--

		-- Populate a temporary table with the list of Job IDs just updated
		CREATE TABLE #TmpIDUpdateList (
			TargetID int NOT NULL
		)
		
		CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
		
		INSERT INTO #TmpIDUpdateList (TargetID)
		SELECT DISTINCT Job
		FROM #TAJ
			
		Exec AlterEventLogEntryUserMultiID 5, @stateID, @callingUser
	End
	
	
 	---------------------------------------------------
	-- Handle associated processor Group
	---------------------------------------------------
 	-----------------------------------------------
	if @associatedProcessorGroup <> '[no change]' and @transName <> ''
	begin 
		---------------------------------------------------
		-- resolve processor group ID
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

		if @gid = 0
			begin
				-- dissassociate given jobs from group
				--
				DELETE FROM T_Analysis_Job_Processor_Group_Associations
				WHERE (Job_ID in (SELECT Job FROM #TAJ))					
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Update operation failed'
					rollback transaction @transName
					RAISERROR (@msg, 10, 1)
					return 51014
				end
			end
		else
			begin
				-- for jobs with existing association, change it
				--
				UPDATE T_Analysis_Job_Processor_Group_Associations
				SET	Group_ID = @gid
				WHERE (Job_ID in (SELECT Job FROM #TAJ))					
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Update operation failed'
					rollback transaction @transName
					RAISERROR (@msg, 10, 1)
					return 51015
				end

				-- for jobs without existing association, create it
				--
				INSERT INTO T_Analysis_Job_Processor_Group_Associations
									(Job_ID, Group_ID)
				SELECT Job, @gid FROM #TAJ
				WHERE NOT (Job IN (SELECT Job_ID FROM T_Analysis_Job_Processor_Group_Associations))
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Update operation failed'
					rollback transaction @transName
					RAISERROR (@msg, 10, 1)
					return 51016
				end
			end
	end  -- associated processor Group

 	---------------------------------------------------
	-- 
	---------------------------------------------------
	if @transName <> ''
	begin
		commit transaction @transName
	end
	
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobs] TO [DMS2_SP_User]
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobs] TO [RBAC-Web_Analysis]
GO

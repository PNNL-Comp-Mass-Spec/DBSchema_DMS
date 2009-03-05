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
**			04/09/2008 mem - Now calling AlterEnteredByUserMultiID if the jobs are associated with a processor group 
**			07/11/2008 jds - Added 5 new fields (@parmFileName, @settingsFileName, @organismID, @protCollNameList, @protCollOptionsList)
**							 and code to validate param file settings file against tool type
**			10/06/2008 mem - Now updating parameter file name, settings file name, protein collection list, protein options list, and organism when a job is reset (for any of these that are not '[no change]')
**			11/05/2008 mem - Now allowing for find/replace in comments when @mode = 'reset'
**			02/27/2009 mem - Changed default values to [no change]
**							 Expanded update failure messages to include more detail
**							 Expanded @comment to varchar(512)
**
*****************************************************/
(
    @JobList varchar(6000),
    @state varchar(32) = '[no change]',
    @priority varchar(12) = '[no change]',
    @comment varchar(512) = '[no change]',						-- Text to append to the comment
    @findText varchar(255) = '[no change]',			-- Text to find in the comment; ignored if '[no change]'
    @replaceText varchar(255) = '[no change]',		-- The replacement text when @findText is not '[no change]'
    @assignedProcessor varchar(64) = '[no change]',
    @associatedProcessorGroup varchar(64) = '[no change]',
    @propagationMode varchar(24) = '[no change]',
--
    @parmFileName varchar(255) = '[no change]',
    @settingsFileName varchar(64) = '[no change]',
    @organismName varchar(64) = '[no change]',
    @protCollNameList varchar(4000) = '[no change]',
    @protCollOptionsList varchar(256) = '[no change]',
--
    @mode varchar(12) = 'update',			-- 'update' or 'reset' to change data; otherwise, will simply validate parameters
    @message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @NoChangeText varchar(32)
	set @NoChangeText = '[no change]'
	set @message = ''

	declare @msg varchar(512)
	declare @list varchar(1024)

	declare @AlterEventLogRequired tinyint
	declare @AlterEnteredByRequired tinyint
	set @AlterEventLogRequired = 0
	set @AlterEnteredByRequired = 0

	declare @transName varchar(32)
	set @transName = ''
	
	---------------------------------------------------
	-- Clean up null arguments
	---------------------------------------------------
	
	set @state = isnull(@state, @NoChangeText)
	set @priority = isnull(@priority, @NoChangeText)
	set @comment = isnull(@comment, @NoChangeText)
	set @findText = isnull(@findText, @NoChangeText)
	set @replaceText = isnull(@replaceText, @NoChangeText)
	set @assignedProcessor = isnull(@assignedProcessor, @NoChangeText)
	set @associatedProcessorGroup = isnull(@associatedProcessorGroup, @NoChangeText)
	set @propagationMode = isnull(@propagationMode, @NoChangeText)
    set @parmFileName = isnull(@parmFileName, @NoChangeText)
    set @settingsFileName = isnull(@settingsFileName, @NoChangeText)
    set @organismName = isnull(@organismName, @NoChangeText)
    set @protCollNameList = isnull(@protCollNameList, @NoChangeText)
    set @protCollOptionsList = isnull(@protCollOptionsList, @NoChangeText)
    
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	if @JobList = ''
	begin
		set @msg = 'Job list is empty'
		RAISERROR (@msg, 10, 1)
		return 51001
	end


	if (@findText = @NoChangeText and @replaceText <> @NoChangeText) OR (@findText <> @NoChangeText and @replaceText = @NoChangeText)
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
	if @state <> @NoChangeText
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
	-- resolve organism ID
	---------------------------------------------------
	--
	declare @orgid int
	set @orgid = 0
	--
	if @organismName <> @NoChangeText
	begin
		SELECT @orgid = ID
		FROM V_Organism_List_Report
		WHERE (Name = @organismName)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to resolve organism name'
			RAISERROR (@msg, 10, 1)
			return 51014
		end
		--
		if @orgid = 0
		begin
			set @msg = 'Organism name not found'
			RAISERROR (@msg, 10, 1)
			return 51015
		end
	end
	
	---------------------------------------------------
	-- Validate param file for tool
	---------------------------------------------------
	declare @result int
	--
	set @result = 0
	--
	if @parmFileName <> @NoChangeText
	begin
		SELECT @result = Param_File_ID
		FROM T_Param_Files
		WHERE Param_File_Name = @parmFileName
		--
		if @result = 0
		begin
			set @message = 'Parameter file could not be found' + ':"' + @parmFileName + '"'
			return 51016
		end
	end

	---------------------------------------------------
	-- validate parameter file for tool
	---------------------------------------------------
	--
	if @parmFileName <> @NoChangeText
	begin
		declare @comma_list as varchar(4000)
		declare @id as varchar(32)
		set @comma_list = ''

		DECLARE cma_list_cursor CURSOR
		FOR SELECT TD.Job
			FROM #TAJ TD
			WHERE not exists (
			    SELECT AJ.AJ_jobID 
				FROM dbo.T_Param_Files PF
					INNER JOIN T_Analysis_Tool AnTool
						ON PF.Param_File_Type_ID = AnTool.AJT_paramFileType
		            JOIN T_Analysis_Job AJ
			            ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
				WHERE (PF.Valid = 1) 
				AND PF.Param_File_Name = @parmFileName
			    AND AJ.AJ_jobID = TD.Job
				)
		OPEN cma_list_cursor

		FETCH NEXT FROM cma_list_cursor INTO @id

		WHILE @@FETCH_STATUS = 0
		BEGIN

			set @comma_list = @comma_list + @id + ','

		FETCH NEXT FROM cma_list_cursor INTO @id

		END

		CLOSE cma_list_cursor
		DEALLOCATE cma_list_cursor

		if @comma_list <> ''
		begin
			set @message = 'Based on the parameter file entered, the following Analysis Job(s) were not compatible with the the tool type' + ':"' + @comma_list + '"'
			return 51017
		end
	end

	---------------------------------------------------
	-- Validate settings file for tool
	---------------------------------------------------
	--
	if @settingsFileName <> @NoChangeText
	begin
/*		declare @fullPath varchar(255)
		declare @dirPath varchar(255)
		declare @orgDbReqd int
		--
		-- get tool parameters
		--
		set @dirPath = ''
		set @orgDbReqd = 0
		--
		SELECT 
--			@dirPath = AJT_parmFileStoragePathLocal,
--			@orgDbReqd = AJT_orgDbReqd
		FROM T_Analysis_Tool AT
			join T_Settings_Files SF on SF.Analysis_Tool = AT.AJT_toolName
		WHERE (SF.File_Name = 'IonTrapDefSettings.xml')--@settingsFileName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error looking up tool parameters'
			return 51038
		end
		--
		-- settings file path
		--
		if @dirPath = ''
		begin
			set @message = 'Could not get settings file folder'
			return 53107
		end
			--
		set @fullPath = @dirPath + 'SettingsFiles\' + @settingsFileName
		exec @result = VerifyFileExists @fullPath, @message output
		--
		if @result <> 0
		begin
			set @message = 'Settings file could not be found' + ':"' + @settingsFileName + '"'
			return 53108
		end
*/		--
		-- validate settings file for tool only
		--
		declare @sf_comma_list as varchar(4000)
		declare @sf_id as varchar(32)
		set @sf_comma_list = ''

		DECLARE cma_list_cursor CURSOR
		FOR SELECT TD.Job
			FROM #TAJ TD
			WHERE not exists (
			    SELECT AJ.AJ_jobID 
				FROM dbo.T_Settings_Files SF
					INNER JOIN T_Analysis_Tool AnTool
						ON SF.Analysis_Tool = AnTool.AJT_toolName
		            JOIN T_Analysis_Job AJ
			            ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
				WHERE SF.File_Name = @settingsFileName
			    AND AJ.AJ_jobID = TD.Job
				)
		OPEN cma_list_cursor

		FETCH NEXT FROM cma_list_cursor INTO @sf_id

		WHILE @@FETCH_STATUS = 0
		BEGIN

			set @sf_comma_list = @sf_comma_list + @sf_id + ','

		FETCH NEXT FROM cma_list_cursor INTO @sf_id

		END

		CLOSE cma_list_cursor
		DEALLOCATE cma_list_cursor

		if @sf_comma_list <> ''
		begin
			set @message = 'Based on the settings file entered, the following Analysis Job(s) were not compatible with the the tool type' + ':"' + @sf_comma_list + '"'
			return 51019
		end

	end

 	---------------------------------------------------
	-- Update jobs from temporary table
	-- in cases where parameter has changed
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin -- <update mode>
		set @myError = 0

		---------------------------------------------------
		set @transName = 'UpadateAnalysisJobs'
		begin transaction @transName

		-----------------------------------------------
		if @state <> @NoChangeText
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
				set @msg = 'Update operation failed when updating job state'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end

			Set @AlterEventLogRequired = 1
		end

		-----------------------------------------------
		if @priority <> @NoChangeText
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
				set @msg = 'Update operation failed when updating job priority'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @comment <> @NoChangeText
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
				set @msg = 'Update operation failed when appending new comment text'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @findText <> @NoChangeText and @replaceText <> @NoChangeText
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
				set @msg = 'Update operation failed when finding and replacing text in comment'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @assignedProcessor <> @NoChangeText
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
				set @msg = 'Update operation failed at assigned processor name udpate'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end

		-----------------------------------------------
		if @propagationMode <> @NoChangeText
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
				set @msg = 'Update operation failed at propagation mode update'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51009
			end
		end

		-----------------------------------------------
		if @parmFileName <> @NoChangeText
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_parmFileName =  @parmFileName
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed at parameter file name update'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51010
			end
		end

		-----------------------------------------------
		if @settingsFileName <> @NoChangeText
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_settingsFileName =  @settingsFileName
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed at settings file name update'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51011
			end
		end

		-----------------------------------------------
		if @organismName <> @NoChangeText
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_organismID =  @orgid
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed at organism name update'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51012
			end
		end

		-----------------------------------------------
		if @protCollNameList <> @NoChangeText
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_proteinCollectionList =  @protCollNameList
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed at protein collection update'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51013
			end
		end

		-----------------------------------------------
		if @protCollOptionsList <> @NoChangeText
		begin
			UPDATE T_Analysis_Job 
			SET 
				AJ_proteinOptionsList =  @protCollOptionsList
			WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed and protein collection options update'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51014
			end
		end

	end -- </update mode>

 	---------------------------------------------------
	-- Reset job to New state
	---------------------------------------------------
	--
	if @Mode = 'reset' 
	begin -- <reset mode>

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
			AJ_parmFileName = CASE WHEN @parmFileName = @NoChangeText               THEN AJ_parmFileName ELSE @parmFileName END, 
			AJ_settingsFileName = CASE WHEN @settingsFileName = @NoChangeText       THEN AJ_settingsFileName ELSE @settingsFileName END,
			AJ_proteinCollectionList = CASE WHEN @protCollNameList = @NoChangeText  THEN AJ_proteinCollectionList ELSE @protCollNameList END, 
			AJ_proteinOptionsList = CASE WHEN @protCollOptionsList = @NoChangeText  THEN AJ_proteinOptionsList ELSE @protCollOptionsList END,
			AJ_organismID = CASE WHEN @organismName = @NoChangeText                 THEN AJ_organismID ELSE @orgid END, 
			AJ_priority =  CASE WHEN @priority = @NoChangeText                      THEN AJ_priority ELSE CAST(@priority AS int) END, 
			AJ_comment = AJ_comment + CASE WHEN @comment = @NoChangeText            THEN '' ELSE ' ' + @comment END,
			AJ_assignedProcessorName = CASE WHEN @assignedProcessor = @NoChangeText THEN AJ_assignedProcessorName ELSE @assignedProcessor END
		WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed at bulk job info update for reset jobs'
			rollback transaction @transName
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		
		
		-----------------------------------------------
		if @findText <> @NoChangeText and @replaceText <> @NoChangeText
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
				set @msg = 'Update operation failed at comment find/replace for reset jobs'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
		end
		
		Set @AlterEventLogRequired = 1
	end -- </reset mode>
	
 	---------------------------------------------------
	-- Handle associated processor Group
	---------------------------------------------------
 	-----------------------------------------------
	if @associatedProcessorGroup <> @NoChangeText and @transName <> ''
	begin -- <associated processor group>
	
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
				set @msg = 'Update operation failed removing job from processor group association'
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
			SET	Group_ID = @gid,
				Entered = GetDate(),
				Entered_By = suser_sname()
			WHERE (Job_ID in (SELECT Job FROM #TAJ))					
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed changing job to processor group association'
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
				set @msg = 'Update operation failed assigning job to new processor group association'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51016
			end
			
			Set @AlterEnteredByRequired = 1
		end
	end  -- </associated processor Group>


 	If Len(@callingUser) > 0 AND (@AlterEventLogRequired <> 0 OR @AlterEnteredByRequired <> 0)
	Begin
		-- @callingUser is defined and items need to be updated in T_Event_Log and/or T_Analysis_Job_Processor_Group_Associations
		--
		-- Populate a temporary table with the list of Job IDs just updated
		CREATE TABLE #TmpIDUpdateList (
			TargetID int NOT NULL
		)
		
		CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
		
		INSERT INTO #TmpIDUpdateList (TargetID)
		SELECT DISTINCT Job
		FROM #TAJ
		
		If @AlterEventLogRequired <> 0
		Begin
			-- Call AlterEventLogEntryUserMultiID
			-- to alter the Entered_By field in T_Event_Log
		
			Exec AlterEventLogEntryUserMultiID 5, @stateID, @callingUser
		End

		If @AlterEnteredByRequired <> 0
		Begin
			-- Call AlterEnteredByUserMultiID
			-- to alter the Entered_By field in T_Analysis_Job_Processor_Group_Associations
		
			Exec AlterEnteredByUserMultiID 'T_Analysis_Job_Processor_Group_Associations', 'Job_ID', @CallingUser
		End
	End


 	---------------------------------------------------
	-- Finalize the changes
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

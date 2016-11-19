/****** Object:  StoredProcedure [dbo].[AddUpdateAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateAnalysisJob
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
**			04/07/2006 grk - revised validation logic to use ValidateAnalysisJobParameters
**			04/11/2006 grk - added state field and reset mode
**			04/21/2006 grk - reset now allowed even if job not in "new" state
**			06/01/2006 grk - added code to handle '(default)' organism
**			11/30/2006 mem - Added column Dataset_Type to #TD (Ticket #335)
**			12/20/2006 mem - Added column DS_rating to #TD (Ticket #339)
**          01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**          02/07/2007 grk - eliminated "Spectra Required" states (Ticket #249)
**          02/15/2007 grk - added associated processor group (Ticket #383)
**			02/15/2007 grk - Added propagation mode (Ticket #366)
**          02/21/2007 grk - removed @assignedProcessor (Ticket #383)
**			10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**			01/17/2008 grk - Modified error codes to help debugging DMS2.  Also had to add explicit NULL column attribute to #TD
**			02/22/2008 mem - Updated to allow updating jobs in state "holding"
**						   - Updated to convert @comment and @associatedProcessorGroup to '' if null (Ticket #648)
**			02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644, http://prismtrac.pnl.gov/trac/ticket/644)
**			04/22/2008 mem - Updated to call AlterEnteredByUser when updating T_Analysis_Job_Processor_Group_Associations
**			09/12/2008 mem - Now passing @parmFileName and @settingsFileName ByRef to ValidateAnalysisJobParameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**			02/27/2009 mem - Expanded @comment to varchar(512)
**			04/15/2009 grk - handles wildcard DTA folder name in comment field (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**			08/05/2009 grk - assign job number from separate table (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**			05/05/2010 mem - Now passing @ownerPRN to ValidateAnalysisJobParameters as input/output
**			05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**			08/18/2010 mem - Now allowing job update if state is Failed, in addition to New or Holding
**			08/19/2010 grk - try-catch for error handling
**			08/26/2010 mem - Added parameter @PreventDuplicateJobs
**			03/29/2011 grk - Added @specialProcessing argument (http://redmine.pnl.gov/issues/304)
**			04/26/2011 mem - Added parameter @PreventDuplicatesIgnoresNoExport
**			05/24/2011 mem - Now populating column AJ_DatasetUnreviewed when adding new jobs
**			05/03/2012 mem - Added parameter @SpecialProcessingWaitUntilReady
**			06/12/2012 mem - Removed unused code related to Archive State in #TD
**			09/18/2012 mem - Now clearing @organismDBName if @mode='reset' and we're searching a protein collection
**			09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**			01/04/2013 mem - Now ignoring @organismName, @protCollNameList, @protCollOptionsList, and @organismDBName for analysis tools that do not use protein collections (AJT_orgDbReqd = 0)
**			04/02/2013 mem - Now updating @msg if it is blank yet @result is non-zero
**			03/13/2014 mem - Now passing @Job to ValidateAnalysisJobParameters
**			04/08/2015 mem - Now passing @AutoUpdateSettingsFileToCentroided and @Warning to ValidateAnalysisJobParameters
**			05/28/2015 mem - No longer creating processor group entries (thus @associatedProcessorGroup is ignored)
**			06/24/2015 mem - Added parameter @infoOnly
**			07/21/2015 mem - Now allowing job comment and Export Mode to be changed
**			01/20/2016 mem - Update comments
**			02/15/2016 mem - Re-enabled handling of @associatedProcessorGroup
**			02/23/2016 mem - Add set XACT_ABORT on
**          07/20/2016 mem - Expand error messages
**			11/18/2016 mem - Log try/catch errors using PostLogEntry
**    
*****************************************************/
(
    @datasetNum varchar(128),
    @priority int = 2,
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(255),
    @organismName varchar(128),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
	@organismDBName varchar(128),
    @ownerPRN varchar(64),
    @comment varchar(512) = null,
    @specialProcessing varchar(512) = null,
	@associatedProcessorGroup varchar(64) = '',		-- Processor group
    @propagationMode varchar(24),
	@stateName varchar(32),
    @jobNum varchar(32) = '0' output,				-- New job number if adding a job; existing job number if updating or resetting a job
	@mode varchar(12) = 'add', -- or 'update' or 'reset'; use 'previewadd' or 'previewupdate' to validate the parameters but not actually make the change (used by the Spreadsheet loader page)
	@message varchar(512) output,
	@callingUser varchar(128) = '',
	@PreventDuplicateJobs tinyint = 0,				-- Only used if @Mode is 'add'; ignores jobs with state 5 (failed); if @PreventDuplicatesIgnoresNoExport = 1 then also ignores jobs with state 14 (no export)
	@PreventDuplicatesIgnoresNoExport tinyint = 1,
	@SpecialProcessingWaitUntilReady tinyint = 0,	-- When 1, then sets the job state to 19="Special Proc. Waiting" when the @specialProcessing parameter is not empty
	@infoOnly tinyint = 0							-- When 1, preview the change even when @mode is 'add' or 'update'
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @AlterEnteredByRequired tinyint
	set @AlterEnteredByRequired = 0
	
	---------------------------------------------------
	-- Assure that the comment and associated processor group 
	-- variables are not null
	---------------------------------------------------
	
	set @comment = IsNull(@comment, '')
	set @associatedProcessorGroup = IsNull(@associatedProcessorGroup, '')
	set @callingUser = IsNull(@callingUser, '')
	Set @PreventDuplicateJobs = IsNull(@PreventDuplicateJobs, 0)
	Set @PreventDuplicatesIgnoresNoExport = IsNull(@PreventDuplicatesIgnoresNoExport, 1)
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	set @message = ''

	declare @msg varchar(256)

    declare @batchID int
	set @batchID = 0

	BEGIN TRY 

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
			set @msg = 'Cannot update: Analysis Job "' + @jobNum + '" is not in database '
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 4)
		end

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

	if @mode = 'update'
	begin
		-- Changes are typically only allowed to jobs in 'new', 'failed', or 'holding' state
		-- However, we do allow the job comment or export mode to be updated
		--
		If Not @stateID IN (1,5,8,19)
		begin
			-- Allow the job comment and Export Mode to be updated
			
			Declare @currentStateName varchar(32)
			Declare @currentExportMode smallint
			Declare @currentComment varchar(512)
			
			SELECT @currentStateName = ASN.AJS_name,
			       @currentComment = IsNull(J.AJ_comment, ''),
			       @currentExportMode = IsNull(J.AJ_propagationMode, 0)
			FROM T_Analysis_Job J
			     INNER JOIN T_Analysis_State_Name ASN
			       ON J.AJ_StateID = ASN.AJS_stateID
			WHERE J.AJ_jobID = @jobID
			
			If @comment <> @currentComment Or @propMode <> @currentExportMode
			Begin
				If @infoOnly = 0
				Begin					
					UPDATE T_Analysis_Job 
					SET AJ_comment = @comment,
						AJ_propagationMode = @propMode
					WHERE AJ_jobID = @jobID
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
				End				
				
				If @comment <> @currentComment And @propMode <> @currentExportMode 
					Set @message = 'Updated job comment and export mode'
				
				If @message = '' And @comment <> @currentComment
					Set @message = 'Updated job comment'

				If @message = '' And @propMode <> @currentExportMode 
					Set @message = 'Updated export mode'
			
				If @stateName <> @currentStateName
				Begin
					Set @message = @message + '; job state cannot be changed from ' + @currentStateName + ' to ' + @stateName
				End
				
				If @infoOnly <> 0
					Set @message = 'Preview: ' + @message

				Goto Done
			End

			set @msg = 'Cannot update: Analysis Job "' + @jobNum + '" is not in "new", "holding", or "failed" state '
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 5)
		end
	end

	if @mode = 'reset'
	begin
		If @organismDBName Like 'ID[_]%' And IsNull(@protCollNameList, '') Not In ('', 'na')
		Begin
			-- We are resetting a job that used a protein collection; clear @organismDBName
			Set @organismDBName = ''
		End
	end
	
	---------------------------------------------------
	-- Resolve processor group ID
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
			RAISERROR (@msg, 11, 8)
		end
		--
		if @gid = 0
		begin
			set @msg = 'Processor group name not found'
			RAISERROR (@msg, 11, 9)
		end
	end
	
	---------------------------------------------------
	-- Create temporary table to hold the dataset details
	-- This table will only have one row
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
		set @msg = 'Failed to create temporary table #TD'
		If @infoOnly <> 0
			print @msg

		RAISERROR (@msg, 11, 7)
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
		set @msg = 'Error populating temporary table with dataset name'
		If @infoOnly <> 0
			print @msg

		RAISERROR (@msg, 11, 11)
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
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 12)
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
	declare @result int = 0
	declare @Warning varchar(255) = ''
	set @msg = ''
	--
	exec @result = ValidateAnalysisJobParameters
							@toolName = @toolName,
							@parmFileName = @parmFileName output,
							@settingsFileName = @settingsFileName output,
							@organismDBName = @organismDBName output,
							@organismName = @organismName,
							@protCollNameList = @protCollNameList output,
							@protCollOptionsList = @protCollOptionsList output,
							@ownerPRN = @ownerPRN output,
							@mode = @mode, 
							@userID = @userID output,
							@analysisToolID = @analysisToolID output, 
							@organismID = @organismID output,
							@message = @msg output,
							@AutoRemoveNotReleasedDatasets = 0,
							@Job = @jobID,
							@AutoUpdateSettingsFileToCentroided = 1,
							@Warning = @Warning output,
							@showDebugMessages = @infoOnly
	--
	if @result <> 0
	begin
		If IsNull(@msg, '') = ''
			Set @msg = 'Error code ' + Convert(varchar(12), @result) + ' returned by ValidateAnalysisJobParameters'
			
		If @infoOnly <> 0
			print @msg
			
		RAISERROR (@msg, 11, 18)
	end

	If IsNull(@Warning, '') <> ''
	Begin
		Set @comment = dbo.AppendToText(@comment, @Warning, 0, '; ')
		
		If @mode Like 'preview%'
			Set @message = @warning
		
	End
	
	---------------------------------------------------
	-- Lookup the Dataset ID
	---------------------------------------------------
	--
	declare @datasetID int
	--
	SELECT TOP 1 @datasetID = Dataset_ID FROM #TD


	---------------------------------------------------
	-- set up transaction variables
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'AddUpdateAnalysisJob'

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	if @mode = 'add'
	begin

		If @PreventDuplicateJobs <> 0
		Begin
			---------------------------------------------------
			-- See if an existing, matching job already exists
			-- If it does, do not add another job
			---------------------------------------------------
			
			Declare @ExistingJobCount int = 0
			Declare @ExistingMatchingJob int = 0
			
			SELECT @ExistingJobCount = COUNT(*), 
			       @ExistingMatchingJob = MAX(AJ_JobID)
			FROM
				T_Dataset DS INNER JOIN
				T_Analysis_Job AJ ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
				T_Analysis_Tool AJT ON AJ.AJ_analysisToolID = AJT.AJT_toolID INNER JOIN
				T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID  INNER JOIN
				T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID INNER JOIN
				#TD ON #TD.Dataset_Num = DS.Dataset_Num
			WHERE
			    ( @PreventDuplicatesIgnoresNoExport > 0 AND NOT AJ.AJ_StateID IN (5, 14) OR
			    @PreventDuplicatesIgnoresNoExport = 0 AND AJ.AJ_StateID <> 5 
			    ) AND
			    AJT.AJT_toolName = @toolName AND 
			    AJ.AJ_parmFileName = @parmFileName AND 
			    AJ.AJ_settingsFileName = @settingsFileName AND 
			    (
			      ( @protCollNameList = 'na' AND 
			        AJ.AJ_organismDBName = @organismDBName AND 
			        Org.OG_name = IsNull(@organismName, Org.OG_name)
			      ) OR
			      ( @protCollNameList <> 'na' AND 
			        AJ.AJ_proteinCollectionList = IsNull(@protCollNameList, AJ.AJ_proteinCollectionList) AND 
 			        AJ.AJ_proteinOptionsList = IsNull(@protCollOptionsList, AJ.AJ_proteinOptionsList)
			      ) OR 
			      ( AJT.AJT_orgDbReqd = 0 )
			    )
		
			If @ExistingJobCount > 0
			Begin
				set @message = 'Job not created since duplicate job exists: ' + Convert(varchar(12), @ExistingMatchingJob)

				If @infoOnly <> 0
					print @message
				
				-- Do not change this error code since SP CreatePredefinedAnalysesJobs 
				-- checks for error code 52500
				return 52500
			End		
		End
		
		
		---------------------------------------------------
		-- Check whether the dataset is unreviewed
		---------------------------------------------------
		Declare @DatasetUnreviewed tinyint = 0
		
		IF Exists (SELECT * FROM T_Dataset WHERE Dataset_ID = @datasetID AND DS_Rating = -10)
			Set @DatasetUnreviewed = 1


		---------------------------------------------------
		-- Get ID for new job
		---------------------------------------------------
		--
		exec @jobID = GetNewJobID 'Job created in DMS', @infoOnly
		if @jobID = 0
		begin
			set @msg = 'Failed to get valid new job ID'
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 15)
		end
		set @jobNum = cast(@jobID as varchar(32))
	
		declare @newJobNum int
		Set @stateID = 1
		
		If IsNull(@SpecialProcessingWaitUntilReady, 0) > 0 And IsNull(@specialProcessing, '') <> ''
			Set @stateID = 19
		
		If @infoOnly <> 0
		Begin
			SELECT 'Preview ' + @mode as Mode,
			       @jobID AS AJ_jobID,
			       @priority AS AJ_priority,
			       getdate() AS AJ_created,
			       @analysisToolID AS AJ_analysisToolID,
			       @parmFileName AS AJ_parmFileName,
			       @settingsFileName AS AJ_settingsFileName,
			       @organismDBName AS AJ_organismDBName,
			       @protCollNameList AS AJ_proteinCollectionList,
			       @protCollOptionsList AS AJ_proteinOptionsList,
			       @organismID AS AJ_organismID,
			       @datasetID AS AJ_datasetID,
			       REPLACE(@comment, '#DatasetNum#', CONVERT(varchar(12), @datasetID)) AS AJ_comment,
			       @specialProcessing AS AJ_specialProcessing,
			       @ownerPRN AS AJ_owner,
			       @batchID AS AJ_batchID,
			       @stateID AS AJ_StateID,
			       @propMode AS AJ_propagationMode,
			       @DatasetUnreviewed AS AJ_DatasetUnreviewed

		End
		Else
		Begin
			---------------------------------------------------
			-- start transaction
			--
			begin transaction @transName

			---------------------------------------------------
			--
			INSERT INTO T_Analysis_Job (
				AJ_jobID,
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
				AJ_specialProcessing,
				AJ_owner,
				AJ_batchID,
				AJ_StateID,
				AJ_propagationMode,
				AJ_DatasetUnreviewed
			) VALUES (
				@jobID,
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
				REPLACE(@comment, '#DatasetNum#', CONVERT(varchar(12), @datasetID)),
				@specialProcessing,
				@ownerPRN,
				@batchID,
				@stateID,
				@propMode,
				@DatasetUnreviewed
			)			
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Insert new job operation failed'
				If @infoOnly <> 0
					print @msg

				RAISERROR (@msg, 11, 13)
			end

			-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
			If Len(@callingUser) > 0
				Exec AlterEventLogEntryUser 5, @jobID, @stateID, @callingUser

			---------------------------------------------------
			-- Associate job with processor group
			--
			if @gid <> 0
			begin
				INSERT INTO T_Analysis_Job_Processor_Group_Associations
					(Job_ID, Group_ID)
				VALUES
					(@jobID, @gid)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Insert new job association failed'
					RAISERROR (@msg, 11, 14)
				end
			end
			
			commit transaction @transName
		End
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
		set @stateID = -1
		--
		if @mode = 'reset' 
		begin
			set @stateID = 1
		end
		else
		begin
			--
			SELECT @stateID = AJS_stateID
			FROM T_Analysis_State_Name
			WHERE (AJS_name = @stateName)		
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error looking up state name'
				If @infoOnly <> 0
					print @msg

				RAISERROR (@msg, 11, 15)
			end
			
			if @stateID = -1
			begin
				set @msg = 'State name not recognized: ' + @stateName
				If @infoOnly <> 0
					print @msg

				RAISERROR (@msg, 11, 15)
			end
		end		

		---------------------------------------------------
		-- Associate job with processor group
		---------------------------------------------------
		--		
		-- Is there an existing association between the job
		-- and a processor group?
		--
		declare @pgaAssocID int
		set @pgaAssocID = 0
		--
		SELECT @pgaAssocID = Group_ID
		FROM T_Analysis_Job_Processor_Group_Associations
		WHERE Job_ID = @jobID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up existing job association'
			RAISERROR (@msg, 11, 16)
		end

		If @infoOnly <> 0
		Begin
			SELECT 'Preview ' + @mode as Mode,
			       @jobID AS AJ_jobID,
			       @priority AS AJ_priority,
			       AJ_created,
			       @analysisToolID AS AJ_analysisToolID,
			       @parmFileName AS AJ_parmFileName,
			       @settingsFileName AS AJ_settingsFileName,
			       @organismDBName AS AJ_organismDBName,
			       @protCollNameList AS AJ_proteinCollectionList,
			       @protCollOptionsList AS AJ_proteinOptionsList,
			       @organismID AS AJ_organismID,
			       @datasetID AS AJ_datasetID,
			       @comment AJ_comment,
			       @specialProcessing AS AJ_specialProcessing,
			       @ownerPRN AS AJ_owner,
			       AJ_batchID,
			       @stateID AS AJ_StateID,
			       CASE WHEN @mode <> 'reset' THEN AJ_start ELSE NULL END AS AJ_start, 
				   CASE WHEN @mode <> 'reset' THEN AJ_finish ELSE NULL END AS AJ_finish,
			       @propMode AS AJ_propagationMode,
			       AJ_DatasetUnreviewed
			FROM T_Analysis_Job
			WHERE (AJ_jobID = @jobID)
			
		End
		Else
		Begin		
			---------------------------------------------------
			-- start transaction
			--
			begin transaction @transName

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
				AJ_specialProcessing = @specialProcessing,
				AJ_owner = @ownerPRN,
				AJ_StateID = @stateID,
				AJ_start = CASE WHEN @mode <> 'reset' THEN AJ_start ELSE NULL END, 
				AJ_finish = CASE WHEN @mode <> 'reset' THEN AJ_finish ELSE NULL END,
				AJ_propagationMode = @propMode
			WHERE (AJ_jobID = @jobID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed: "' + @jobNum + '"'
				RAISERROR (@msg, 11, 17)
			end

			-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
			If Len(@callingUser) > 0
				Exec AlterEventLogEntryUser 5, @jobID, @stateID, @callingUser

			---------------------------------------------------
			-- Deal with job association with group, 
			---------------------------------------------------
			--
			-- If no group is given, but existing association
			-- exists for job, delete it
			--
			if @gid = 0
			begin
				DELETE FROM T_Analysis_Job_Processor_Group_Associations
				WHERE (Job_ID = @jobID)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-- If group is given, and no association for job exists
			-- create one
			--
			if @gid <> 0 and @pgaAssocID = 0
			begin
				INSERT INTO T_Analysis_Job_Processor_Group_Associations
					(Job_ID, Group_ID)
				VALUES
					(@jobID, @gid)				
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				
				Set @AlterEnteredByRequired = 1
			end

			-- If group is given, and an association for job does exist
			-- update it
			--
			if @gid <> 0 and @pgaAssocID <> 0 and @pgaAssocID <> @gid
			begin
				UPDATE T_Analysis_Job_Processor_Group_Associations
					SET Group_ID = @gid,
						Entered = GetDate(),
						Entered_By = suser_sname()
				WHERE
					Job_ID = @jobID				
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				
				Set @AlterEnteredByRequired = 1
			end
			
			-- Report error, if one occurred
			--
			if @myError <> 0
			begin
				set @msg = 'Error deleting existing association for job'
				RAISERROR (@msg, 11, 21)
			end

			commit transaction @transName
			
			If Len(@callingUser) > 0 AND @AlterEnteredByRequired <> 0
			Begin
				-- Call AlterEnteredByUser
				-- to alter the Entered_By field in T_Analysis_Job_Processor_Group_Associations
			
				Exec AlterEnteredByUser 'T_Analysis_Job_Processor_Group_Associations', 'Job_ID', @jobID, @CallingUser
			End
		End
		
	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		exec PostLogEntry 'Error', @message, 'AddUpdateAnalysisJob'		
	END CATCH

Done:

	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJob] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJob] TO [PNL\D3M580] AS [dbo]
GO

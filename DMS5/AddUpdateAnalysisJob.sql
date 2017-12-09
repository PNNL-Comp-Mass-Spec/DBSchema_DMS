/****** Object:  StoredProcedure [dbo].[AddUpdateAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[AddUpdateAnalysisJob]
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
**			02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Expand error messages
**			11/18/2016 mem - Log try/catch errors using PostLogEntry
**			12/05/2016 mem - Exclude logging some try/catch errors
**			12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**			06/09/2017 mem - Add support for state 13 (inactive)
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**			11/09/2017 mem - Allow job state to be changed from Complete (state 4) to No Export (state 14) if @propagationMode is 1 (aka 'No Export')
**			12/06/2017 mem - Set @allowNewDatasets to 0 when calling ValidateAnalysisJobParameters
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
    @propagationMode varchar(24),					-- Propagation mode, aka export mode
	@stateName varchar(32),
    @jobNum varchar(32) = '0' output,				-- New job number if adding a job; existing job number if updating or resetting a job
	@mode varchar(12) = 'add', -- or 'update' or 'reset'; use 'previewadd' or 'previewupdate' to validate the parameters but not actually make the change (used by the Spreadsheet loader page)
	@message varchar(512) output,
	@callingUser varchar(128) = '',
	@PreventDuplicateJobs tinyint = 0,				-- Only used if @Mode is 'add'; ignores jobs with state 5 (failed), 13 (inactive) or 14 (no export)
	@PreventDuplicatesIgnoresNoExport tinyint = 1,
	@SpecialProcessingWaitUntilReady tinyint = 0,	-- When 1, then sets the job state to 19="Special Proc. Waiting" when the @specialProcessing parameter is not empty
	@infoOnly tinyint = 0							-- When 1, preview the change even when @mode is 'add' or 'update'
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0

	Declare @AlterEnteredByRequired tinyint = 0
	
	---------------------------------------------------
	-- Assure that the comment and associated processor group 
	-- variables are not null
	---------------------------------------------------
	
	Set @comment = IsNull(@comment, '')
	Set @associatedProcessorGroup = IsNull(@associatedProcessorGroup, '')
	Set @callingUser = IsNull(@callingUser, '')
	Set @PreventDuplicateJobs = IsNull(@PreventDuplicateJobs, 0)
	Set @PreventDuplicatesIgnoresNoExport = IsNull(@PreventDuplicatesIgnoresNoExport, 1)
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	Set @message = ''

	Declare @msg varchar(256)

    Declare @batchID int = 0
    Declare @logErrors tinyint = 0

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateAnalysisJob', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	Begin Try 

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates and resets)
	---------------------------------------------------

	Declare @jobID int = 0
	Declare @currentStateID int = 0

	If @mode = 'update' or @mode = 'reset'
	Begin
		-- cannot update a non-existent entry
		--
		SELECT 
			@jobID = AJ_jobID,
			@currentStateID = AJ_StateID
		FROM T_Analysis_Job
		WHERE AJ_jobID = Try_Cast(@jobNum AS int)

		If @jobID = 0
		Begin	
			Set @msg = 'Cannot update: Analysis Job "' + @jobNum + '" is not in database'
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 4)
		End

	End

	---------------------------------------------------
	-- Resolve propagation mode 
	---------------------------------------------------
	Declare @propMode smallint
	Set @propMode = CASE @propagationMode 
						WHEN 'Export' THEN 0 
						WHEN 'No Export' THEN 1 
						ELSE 0 
					End 

	If @mode = 'update'
	Begin
		-- Changes are typically only allowed to jobs in 'new', 'failed', or 'holding' state
		-- However, we do allow the job comment or export mode to be updated
		--
		If Not @currentStateID IN (1,5,8,19)
		Begin
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
			
			If @comment <> @currentComment Or 
			   @propMode <> @currentExportMode Or 
			   @currentStateName = 'Complete' And @stateName = 'No export'
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
					If @propMode = 1 And @currentStateName = 'Complete' And @stateName = 'No export'
					Begin
						If @infoOnly = 0
						Begin
							UPDATE T_Analysis_Job 
							SET AJ_StateID = 14
							WHERE AJ_jobID = @jobID
							--
							SELECT @myError = @@error, @myRowCount = @@rowcount
						End

						Set @message = dbo.AppendToText(@message, 'set job state to "No export"', 0, '; ')						
					End
					Else
					Begin
						Set @msg = 'job state cannot be changed from ' + @currentStateName + ' to ' + @stateName
						Set @message = dbo.AppendToText(@message, @msg, 0, '; ')
							
						If @propagationMode = 'Export' And @stateName = 'No export'
						Begin
							-- Job propagation mode is Export (0) but user wants to set the state to No export							
							Set @message = dbo.AppendToText(@message, 'to make this change, set the Export Mode to "No Export"', 0, '; ')
						End
					End
				End
				
				If @infoOnly <> 0
					Set @message = 'Preview: ' + @message

				Goto Done
			End

			set @msg = 'Cannot update: Analysis Job "' + @jobNum + '" is not in "new", "holding", or "failed" state'
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 5)
		End
	End

	If @mode = 'reset'
	Begin
		If @organismDBName Like 'ID[_]%' And IsNull(@protCollNameList, '') Not In ('', 'na')
		Begin
			-- We are resetting a job that used a protein collection; clear @organismDBName
			Set @organismDBName = ''
		End
	End
	
	---------------------------------------------------
	-- Resolve processor group ID
	---------------------------------------------------
	--
	Declare @gid int = 0
	--
	If @associatedProcessorGroup <> ''
	Begin
		SELECT @gid = ID
		FROM T_Analysis_Job_Processor_Group
		WHERE (Group_Name = @associatedProcessorGroup)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			set @msg = 'Error trying to resolve processor group name'
			RAISERROR (@msg, 11, 8)
		End
		--
		If @gid = 0
		Begin
			set @msg = 'Processor group name not found'
			RAISERROR (@msg, 11, 9)
		End
	End
	
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
	If @myError <> 0
	Begin
		set @msg = 'Failed to create temporary table #TD'
		If @infoOnly <> 0
			print @msg

		RAISERROR (@msg, 11, 7)
	End

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
	If @myError <> 0
	Begin
		set @msg = 'Error populating temporary table with dataset name'
		If @infoOnly <> 0
			print @msg

		RAISERROR (@msg, 11, 11)
	End

	---------------------------------------------------
	-- handle '(default)' organism  
	---------------------------------------------------

	If @organismName = '(default)'
	Begin
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
		If @myError <> 0
		Begin
			set @msg = 'Error resolving default organism name'
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 12)
		End
	End

	---------------------------------------------------
	-- validate job parameters
	---------------------------------------------------
	--
	Declare @userID int
	Declare @analysisToolID int
	Declare @organismID int
	--
	Declare @result int = 0
	
	Declare @Warning varchar(255) = ''
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
							@allowNewDatasets = 0,
							@Warning = @Warning output,
							@showDebugMessages = @infoOnly
	--
	If @result <> 0
	Begin
		If IsNull(@msg, '') = ''
			Set @msg = 'Error code ' + Convert(varchar(12), @result) + ' returned by ValidateAnalysisJobParameters'
			
		If @infoOnly <> 0
			print @msg
			
		RAISERROR (@msg, 11, 18)
	End

	If IsNull(@Warning, '') <> ''
	Begin
		Set @comment = dbo.AppendToText(@comment, @Warning, 0, '; ')
		
		If @mode Like 'preview%'
			Set @message = @warning
		
	End
	
	Set @logErrors = 1
	
	---------------------------------------------------
	-- Lookup the Dataset ID
	---------------------------------------------------
	--
	Declare @datasetID int
	--
	SELECT TOP 1 @datasetID = Dataset_ID FROM #TD


	---------------------------------------------------
	-- set up transaction variables
	---------------------------------------------------
	--
	Declare @transName varchar(32) = 'AddUpdateAnalysisJob'

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	If @mode = 'add'
	Begin

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
			    ( @PreventDuplicatesIgnoresNoExport > 0 AND NOT AJ.AJ_StateID IN (5, 13, 14) OR
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
		If @jobID = 0
		Begin
			set @msg = 'Failed to get valid new job ID'
			If @infoOnly <> 0
				print @msg

			RAISERROR (@msg, 11, 15)
		End
		set @jobNum = cast(@jobID as varchar(32))
	
		Declare @newJobNum int
		Declare @newStateID int = 1
		
		If IsNull(@SpecialProcessingWaitUntilReady, 0) > 0 And IsNull(@specialProcessing, '') <> ''
			Set @newStateID = 19
		
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
			       @newStateID AS AJ_StateID,
			    @propMode AS AJ_propagationMode,
			       @DatasetUnreviewed AS AJ_DatasetUnreviewed

		End
		Else
		Begin
			---------------------------------------------------
			-- start transaction
			--
			Begin transaction @transName

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
				@newStateID,
				@propMode,
				@DatasetUnreviewed
			)			
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			If @myError <> 0
			Begin
				set @msg = 'Insert new job operation failed'
				If @infoOnly <> 0
					print @msg

				RAISERROR (@msg, 11, 13)
			End

			-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
			If Len(@callingUser) > 0
				Exec AlterEventLogEntryUser 5, @jobID, @newStateID, @callingUser

			---------------------------------------------------
			-- Associate job with processor group
			--
			If @gid <> 0
			Begin
				INSERT INTO T_Analysis_Job_Processor_Group_Associations
					(Job_ID, Group_ID)
				VALUES
					(@jobID, @gid)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				If @myError <> 0
				Begin
					set @msg = 'Insert new job association failed'
					RAISERROR (@msg, 11, 14)
				End
			End
			
			commit transaction @transName
		End
	End -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	If @mode = 'update' or @mode = 'reset' 
	Begin
		set @myError = 0

		---------------------------------------------------
		-- Resolve state ID according to mode and state name
		--
		Declare @updateStateID int = -1
		--
		If @mode = 'reset' 
		Begin
			set @updateStateID = 1
		End
		Else
		Begin
			--
			SELECT @updateStateID = AJS_stateID
			FROM T_Analysis_State_Name
			WHERE (AJS_name = @stateName)		
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			If @myError <> 0
			Begin
				set @msg = 'Error looking up state name'
				If @infoOnly <> 0
					print @msg

				RAISERROR (@msg, 11, 15)
			End
			
			If @updateStateID = -1
			Begin
				set @msg = 'State name not recognized: ' + @stateName
				If @infoOnly <> 0
					print @msg

				RAISERROR (@msg, 11, 15)
			End
		End		

		---------------------------------------------------
		-- Associate job with processor group
		---------------------------------------------------
		--		
		-- Is there an existing association between the job
		-- and a processor group?
		--
		Declare @pgaAssocID int = 0
		--
		SELECT @pgaAssocID = Group_ID
		FROM T_Analysis_Job_Processor_Group_Associations
		WHERE Job_ID = @jobID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			set @msg = 'Error looking up existing job association'
			RAISERROR (@msg, 11, 16)
		End

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
			       @updateStateID AS AJ_StateID,
			       CASE WHEN @mode <> 'reset' THEN AJ_start ELSE NULL End AS AJ_start, 
				   CASE WHEN @mode <> 'reset' THEN AJ_finish ELSE NULL End AS AJ_finish,
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
			Begin transaction @transName

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
				AJ_StateID = @updateStateID,
				AJ_start = CASE WHEN @mode <> 'reset' THEN AJ_start ELSE NULL End, 
				AJ_finish = CASE WHEN @mode <> 'reset' THEN AJ_finish ELSE NULL End,
				AJ_propagationMode = @propMode
			WHERE (AJ_jobID = @jobID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			If @myError <> 0
			Begin
				set @msg = 'Update operation failed: "' + @jobNum + '"'
				RAISERROR (@msg, 11, 17)
			End

			-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
			If Len(@callingUser) > 0
				Exec AlterEventLogEntryUser 5, @jobID, @updateStateID, @callingUser

			---------------------------------------------------
			-- Deal with job association with group, 
			---------------------------------------------------
			--
			-- If no group is given, but existing association
			-- exists for job, delete it
			--
			If @gid = 0
			Begin
				DELETE FROM T_Analysis_Job_Processor_Group_Associations
				WHERE (Job_ID = @jobID)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			End

			-- If group is given, and no association for job exists
			-- create one
			--
			If @gid <> 0 and @pgaAssocID = 0
			Begin
				INSERT INTO T_Analysis_Job_Processor_Group_Associations
					(Job_ID, Group_ID)
				VALUES
					(@jobID, @gid)				
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				
				Set @AlterEnteredByRequired = 1
			End

			-- If group is given, and an association for job does exist
			-- update it
			--
			If @gid <> 0 and @pgaAssocID <> 0 and @pgaAssocID <> @gid
			Begin
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
			End
			
			-- Report error, if one occurred
			--
			If @myError <> 0
			Begin
				Set @msg = 'Error deleting existing association for job'
				RAISERROR (@msg, 11, 21)
			End

			commit transaction @transName
			
			If Len(@callingUser) > 0 AND @AlterEnteredByRequired <> 0
			Begin
				-- Call AlterEnteredByUser
				-- to alter the Entered_By field in T_Analysis_Job_Processor_Group_Associations
			
				Exec AlterEnteredByUser 'T_Analysis_Job_Processor_Group_Associations', 'Job_ID', @jobID, @CallingUser
			End
		End
		
	End -- update mode

	End Try
	Begin Catch
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;


		If @logErrors > 0
		Begin
			Declare @logMessage varchar(1024) = @message + '; Job ' + @jobNum
			exec PostLogEntry 'Error', @logMessage, 'AddUpdateAnalysisJob'
		End
			
		
	End Catch

Done:

	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO

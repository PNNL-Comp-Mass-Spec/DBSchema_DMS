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
**			04/07/2006 grk - revised valiation logic to use ValidateAnalysisJobParameters
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
**    
*****************************************************/
(
    @datasetNum varchar(128),
    @priority int = 2,
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(255),
    @organismName varchar(64),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
	@organismDBName varchar(64),
    @ownerPRN varchar(64),
    @comment varchar(512) = null,
    @specialProcessing varchar(512) = null,
	@associatedProcessorGroup varchar(64),
    @propagationMode varchar(24),
	@stateName varchar(32),
    @jobNum varchar(32) = '0' output,
	@mode varchar(12) = 'add', -- or 'update' or 'reset'
	@message varchar(512) output,
	@callingUser varchar(128) = '',
	@PreventDuplicateJobs tinyint = 0,				-- Only used if @Mode is 'add'; ignores jobs with state 5 (failed); if @PreventDuplicatesIgnoresNoExport = 1 then also ignores jobs with state 14 (no export)
	@PreventDuplicatesIgnoresNoExport tinyint = 1,
	@SpecialProcessingWaitUntilReady tinyint = 0		-- When 1, then sets the job state to 19="Special Proc. Waiting" when the @specialProcessing parameter is not empty
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
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
			set @msg = 'Cannot update:  Analysis Job "' + @jobNum + '" is not in database '
			RAISERROR (@msg, 11, 4)
		end
	end

	if @mode = 'update'
	begin
		-- changes only allowed to jobs in 'new', 'failed', or 'holding' state
		--
		If Not @stateID IN (1,5,8,19)
		begin
			set @msg = 'Cannot update:  Analysis Job "' + @jobNum + '" is not in "new", "holding", or "failed" state '
			RAISERROR (@msg, 11, 5)
		end
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
	-- Create temporary table to hold "list" of the dataset
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
		set @msg = 'Error populating temporary table'
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
			RAISERROR (@msg, 11, 12)
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
							@parmFileName output,
							@settingsFileName output,
							@organismDBName output,
							@organismName,
							@protCollNameList output,
							@protCollOptionsList output,
							@ownerPRN output,
							@mode, 
							@userID output,
							@analysisToolID output, 
							@organismID output,
							@msg output
	--
	if @result <> 0
	begin
		RAISERROR (@msg, 11, 18)
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
				  @PreventDuplicatesIgnoresNoExport = 0 AND AJ.AJ_StateID <> 5              ) AND
				AJT.AJT_toolName = @toolName AND 
				AJ.AJ_parmFileName = @parmFileName AND 
				AJ.AJ_settingsFileName = @settingsFileName AND 
				( (	@protCollNameList = 'na' AND AJ.AJ_organismDBName = @organismDBName AND 
					Org.OG_name = IsNull(@organismName, Org.OG_name)
				) OR
				(	@protCollNameList <> 'na' AND 
					AJ.AJ_proteinCollectionList = IsNull(@protCollNameList, AJ.AJ_proteinCollectionList) AND 
					AJ.AJ_proteinOptionsList = IsNull(@protCollOptionsList, AJ.AJ_proteinOptionsList)
				) 
				)
		
			If @ExistingJobCount > 0
			Begin
				set @message = 'Job not created since duplicate job exists: ' + Convert(varchar(12), @ExistingMatchingJob)
				
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
		-- get ID for new job (#744)
		---------------------------------------------------
		--
		exec @jobID = GetNewJobID 'Job created in DMS'
		if @jobID = 0
		begin
			set @msg = 'Failed to get valid new job ID'
			RAISERROR (@msg, 11, 15)
		end
		set @jobNum = cast(@jobID as varchar(32))
	
		declare @newJobNum int
		Set @stateID = 1
		
		If IsNull(@SpecialProcessingWaitUntilReady, 0) > 0 And IsNull(@specialProcessing, '') <> ''
			Set @stateID = 19
			
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
			RAISERROR (@msg, 11, 13)
		end

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 5, @jobID, @stateID, @callingUser
			
		-- associate job with processor group
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
			SELECT @stateID =  AJS_stateID
			FROM T_Analysis_State_Name
			WHERE (AJS_name = @stateName)		
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error looking up state name'
				RAISERROR (@msg, 11, 15)
			end
			
			if @stateID = -1
			begin
				set @msg = 'State name not recognized: ' + @stateName
				RAISERROR (@msg, 11, 15)
			end
		end		

		---------------------------------------------------
		-- is there an existing association between the job
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
		-- deal with job association with group, 

		-- if no group is given, but existing association
		-- exists for job, delete it
		--
		if @gid = 0
		begin
			DELETE FROM T_Analysis_Job_Processor_Group_Associations
			WHERE (Job_ID = @jobID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end

		-- if group is given, and no association for job exists
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

		-- if group is given, and an association for job does exist
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
	
		-- report error, if one occurred
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
		
	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
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

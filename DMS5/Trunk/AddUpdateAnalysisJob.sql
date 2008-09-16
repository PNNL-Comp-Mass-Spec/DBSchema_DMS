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
**    
*****************************************************/
(
    @datasetNum varchar(128),
    @priority int = 2,
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(64),
    @organismName varchar(64),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
	@organismDBName varchar(64),
    @ownerPRN varchar(32),
    @comment varchar(255) = null,
	@associatedProcessorGroup varchar(64),
    @propagationMode varchar(24),
	@stateName varchar(32),
    @jobNum varchar(32) = "0" output,
	@mode varchar(12) = 'add', -- or 'update' or 'reset'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
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
		-- changes only allowed to jobs in 'new' or 'holding' state
		--
		if @stateID <> 1 and @stateID <> 8
		begin
				set @msg = 'Cannot update:  Analysis Job "' + @jobNum + '" is not in "new" or "holding" state '
				RAISERROR (@msg, 10, 1)
				return 51005
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
		return 51011
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
	
		declare @newJobNum int
		Set @stateID = 1
		
		---------------------------------------------------
		-- start transaction
		--
		begin transaction @transName

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
			AJ_propagationMode
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
			@stateID,
			@propMode
		)			
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Insert new job operation failed'
			RAISERROR (@msg, 10, 1)
			return 51013
		end
		
		-- return job number of newly created job
		--
		set @jobID = IDENT_CURRENT('T_Analysis_Job')
		set @jobNum = cast(@jobID as varchar(32))

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
				rollback transaction @transName
				set @msg = 'Insert new job association failed'
				RAISERROR (@msg, 10, 1)
				return 51014
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
				return 51015
			end
		end		

		---------------------------------------------------
		-- is there an existing association between the job
		-- that a processor group?
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
			RAISERROR (@msg, 10, 1)
			return 51016
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
			rollback transaction @transName
			set @msg = 'Update operation failed: "' + @jobNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51017
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
			rollback transaction @transName
			set @msg = 'Error deleting existing association for job'
			RAISERROR (@msg, 10, 1)
			return 51021
		end

		commit transaction @transName
		
		If Len(@callingUser) > 0 AND @AlterEnteredByRequired <> 0
		Begin
			-- Call AlterEnteredByUser
			-- to alter the Entered_By field in T_Analysis_Job_Processor_Group_Associations
		
			Exec AlterEnteredByUser 'T_Analysis_Job_Processor_Group_Associations', 'Job_ID', @jobID, @CallingUser
		End
		
	end -- update mode

	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS_Analysis]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS_SP_User]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJob] TO [DMS2_SP_User]
GO

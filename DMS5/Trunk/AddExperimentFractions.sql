/****** Object:  StoredProcedure [dbo].[AddExperimentFractions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddExperimentFractions
/****************************************************
**
**	Desc: 
**    Creates a group of new experiments in DMS
**    that are fractionated from a
**    parent experiment.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	kja
**	Date:	05/28/2005
**          05/29/2005 grk - added mods to better work with entry page
**          05/31/2005 grk - added mods for separate group members table
**          06/10/2005 grk - added handling for sample prep request
**          10/04/2005 grk - added call to AddExperimentCellCulture
**          10/04/2005 grk - added override for request ID
**          10/28/2005 grk - added handling for internal standard
**          11/11/2005 grk - added handling for postdigest internal standard
**          12/20/2005 grk - added handling for separate user
**          02/06/2006 grk - increased maximum count
**          01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**			09/27/2007 mem - Moved the copying of AuxInfo to occur after the new experiments have been created and to use CopyAuxInfoMultiID (Ticket #538)
**			10/22/2008 grk - Added container field (Ticket http://prismtrac.pnl.gov/trac/ticket/697)
**    
*****************************************************/
(
	@parentExperiment varchar(128),       -- Parent experiment for group (must already exist)
	@groupType varchar(20) = 'Fraction',  -- 'None', 'Fraction'
	@description varchar(512),            -- Purpose of group
	@totalCount int,                      -- Number of new experiments to automatically create
	@startingIndex int = 1,               -- Initial index for automatic naming of new experiments
	@step int = 1,                        -- Step interval in index
	@groupID int,                         -- ID of newly created experiment group
	@requestOverride varchar(12) = 'parent',   -- ID of request for fractions (if different than parent)
	@internalStandard varchar(50) = 'parent',
	@postdigestIntStd varchar(50) = 'parent',
	@researcher varchar(50) = 'parent',
	@mode varchar(12),                    -- Not used at present - included for consistentcy
	@message varchar(512) output,
   	@callingUser varchar(128) = '',
	@container varchar(128) = 'na'        -- na, "parent", "-20", or actual container ID
)
AS
	SET NOCOUNT ON
	declare @myError int
	set @myError = 0
	declare @myRowCount int
	
	declare @fractionCount int
	set @fractionCount = 0
	declare @maxCount smallint
	set @maxCount = 200
	
	Declare @fractionNumberText varchar(2)
	
	declare @fullFractionCount int
	declare @newExpID int
	declare @matchCount int

	declare @msg varchar(256)
	
	-- T_Experiments column variables
	--
	declare @researcherPRN varchar(50)
	declare @organismID int
	declare @reason varchar(500)
	declare @comment varchar(500)
	declare @created datetime
	declare @sampleConc varchar(50)
	declare @labNotebook varchar(50)
	declare @campaignID int
	declare @cellCultureList varchar(1024)
	declare @labelling varchar(64)
	declare @enzymeID int
	declare @samplePrepRequest int
	declare @internalStandardID int
	declare @postdigestIntStdID int

	declare @ExperimentIDList varchar(8000)
	Set @ExperimentIDList = ''

	declare @MaterialIDList varchar(8000)
	Set @MaterialIDList = ''

	---------------------------------------------------
	-- Validate arguments
	---------------------------------------------------
	
	-- don't allow too many child experiments to be created
	--
	if @totalCount > @maxCount
	begin
		set @message = 'Cannot create more than ' + convert(varchar(12), @maxCount) + ' child experments'
		RAISERROR (@message, 10, 1)
		set @myError = 51004
		goto Done
	end

	-- make sure that we don't overflow our alloted space for digits
	--
	if @startingIndex + (@totalCount * @step) > 999
	begin
		set @message = 'Automatic numbering parameters will require too many digits'
		RAISERROR (@message, 10, 1)
		set @myError = 51005
		goto Done
	end

	---------------------------------------------------
	-- Get information for parent experiment
	---------------------------------------------------
	
	declare @ParentExperimentID int
	set @ParentExperimentID = 0
	declare @parentContainerID int
	set @parentContainerID = 0
	--
	SELECT
		@ParentExperimentID = Exp_ID,
		@researcherPRN = EX_researcher_PRN,
		@organismID = EX_organism_ID,
		@reason = EX_reason,
		@comment = EX_comment,
		@created = EX_created,
		@sampleConc = EX_sample_concentration,
		@labNotebook = EX_lab_notebook_ref,
		@campaignID = EX_campaign_ID,
		@cellCultureList = EX_cell_culture_list,
		@labelling = EX_Labelling,
		@enzymeID = EX_enzyme_ID,
		@samplePrepRequest = EX_sample_prep_request_ID,
		@internalStandardID = EX_internal_standard_ID,
		@postdigestIntStdID = EX_postdigest_internal_std_ID,
		@parentContainerID = EX_Container_ID
	FROM	T_Experiments
	WHERE (Experiment_Num = @parentExperiment)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 OR @ParentExperimentID = 0
	begin
		set @message = 'Could not find parent experiment in database'
		RAISERROR (@message, 10, 1)
		set @myError = 51006
		goto Done
	end

	---------------------------------------------------
	-- override request ID
	---------------------------------------------------

	if @requestOverride <> 'parent'
	begin
		Set @samplePrepRequest = CONVERT(int, @requestOverride)
		Set @matchCount = 0
		
		SELECT @matchCount = COUNT(*)
		FROM T_Sample_Prep_Request
		WHERE ID = @samplePrepRequest
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @matchCount <> 1
		begin
			set @message = 'Could not find sample prep request'
			RAISERROR (@message, 10, 1)
			set @myError = 51029
			goto Done
		end
	end

	---------------------------------------------------
	-- Resolve predigest internal standard ID
	---------------------------------------------------
	if @internalStandard <> 'parent'
	begin
		declare @tmpID int
		set @tmpID = Null
		--
		SELECT @tmpID = Internal_Std_Mix_ID
		FROM T_Internal_Standards
		WHERE (Name = @internalStandard)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myRowCount = 0
		begin
			set @message = 'Could not find entry in database for internal standard "' + @internalStandard + '"'
			RAISERROR (@message, 10, 1)
			return 51009
		end
		Set @internalStandardID = @tmpID
	end

	---------------------------------------------------
	-- Resolve postdigestion internal standard ID
	---------------------------------------------------
	-- 
	if @postdigestIntStd <> 'parent'
	begin
		set @tmpID = Null
		--
		SELECT @tmpID = Internal_Std_Mix_ID
		FROM T_Internal_Standards
		WHERE (Name = @postdigestIntStd)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myRowCount = 0
		begin
			set @message = 'Could not find entry in database for postdigestion internal standard "' + @tmpID + '"'
			RAISERROR (@message, 10, 1)
			return 51009
		end
		Set @postdigestIntStdID = @tmpID
	end

	---------------------------------------------------
	-- Resolve researcher
	---------------------------------------------------
	-- 
	if @researcher <> 'parent'
	begin
		set @researcherPRN = @researcher
	end

	
	---------------------------------------------------
	-- Set up transaction around multiple table modifications
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'AddBatchExperimentEntry'
	begin transaction @transName
	
	---------------------------------------------------
	-- Make Experiment group entry
	---------------------------------------------------
	
	INSERT INTO T_Experiment_Groups (
		EG_Group_Type,
		Parent_Exp_ID,
		 EG_Description,
		 EG_Created
	) VALUES (
		@groupType,
		@ParentExperimentID,
		@description,
		GETDATE()
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to insert of new group entry into database'
		RAISERROR (@message, 10, 1)
		set @myError = 51007
		goto Done
	end
	
	set @groupID = SCOPE_IDENTITY()

	---------------------------------------------------
	-- Add parent experiment to reference group
	---------------------------------------------------
	
	INSERT INTO T_Experiment_Group_Members
		(Group_ID, Exp_ID)
	VALUES (@groupID, @ParentExperimentID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to update group reference for experiment'
		RAISERROR (@message, 10, 1)
		set @myError = 51008
		goto Done
	end

	---------------------------------------------------
	-- Insert Fractionated experiment entries
	---------------------------------------------------
	declare @newComment varchar(500)
	declare @newExpName varchar(129)
	declare @xID int
	declare @result int
	
	WHILE @fractionCount < @totalCount and @myError = 0
	BEGIN -- <a>
		-- build name for new experiment fraction
		--
		set @fullFractionCount = @startingIndex + @fractionCount
		set @fractionNumberText = CAST(@fullFractionCount as varchar(3))
		if  @fullFractionCount < 10
		begin
			set @fractionNumberText = '0' + @fractionNumberText
		end

		set @fractionCount = @fractionCount + @step
		set @newComment = '(Fraction ' + CAST(@fullfractioncount as varchar(3)) + ' of ' + CAST(@totalcount as varchar(3)) + ')'
		set @newExpName = @parentExperiment + '_' + @fractionNumberText

		-- verify that experiment name is not duplicated in table
		--
		set @xID = 0
		execute @xID = GetexperimentID @newExpName
		--
		if @xID <> 0
		begin
			rollback transaction @transName
			set @message = 'Failed to add new fraction experiment because name already in database'
			set @myError = 51002
			RAISERROR (@message, 10, 1)
			goto Done
		end

		-- insert new experiment into database
		--
		INSERT INTO [T_Experiments] (
			Experiment_Num, 
			EX_researcher_PRN, 
			EX_organism_ID, 
			EX_reason, 
			EX_comment,
			EX_created, 
			EX_sample_concentration, 
			EX_lab_notebook_ref, 
			EX_campaign_ID,
			EX_cell_culture_list,
			EX_Labelling,
			EX_enzyme_ID,
			EX_sample_prep_request_ID,
			EX_internal_standard_ID,
			EX_postdigest_internal_std_ID
		) VALUES (
			@newExpName, 
			@researcherPRN, 
			@organismID, 
			@reason, 
			@newComment,
			GETDATE(), 
			@sampleConc, 
			@labNotebook, 
			@campaignID,
			@cellCultureList,
			@labelling,
			@enzymeID,
			@samplePrepRequest,
			@internalStandardID,
			@postdigestIntStdID
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Insert operation failed!'
			RAISERROR (@message, 10, 1)
			goto Done
		end
		
		set @newExpID = SCOPE_IDENTITY()

		-- Add the cell cultures
		--
		execute @result = AddExperimentCellCulture
								@newExpID,
								@cellCultureList,
								@message output
		--
		if @result <> 0
		begin
			set @msg = 'Could not add experiment cell cultures to database for experiment: "' + @newExpName + '" ' + @message
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return @result
		end


		---------------------------------------------------
		-- Add fractionated experiment reference to experiment group
		---------------------------------------------------
		
		INSERT INTO T_Experiment_Group_Members
			(Group_ID, Exp_ID)
		VALUES (@groupID, @newExpID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Failed to update group reference for new experiment'
			RAISERROR (@message, 10, 1)
			set @myError = 51008
			goto Done
		end
	
		---------------------------------------------------
		-- Append Experiment ID to @ExperimentIDList and @MaterialIDList
		---------------------------------------------------
		--
		If Len(@ExperimentIDList) > 0
			set @ExperimentIDList = @ExperimentIDList + ','

		Set @ExperimentIDList = @ExperimentIDList + Convert(varchar(12), @newExpID)

		If Len(@MaterialIDList) > 0
			set @MaterialIDList = @MaterialIDList + ','
			
		set @MaterialIDList = @MaterialIDList + 'E:' + Convert(varchar(12), @newExpID) 
		
	END -- </a>

	---------------------------------------------------
	-- resolve parent container name
	---------------------------------------------------
	--
	if @container = 'parent'
	begin
		SELECT @container = Tag
		FROM T_Material_Containers
		WHERE ID = @parentContainerID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Failed to find parent container'
			RAISERROR (@message, 10, 1)
			set @myError = 51019
			goto Done
		end
	end

	---------------------------------------------------
	-- move new fraction experiments to container
	---------------------------------------------------
	--
	exec @result = UpdateMaterialItems
					'move_material',
					@MaterialIDList,
					'mixed_material',
					@container,
					'',
					@message output,
   					@callingUser
	If @result <> 0
	Begin
		if @@TRANCOUNT > 0
			rollback transaction @transName
		RAISERROR (@message, 10, 1)
		set @myError = @result
		goto Done
	End
	
	---------------------------------------------------
	-- Now copy the aux info from the parent experiment 
	-- into the fractionated experiments
	---------------------------------------------------
	
	exec @result = CopyAuxInfoMultiID 
					@targetName = 'Experiment',
					@targetEntityIDList = @ExperimentIDList,
					@categoryName = '', 
					@subCategoryName = '', 
					@sourceEntityID = @ParentExperimentID,
					@mode = 'copyAll',
					@message = @message output

	If @result <> 0
	Begin
		if @@TRANCOUNT > 0
			rollback transaction @transName
		set @message = 'Error copying Aux Info from parent Experiment to fractionated experiments'
		RAISERROR (@message, 10, 1)
		set @myError = 51009
		goto Done
	End

	---------------------------------------------------
	-- Commit transaction if there were no errors
	---------------------------------------------------
		
	commit transaction @transName

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[AddExperimentFractions] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[AddExperimentFractions] TO [DMS2_SP_User]
GO

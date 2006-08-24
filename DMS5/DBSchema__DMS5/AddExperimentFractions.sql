/****** Object:  StoredProcedure [dbo].[AddExperimentFractions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddExperimentFractions
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
**		Auth: kja
**		Date: 5/28/2005
**            5/29/2005 grk - added mods to better work with entry page
**            5/31/2005 grk - added mods for separate group members table
**            6/10/2005 grk - added handling for sample prep request
**            10/4/2005 grk - added call to AddExperimentCellCulture
**            10/4/2005 grk - added override for request ID
**            10/28/2005  grk - added handling for internal standard
**            11/11/2005  grk - added handling for postdigest internal standard
**            12/20/2005  grk - added handling for separate user
**             2/06/2006  grk - increased maximum count
**    
*****************************************************/
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
	@message varchar(512) output
AS
	SET NOCOUNT ON
	declare @myError int
	set @myError = 0
	declare @myRowCount int
	
	declare @fractionCount int
	set @fractionCount = 0
	declare @maxCount smallint
	set @maxCount = 100
	
	Declare @fractionNumberText varchar(2)
	
	declare @fullFractionCount int
	declare @newExpID int
		
	-- T_Experiments column variables
	--
	declare @researcherPRN varchar(50)
	declare @organismName varchar(50)
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
	
	declare @expID int
	set @expID = 0
	SELECT
		@expID = Exp_ID,
		@researcherPRN = EX_researcher_PRN,
		@organismName = EX_organism_name,
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
		@postdigestIntStdID = EX_postdigest_internal_std_ID
	FROM	T_Experiments
	WHERE (Experiment_Num = @parentExperiment)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 OR @expID = 0
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
		SET @samplePrepRequest = CONVERT(int, @requestOverride)
		
		SELECT *
		FROM T_Sample_Prep_Request
		WHERE ID = @samplePrepRequest
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @myRowCount <> 1
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
		set @tmpID = 0
		--
		SELECT @tmpID = Internal_Std_Mix_ID
		FROM T_Internal_Standards
		WHERE (Name = @internalStandard)
		--
		if @tmpID = 0
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
		set @tmpID = 0
		--
		SELECT @tmpID = Internal_Std_Mix_ID
		FROM T_Internal_Standards
		WHERE (Name = @postdigestIntStd)
		--
		if @tmpID = 0
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
		@expID,
		@description,
		getdate()
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 OR @expID = 0
	begin
		set @message = 'Failed to insert of new group entry into database'
		RAISERROR (@message, 10, 1)
		set @myError = 51007
		goto Done
	end
	
	set @groupID = IDENT_CURRENT('T_Experiment_Groups')

	---------------------------------------------------
	-- Add parent experiment to reference group
	---------------------------------------------------
	
	INSERT INTO T_Experiment_Group_Members
		(Group_ID, Exp_ID)
	VALUES (@groupID, @expID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failied to update group reference for experiment'
		RAISERROR (@message, 10, 1)
		set @myError = 51008
		goto Done
	end

	---------------------------------------------------
	-- Insert Fractionated experiment entries
	---------------------------------------------------
	declare @newComment varchar(500)
	declare @newExpName varchar(129)
	
	WHILE @fractionCount < @totalCount and @myError = 0
	BEGIN
		-- build name for new experiment fraction
		--
		set @fullFractionCount = @startingIndex + @fractionCount
		set @fractionNumberText = CAST(@fullFractionCount as varchar(3))
		if  @fullFractionCount < 10
		begin
			set @fractionNumberText = '0' + @fractionNumberText
		end

		set @fractionCount = @fractionCount + @step
		set @newComment = N''
		set @newComment = @newComment + '(Fraction ' + CAST(@fullfractioncount as varchar(3)) + ' of ' + CAST(@totalcount as varchar(3)) + ')'
		set @newExpName = @parentExperiment + '_' + @fractionNumberText

		-- verify that experiment name is not duplicated in table
		--
		declare @xID int
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
			EX_organism_name, 
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
			@organismName, 
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
		
		set @newExpID = IDENT_CURRENT('T_Experiments')

		-- Add the cell cultures
		--
		declare @result int
		execute @result = AddExperimentCellCulture
								@newExpID,
								@cellCultureList,
								@message output
		--
		if @result <> 0
		begin
			declare @msg varchar(256)
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
			set @message = 'Failied to update group reference for new experiment'
			RAISERROR (@message, 10, 1)
			set @myError = 51008
			goto Done
		end
		
		---------------------------------------------------
		-- copy aux info from parent into fractionated experiment
		---------------------------------------------------
		exec @result = CopyAuxInfo
							@targetName = 'Experiment',
							@targetEntityName = @newExpName,
							@categoryName = '', 
							@subCategoryName = '', 
							@sourceEntityName = @parentExperiment,
							@mode = 'copyAll',
							@message = @message output
		--
		if @result <> 0
		begin
			rollback transaction @transName
			RAISERROR (@message, 10, 1)
			set @myError = @result
			goto Done
		end
	END

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

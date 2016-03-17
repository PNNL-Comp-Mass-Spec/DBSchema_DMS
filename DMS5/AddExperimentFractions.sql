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
**	Auth:	grk
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
**			07/16/2009 grk - added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**			07/31/2009 grk - added prep LC run field (http://prismtrac.pnl.gov/trac/ticket/743)
**			09/13/2011 grk - added researcher to experiment group
**			10/03/2011 grk - added try-catch error handling
**			11/10/2011 grk - Added Tab field
**			11/15/2011 grk - added handling for experiment alkylation field
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@parentExperiment varchar(128),       -- Parent experiment for group (must already exist)
	@groupType varchar(20) = 'Fraction',  -- 'None', 'Fraction'
	@tab VARCHAR(128),
	@description varchar(512),            -- Purpose of group
	@totalCount int,                      -- Number of new experiments to automatically create
	@groupID int,                         -- ID of newly created experiment group
	@requestOverride varchar(12) = 'parent',   -- ID of request for fractions (if different than parent)
	@internalStandard varchar(50) = 'parent',
	@postdigestIntStd varchar(50) = 'parent',
	@researcher varchar(50) = 'parent',
	@wellplateNum varchar(64) output,
	@wellNum varchar(8) output,
	@container varchar(128) = 'na',        -- na, "parent", "-20", or actual container ID
	@prepLCRunID int,
	@mode varchar(12),                    -- Not used at present - included for consistentcy
	@message varchar(512) output,
   	@callingUser varchar(128) = ''
)
AS
	Set XACT_ABORT, nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0
	
	declare @fractionCount int
	set @fractionCount = 0
	declare @maxCount smallint
	set @maxCount = 200
	
	Declare @fractionNumberText varchar(2)
	
	declare @fullFractionCount int
	declare @newExpID int
	declare @matchCount int
	
	declare @msg varchar(512)

	declare @startingIndex int
	declare @step int
	set @startingIndex = 1               -- Initial index for automatic naming of new experiments
	set @step = 1                        -- Step interval in index
	
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
	DECLARE @alkylation CHAR(1)

	declare @ExperimentIDList varchar(8000)
	Set @ExperimentIDList = ''

	declare @MaterialIDList varchar(8000)
	Set @MaterialIDList = ''


	BEGIN TRY
	
	---------------------------------------------------
	-- Validate arguments
	---------------------------------------------------
	
	-- don't allow too many child experiments to be created
	--
	if @totalCount > @maxCount
	begin
		set @message = 'Cannot create more than ' + convert(varchar(12), @maxCount) + ' child experments'
		RAISERROR (@message, 11, 4)
	end

	-- make sure that we don't overflow our alloted space for digits
	--
	if @startingIndex + (@totalCount * @step) > 999
	begin
		set @message = 'Automatic numbering parameters will require too many digits'
		RAISERROR (@message, 11, 5)
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
		@parentContainerID = EX_Container_ID,
		@alkylation = EX_Alkylation
	FROM	T_Experiments
	WHERE (Experiment_Num = @parentExperiment)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 OR @ParentExperimentID = 0
	begin
		set @message = 'Could not find parent experiment in database'
		RAISERROR (@message, 11, 6)
	end

	---------------------------------------------------
	-- set up and validate wellplate values
	---------------------------------------------------
	--
	declare @wellIndex int
	exec @myError = ValidateWellplateLoading
						@wellplateNum  output,
						@wellNum  output,
						@totalCount,
						@wellIndex output,
						@message output
	if @myError <> 0
	begin
		RAISERROR (@message, 11, 7)
	end

	---------------------------------------------------
	-- assure that wellplate is in wellplate table (if set)
	---------------------------------------------------
	--
	if not @wellplateNum is null
	begin
		if @wellplateNum = 'new'
		begin
			set @wellplateNum = '(generate name)'
			set @mode = 'add'
		end
		else
		begin
			set @mode = 'assure'
		end
		--
		declare @note varchar(128)
		set @note = 'Created by experiment fraction entry (' + @parentExperiment + ')'
		exec @myError = AddUpdateWellplate
							@wellplateNum output,
							@note,
							@mode,
							@message output,
							@callingUser
		if @myError <> 0
		begin
			return @myError
		end
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
			RAISERROR (@message, 11, 8)
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
			RAISERROR (@message, 11, 9)
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
			RAISERROR (@message, 11, 10)
		end
		Set @postdigestIntStdID = @tmpID
	end

	---------------------------------------------------
	-- Resolve researcher
	---------------------------------------------------
	-- 
	if @researcher <> 'parent'
	begin
		declare @userID int
		execute @userID = GetUserID @researcher
		if @userID = 0
		begin
			-- Could not find entry in database for PRN @researcher
			-- Try to auto-resolve the name

			Declare @NewPRN varchar(64)

			exec AutoResolveNameToPRN @researcher, @matchCount output, @NewPRN output, @userID output

			If @matchCount = 1
			Begin
			  -- Single match found; update @researcher
			  Set @researcher = @NewPRN
			End
			Else
			Begin
			 set @message = 'Could not find entry in database for researcher PRN "' + @researcher + '"'
			 RAISERROR (@message, 11, 11)
			End
		end
		SET @researcherPRN = @researcher
	end

	---------------------------------------------------
	-- Set up transaction around multiple table modifications
	---------------------------------------------------
	
--RAISERROR ('Researcher:%s', 11, 40, @researcherPRN)


	declare @transName varchar(32)
	set @transName = 'AddBatchExperimentEntry'
	begin transaction @transName
	
	---------------------------------------------------
	-- Make Experiment group entry
	---------------------------------------------------
	INSERT  INTO T_Experiment_Groups ( 
		EG_Group_Type ,
		Parent_Exp_ID ,
		EG_Description ,
		Prep_LC_Run_ID ,
		EG_Created ,
		Researcher,
		Tab
	)
	VALUES  ( 
		@groupType ,
		@ParentExperimentID ,
		@description ,
		@prepLCRunID ,
		GETDATE() ,
		@researcherPRN,
		@tab
	)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to insert new group entry into database'
		RAISERROR (@message, 11, 12)
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
		RAISERROR (@message, 11, 14)
	end

	---------------------------------------------------
	-- Insert Fractionated experiment entries
	---------------------------------------------------
	declare @newComment varchar(500)
	declare @newExpName varchar(129)
	declare @xID int
	declare @result int
	declare @wn varchar(8)
	set @wn = @wellNum
	
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
			RAISERROR (@message, 11, 16)
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
			EX_postdigest_internal_std_ID,
			EX_wellplate_num, 
			EX_well_num,
			EX_Alkylation
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
			@postdigestIntStdID,
			@wellplateNum,
			@wn,
			@alkylation
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Insert operation failed!'
			RAISERROR (@message, 11, 17)
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
			rollback transaction @transName
			set @msg = 'Could not add experiment cell cultures to database for experiment: "' + @newExpName + '" ' + @message
			RAISERROR (@msg, 11, 18)
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
			RAISERROR (@message, 11, 19)
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

		---------------------------------------------------
		-- increment well number
		---------------------------------------------------
		--
		if not @wn is null
		begin
			set @wellIndex = @wellIndex + 1
			set @wn = dbo.GetWellNum(@wellIndex)
		end

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
			RAISERROR (@message, 11, 20)
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
		RAISERROR (@message, 11, 22)
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
		RAISERROR (@message, 11, 23)
	End

	---------------------------------------------------
	-- Commit transaction if there were no errors
	---------------------------------------------------
		
	commit transaction @transName

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError


GO
GRANT EXECUTE ON [dbo].[AddExperimentFractions] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddExperimentFractions] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentFractions] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentFractions] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentFractions] TO [PNL\D3M580] AS [dbo]
GO

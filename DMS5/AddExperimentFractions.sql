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
**          05/29/2005 grk - Added mods to better work with entry page
**          05/31/2005 grk - Added mods for separate group members table
**          06/10/2005 grk - Added handling for sample prep request
**          10/04/2005 grk - Added call to AddExperimentCellCulture
**          10/04/2005 grk - Added override for request ID
**          10/28/2005 grk - Added handling for internal standard
**          11/11/2005 grk - Added handling for postdigest internal standard
**          12/20/2005 grk - Added handling for separate user
**          02/06/2006 grk - Increased maximum count
**          01/13/2007 grk - Switched to organism ID instead of organism name (Ticket #360)
**			09/27/2007 mem - Moved the copying of AuxInfo to occur after the new experiments have been created and to use CopyAuxInfoMultiID (Ticket #538)
**			10/22/2008 grk - Added container field (Ticket http://prismtrac.pnl.gov/trac/ticket/697)
**			07/16/2009 grk - Added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**			07/31/2009 grk - Added prep LC run field (http://prismtrac.pnl.gov/trac/ticket/743)
**			09/13/2011 grk - Added researcher to experiment group
**			10/03/2011 grk - Added try-catch error handling
**			11/10/2011 grk - Added Tab field
**			11/15/2011 grk - Added handling for experiment alkylation field
**			02/23/2016 mem - Add Set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			08/22/2017 mem - Copy TissueID
**			08/25/2017 mem - Use TissueID from the Sample Prep Request if @requestOverride is not "parent" and if the prep request has a tissue defined
**			09/06/2017 mem - Fix data type for @tissueID
**			11/29/2017 mem - No longer pass @cellCultureList to AddExperimentCellCulture since it now uses temp table #Tmp_ExpToCCMap
**			                 Remove references to the Cell_Culture_List field in T_Experiments (procedure AddExperimentCellCulture calls UpdateCachedExperimentInfo)
**			                 Call AddExperimentReferenceCompound
**			01/04/2018 mem - Update fields in #Tmp_ExpToRefCompoundMap, switching from Compound_Name to Compound_IDName
**    
*****************************************************/
(
	@parentExperiment varchar(128),			-- Parent experiment for group (must already exist)
	@groupType varchar(20) = 'Fraction',	-- 'None', 'Fraction'
	@tab VARCHAR(128),						-- User-defined name for this fraction group, aka tag
	@description varchar(512),				-- Purpose of group
	@totalCount int,						-- Number of new experiments to automatically create
	@groupID int,							-- ID of newly created experiment group
	@requestOverride varchar(12) = 'parent',   -- ID of sample prep request for fractions (if different than parent experiment)
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
	
	Declare @myError int = 0
	Declare @myRowCount int = 0
	
	Declare @fractionCount int = 0
	Declare @maxCount smallint = 200
	
	Declare @fractionNumberText varchar(2)
	
	Declare @fullFractionCount int
	Declare @newExpID int
	
	Declare @msg varchar(512)

	Declare @startingIndex int = 1               -- Initial index for automatic naming of new experiments
	Declare @step int = 1                 -- Step interval in index
	
	-- T_Experiments column variables
	--
	Declare @researcherPRN varchar(50)
	Declare @organismID int
	Declare @reason varchar(500)
	Declare @comment varchar(500)
	Declare @created datetime
	Declare @sampleConc varchar(50)
	Declare @labNotebook varchar(50)
	Declare @campaignID int
	Declare @labelling varchar(64)
	Declare @enzymeID int
	Declare @samplePrepRequest int
	Declare @internalStandardID int
	Declare @postdigestIntStdID int
	Declare @alkylation CHAR(1)
	Declare @tissueID varchar(24)
	
	Declare @ExperimentIDList varchar(8000) = ''

	Declare @MaterialIDList varchar(8000) = ''


	Begin TRY
	
	---------------------------------------------------
	-- Validate arguments
	---------------------------------------------------
	
	-- don't allow too many child experiments to be created
	--
	If @totalCount > @maxCount
	Begin
		Set @message = 'Cannot create more than ' + convert(varchar(12), @maxCount) + ' child experments'
		RAISERROR (@message, 11, 4)
	End

	-- make sure that we don't overflow our alloted space for digits
	--
	If @startingIndex + (@totalCount * @step) > 999
	Begin
		Set @message = 'Automatic numbering parameters will require too many digits'
		RAISERROR (@message, 11, 5)
	End

	-- Create temporary tables to hold cell cultures and reference compounds associated with the parent experiment
	--
	CREATE TABLE #Tmp_ExpToCCMap (
		CC_Name varchar(128) not null,
		CC_ID int null
	)

	CREATE TABLE #Tmp_ExpToRefCompoundMap (
		Compound_IDName varchar(128) not null,
		Colon_Pos int null,
		Compound_ID int null
	)
	
	---------------------------------------------------
	-- Get information for parent experiment
	---------------------------------------------------
	
	Declare @ParentExperimentID int = 0
	Declare @parentContainerID int = 0
	--
	SELECT @ParentExperimentID = Exp_ID,
	       @researcherPRN = EX_researcher_PRN,
	       @organismID = EX_organism_ID,
	       @reason = EX_reason,
	       @comment = EX_comment,
	       @created = EX_created,
	       @sampleConc = EX_sample_concentration,
	       @labNotebook = EX_lab_notebook_ref,
	       @campaignID = EX_campaign_ID,
	       @labelling = EX_Labelling,
	       @enzymeID = EX_enzyme_ID,
	       @samplePrepRequest = EX_sample_prep_request_ID,
	       @internalStandardID = EX_internal_standard_ID,
	       @postdigestIntStdID = EX_postdigest_internal_std_ID,
	       @parentContainerID = EX_Container_ID,
	       @alkylation = EX_Alkylation,
	       @tissueID = EX_Tissue_ID
	FROM T_Experiments
	WHERE Experiment_Num = @parentExperiment
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0 OR @ParentExperimentID = 0
	Begin
		Set @message = 'Could not find parent experiment in database'
		RAISERROR (@message, 11, 6)
	End

	---------------------------------------------------
	-- Cache the cell culture mapping
	---------------------------------------------------
	--
	INSERT INTO #Tmp_ExpToCCMap( CC_Name,
	                             CC_ID )
	SELECT CC.CC_Name,
	       CC.CC_ID
	FROM T_Experiment_Cell_Cultures ECC
	     INNER JOIN T_Cell_Culture CC
	       ON ECC.CC_ID = CC.CC_ID
	WHERE ECC.Exp_ID = @ParentExperimentID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	---------------------------------------------------
	-- Cache the reference compound mapping
	---------------------------------------------------
	--
	INSERT INTO #Tmp_ExpToRefCompoundMap( Compound_IDName,
	                                      Compound_ID )
	SELECT Cast(RC.Compound_ID As varchar(12)),
	       RC.Compound_ID
	FROM T_Experiment_Reference_Compounds ERC
	     INNER JOIN T_Reference_Compound RC
	       ON ERC.Compound_ID = RC.Compound_ID
	WHERE ERC.Exp_ID = @ParentExperimentID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	---------------------------------------------------
	-- Set up and validate wellplate values
	---------------------------------------------------
	--
	Declare @wellIndex int
	exec @myError = ValidateWellplateLoading
						@wellplateNum output,
						@wellNum output,
						@totalCount,
						@wellIndex output,
						@message output
	If @myError <> 0
	Begin
		RAISERROR (@message, 11, 7)
	End

	---------------------------------------------------
	-- assure that wellplate is in wellplate table (if set)
	---------------------------------------------------
	--
	If Not @wellplateNum Is Null
	Begin
		If @wellplateNum = 'new'
		Begin
			Set @wellplateNum = '(generate name)'
			Set @mode = 'add'
		End
		Else
		Begin
			Set @mode = 'assure'
		End
		--
		Declare @note varchar(128)
		Set @note = 'Created by experiment fraction entry (' + @parentExperiment + ')'
		exec @myError = AddUpdateWellplate
							@wellplateNum output,
							@note,
							@mode,
							@message output,
							@callingUser
		If @myError <> 0
		Begin
			return @myError
		End
	End

	---------------------------------------------------
	-- override request ID
	---------------------------------------------------

	Declare @prepRequestTissueID varchar(24) = Null
	
	If @requestOverride <> 'parent'
	Begin
		Set @samplePrepRequest = Try_Cast(@requestOverride as int)
		
		If @samplePrepRequest Is Null
		Begin
			Set @message = 'Prep request ID is not an integer: ' + @requestOverride
			RAISERROR (@message, 11, 8)
		End
		
		SELECT @prepRequestTissueID = Tissue_ID
		FROM T_Sample_Prep_Request
		WHERE ID = @samplePrepRequest
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0 OR @myRowCount <> 1
		Begin
			Set @message = 'Could not find sample prep request: ' + @requestOverride
			RAISERROR (@message, 11, 8)
		End
	End

	---------------------------------------------------
	-- Resolve predigest internal standard ID
	---------------------------------------------------
	If @internalStandard <> 'parent'
	Begin
		Declare @tmpID int = Null
		--
		SELECT @tmpID = Internal_Std_Mix_ID
		FROM T_Internal_Standards
		WHERE (Name = @internalStandard)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myRowCount = 0
		Begin
			Set @message = 'Could not find entry in database for internal standard "' + @internalStandard + '"'
			RAISERROR (@message, 11, 9)
		End
		Set @internalStandardID = @tmpID
	End

	---------------------------------------------------
	-- Resolve postdigestion internal standard ID
	---------------------------------------------------
	-- 
	If @postdigestIntStd <> 'parent'
	Begin
		Set @tmpID = Null
		--
		SELECT @tmpID = Internal_Std_Mix_ID
		FROM T_Internal_Standards
		WHERE (Name = @postdigestIntStd)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myRowCount = 0
		Begin
			Set @message = 'Could not find entry in database for postdigestion internal standard "' + @tmpID + '"'
			RAISERROR (@message, 11, 10)
		End
		Set @postdigestIntStdID = @tmpID
	End

	---------------------------------------------------
	-- Resolve researcher
	---------------------------------------------------
	-- 
	If @researcher <> 'parent'
	Begin
		Declare @userID int
		execute @userID = GetUserID @researcher
		If @userID = 0
		Begin
			-- Could not find entry in database for PRN @researcher
			-- Try to auto-resolve the name

			Declare @NewPRN varchar(64)
			Declare @matchCount int

			exec AutoResolveNameToPRN @researcher, @matchCount output, @NewPRN output, @userID output

			If @matchCount = 1
			Begin
				-- Single match found; update @researcher
				Set @researcher = @NewPRN
			End
			Else
			Begin
				Set @message = 'Could not find entry in database for researcher PRN "' + @researcher + '"'
				RAISERROR (@message, 11, 11)
			End
		End
		Set @researcherPRN = @researcher
	End

	---------------------------------------------------
	-- Set up transaction around multiple table modifications
	---------------------------------------------------
	
--RAISERROR ('Researcher:%s', 11, 40, @researcherPRN)


	Declare @transName varchar(32) = 'AddBatchExperimentEntry'
	
	Begin transaction @transName
	
	---------------------------------------------------
	-- Make Experiment group entry
	---------------------------------------------------
	INSERT INTO T_Experiment_Groups ( 
		EG_Group_Type ,
		Parent_Exp_ID ,
		EG_Description ,
		Prep_LC_Run_ID ,
		EG_Created ,
		Researcher,
		Tab
	) VALUES ( 
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
	If @myError <> 0
	Begin
		Set @message = 'Failed to insert new group entry into database'
		RAISERROR (@message, 11, 12)
	End
	
	Set @groupID = SCOPE_IDENTITY()

	---------------------------------------------------
	-- Add parent experiment to reference group
	---------------------------------------------------
	
	INSERT INTO T_Experiment_Group_Members (
		Group_ID, 
		Exp_ID
	) VALUES (
		@groupID, 
		@ParentExperimentID
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Failed to update group reference for experiment'
		RAISERROR (@message, 11, 14)
	End

	---------------------------------------------------
	-- Insert Fractionated experiment entries
	---------------------------------------------------
	Declare @newComment varchar(500)
	Declare @newExpName varchar(129)
	Declare @xID int
	Declare @result int
	Declare @wn varchar(8) = @wellNum
	
	WHILE @fractionCount < @totalCount and @myError = 0
	Begin -- <a>
		-- build name for new experiment fraction
		--
		Set @fullFractionCount = @startingIndex + @fractionCount
		Set @fractionNumberText = CAST(@fullFractionCount as varchar(3))
		If  @fullFractionCount < 10
		Begin
			Set @fractionNumberText = '0' + @fractionNumberText
		End

		Set @fractionCount = @fractionCount + @step
		Set @newComment = '(Fraction ' + CAST(@fullfractioncount as varchar(3)) + ' of ' + CAST(@totalcount as varchar(3)) + ')'
		Set @newExpName = @parentExperiment + '_' + @fractionNumberText

		-- verify that experiment name is not duplicated in table
		--
		Set @xID = 0
		execute @xID = GetexperimentID @newExpName
		--
		If @xID <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Failed to add new fraction experiment because name already in database'
			Set @myError = 51002
			RAISERROR (@message, 11, 16)
		End

		-- Insert new experiment into database
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
			EX_Labelling,
			EX_enzyme_ID,
			EX_sample_prep_request_ID,
			EX_internal_standard_ID,
			EX_postdigest_internal_std_ID,
			EX_wellplate_num, 
			EX_well_num,
			EX_Alkylation,
			EX_Tissue_ID
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
			@labelling,
			@enzymeID,
			@samplePrepRequest,
			@internalStandardID,
			@postdigestIntStdID,
			@wellplateNum,
			@wn,
			@alkylation,
			Case When IsNull(@prepRequestTissueID, '') <> '' Then @prepRequestTissueID Else @tissueID End
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Insert operation failed!'
			RAISERROR (@message, 11, 17)
		End
		
		Set @newExpID = SCOPE_IDENTITY()

		-- Add the experiment to cell culture mapping
		-- The stored procedure uses table #Tmp_ExpToCCMap
		--
		execute @result = AddExperimentCellCulture
								@newExpID,
								@updateCachedInfo=0,
								@message=@message output
		--
		If @result <> 0
		Begin
			rollback transaction @transName
			Set @msg = 'Could not add experiment cell cultures to database for experiment: "' + @newExpName + '" ' + @message
			RAISERROR (@msg, 11, 18)
		End

		-- Add the experiment to reference compound mapping
		-- The stored procedure uses table #Tmp_ExpToRefCompoundMap
		--
		execute @result = AddExperimentReferenceCompound
								@newExpID,
								@updateCachedInfo=1,
								@message=@message output
		--
		If @result <> 0
		Begin
			rollback transaction @transName
			Set @msg = 'Could not add experiment reference compounds to database for experiment: "' + @newExpName + '" ' + @message
			RAISERROR (@msg, 11, 18)
		End

		---------------------------------------------------
		-- Add fractionated experiment reference to experiment group
		---------------------------------------------------
		
		INSERT INTO T_Experiment_Group_Members (
			Group_ID, 
			Exp_ID
		) VALUES (
			@groupID, 
			@newExpID
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Failed to update group reference for new experiment'
			RAISERROR (@message, 11, 19)
		End
	
		---------------------------------------------------
		-- Append Experiment ID to @ExperimentIDList and @MaterialIDList
		---------------------------------------------------
		--
		If Len(@ExperimentIDList) > 0
			Set @ExperimentIDList = @ExperimentIDList + ','

		Set @ExperimentIDList = @ExperimentIDList + Convert(varchar(12), @newExpID)

		If Len(@MaterialIDList) > 0
			Set @MaterialIDList = @MaterialIDList + ','
			
		Set @MaterialIDList = @MaterialIDList + 'E:' + Convert(varchar(12), @newExpID) 

		---------------------------------------------------
		-- increment well number
		---------------------------------------------------
		--
		If Not @wn Is Null
		Begin
			Set @wellIndex = @wellIndex + 1
			Set @wn = dbo.GetWellNum(@wellIndex)
		End

	End -- </a>

	---------------------------------------------------
	-- resolve parent container name
	---------------------------------------------------
	--
	If @container = 'parent'
	Begin
		SELECT @container = Tag
		FROM T_Material_Containers
		WHERE ID = @parentContainerID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Failed to find parent container'
			RAISERROR (@message, 11, 20)
		End
	End

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
		If @@TRANCOUNT > 0
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
		If @@TRANCOUNT > 0
			rollback transaction @transName
		Set @message = 'Error copying Aux Info from parent Experiment to fractionated experiments'
		RAISERROR (@message, 11, 23)
	End

	---------------------------------------------------
	-- Commit transaction if there were no errors
	---------------------------------------------------
		
	commit transaction @transName

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	End TRY
	Begin CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'AddExperimentFractions'
	End CATCH
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentFractions] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddExperimentFractions] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddExperimentFractions] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentFractions] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[AddUpdateExperiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateExperiment
/****************************************************
**
**	Desc:	Adds a new experiment to DB
**
**			Note that the Experiment Detail Report web page 
**			uses DoMaterialItemOperation to retire an experiment
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	01/8/2002 - initial release
**			08/25/2004 jds - updated proc to add T_Enzyme table value
**			06/10/2005 grk - added handling for sample prep request
**			10/28/2005 grk - added handling for internal standard
**			11/11/2005 grk - added handling for postdigest internal standard
**			11/21/2005 grk - fixed update error for postdigest internal standard
**			01/12/2007 grk - added verification mode
**			01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**			04/30/2007 grk - added better name validation (Ticket #450)
**			02/13/2008 mem - Now checking for @badCh = '[space]' (Ticket #602)
**			03/13/2008 grk - added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter @callingUser
**			03/25/2008 mem - Now calling AlterEventLogEntryUser if @callingUser is not blank (Ticket #644)
**			07/16/2009 grk - added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**			12/01/2009 grk - modified to skip checking of existing well occupancy if updating existing experiment
**			04/22/2010 grk - try-catch for error handling
**			05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @researcherPRN contains a person's real name rather than their username
**			05/18/2010 mem - Now validating that @internalStandard and @postdigestIntStd are active internal standards when creating a new experiment (@mode is 'add' or 'check_add')
**			11/15/2011 grk - added alkylation field
**			12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**			03/26/2012 mem - Now validating @container
**			               - Updated to validate additional terms when @mode = 'check_add'
**			11/15/2012 mem - Now updating @cellCultureList to replace commas with semicolons
**			04/03/2013 mem - Now requiring that the experiment name be at least 6 characters in length
**			05/09/2014 mem - Expanded @campaignNum from varchar(50) to varchar(64)
**			09/09/2014 mem - Added @barcode
**			06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**			07/31/2015 mem - Now updating Last_Used when key fields are updated
**			02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Update error messages to use user-friendly entity names (e.g. campaign name instead of campaignNum)
**			09/14/2016 mem - Validate inputs
**			11/18/2016 mem - Log try/catch errors using PostLogEntry
**			11/23/2016 mem - Include the experiment name when calling PostLogEntry from within the catch block
**						   - Trim trailing and leading spaces from input parameters
**			12/05/2016 mem - Exclude logging some try/catch errors
**			12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**			01/24/2017 mem - Fix validation of @labelling to raise an error when the label name is unknown
**			01/27/2017 mem - Change @internalStandard and @postdigestIntStd to 'none' if empty
**			03/17/2017 mem - Only call MakeTableFromListDelim if @cellCultureList contains a semicolon
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/18/2017 mem - Add parameter @tissue (tissue name, e.g. hypodermis)
**			09/01/2017 mem - Allow @tissue to be a BTO ID (e.g. BTO:0000131)
**
*****************************************************/
(
	@experimentNum varchar(50),
	@campaignNum varchar(64),
	@researcherPRN varchar(50),
	@organismName varchar(50),
	@reason varchar(250) = 'na',
	@comment varchar(250) = Null,
	@sampleConcentration varchar(32) = 'na',
	@enzymeName varchar(50) = 'Trypsin',
	@labNotebookRef varchar(64) = 'na',
	@labelling varchar(64) = 'none',
	@cellCultureList varchar(200) = '',
	@samplePrepRequest int = 0,
	@internalStandard varchar(50),
	@postdigestIntStd varchar(50),
	@wellplateNum varchar(64),
	@wellNum varchar(8),
	@alkylation varchar(1),
	@mode varchar(12) = 'add', -- or 'update', 'check_add', 'check_update'
	@message varchar(512) output,
	@container varchar(128) = 'na', 
	@barcode varchar(64) = '',
	@tissue varchar(128) = '',
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0
	
	Set @message = ''

	Declare @result int
	
	Declare @msg varchar(256)
	Declare @logErrors tinyint = 0
	
	BEGIN TRY 

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateExperiment', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @experimentNum = LTrim(RTrim(IsNull(@experimentNum, '')))
	Set @campaignNum = LTrim(RTrim(IsNull(@campaignNum, '')))
	Set @researcherPRN = LTrim(RTrim(IsNull(@researcherPRN, '')))
	Set @organismName = LTrim(RTrim(IsNull(@organismName, '')))
	Set @reason = LTrim(RTrim(IsNull(@reason, '')))
	Set @comment = LTrim(RTrim(IsNull(@comment, '')))
	Set @enzymeName = LTrim(RTrim(IsNull(@enzymeName, '')))
	Set @labelling = LTrim(RTrim(IsNull(@labelling, '')))
	Set @cellCultureList = LTrim(RTrim(IsNull(@cellCultureList, '')))
	Set @internalStandard = LTrim(RTrim(IsNull(@internalStandard, '')))
	Set @postdigestIntStd = LTrim(RTrim(IsNull(@postdigestIntStd, '')))
	Set @alkylation = LTrim(RTrim(IsNull(@alkylation, '')))
	Set @mode = LTrim(RTrim(IsNull(@mode, '')))
	
	if LEN(@experimentNum) < 1
		RAISERROR ('experiment name must be defined', 11, 30)
	--
	if LEN(@campaignNum) < 1
		RAISERROR ('Campaign name must be defined', 11, 31)
	--
	if LEN(@researcherPRN) < 1
		RAISERROR ('Researcher PRN must be defined', 11, 32)
	--
	if LEN(@organismName) < 1
		RAISERROR ('Organism name must be defined', 11, 33)
	--
	if LEN(@reason) < 1
		RAISERROR ('Reason cannot be blank', 11, 34)
	--
	if LEN(@labelling) < 1
		RAISERROR ('Labelling cannot be blank', 11, 35)

	If Not @alkylation IN ('Y', 'N')
		RAISERROR ('Alkylation must be Y or N', 11, 35)
		
	-- Assure that @comment is not null and assure that it doesn't have &quot;
	If @comment LIKE '%&quot;%'
		Set @comment = Replace(@comment, '&quot;', '"')

	-- Auto change empty internal standards to "none" since now rarely used
	If @internalStandard = ''
		Set @internalStandard = 'none'

	If @postdigestIntStd= ''
		Set @postdigestIntStd = 'none'

	---------------------------------------------------
	-- Validate experiment name
	---------------------------------------------------

	Declare @badCh varchar(128) = dbo.ValidateChars(@experimentNum, '')
	if @badCh <> ''
	begin
		If @badCh = '[space]'
			RAISERROR ('Experiment name may not contain spaces', 11, 36)
		Else
			RAISERROR ('Experiment name may not contain the character(s) "%s"', 11, 37, @badCh)
	end

	If Len(@experimentNum) < 6
	begin
		Set @msg = 'Experiment name must be at least 6 characters in length; currently ' + Convert(varchar(12), Len(@experimentNum)) + ' characters'
		RAISERROR (@msg, 11, 37)
	end

	---------------------------------------------------
	-- Resolve @tissue to BTO identifier
	---------------------------------------------------
	
	Declare @tissueIdentifier varchar(24)
	Declare @tissueName varchar(128)
	Declare @errorCode int

	EXEC @errorCode = GetTissueID 
		@tissueNameOrID=@tissue,
		@tissueIdentifier=@tissueIdentifier output,
		@tissueName=@tissueName output
	
	If @errorCode = 100
		RAISERROR ('Could not find entry in database for tissue "%s"', 11, 41, @tissue)
	Else If @errorCode > 0
		RAISERROR ('Could not resolve tissue name or id: "%s"', 11, 41, @tissue)
	
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	Declare @experimentID int = 0
	Declare @curContainerID int = 0
	--
	SELECT 
		@experimentID = Exp_ID,
		@curContainerID = EX_Container_ID
	FROM T_Experiments 
	WHERE (Experiment_Num = @experimentNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Error trying to resolve experiment ID', 11, 38)

	-- cannot create an entry that already exists
	--
	if @experimentID <> 0 and (@mode In ('add', 'check_add'))
		RAISERROR ('Cannot add: Experiment "%s" already in database', 11, 39, @experimentNum)

	-- cannot update a non-existent entry
	--
	if @experimentID = 0 and (@mode In ('update', 'check_update'))
		RAISERROR ('Cannot update: Experiment "%s" is not in database', 11, 40, @experimentNum)

	---------------------------------------------------
	-- Resolve campaign ID
	---------------------------------------------------

	Declare @campaignID int
	execute @campaignID = GetCampaignID @campaignNum
	if @campaignID = 0
		RAISERROR ('Could not find entry in database for campaign "%s"', 11, 41, @campaignNum)

	---------------------------------------------------
	-- Resolve researcher PRN
	---------------------------------------------------

	Declare @userID int
	execute @userID = GetUserID @researcherPRN
	if @userID = 0
	begin
		-- Could not find entry in database for PRN @researcherPRN
		-- Try to auto-resolve the name

		Declare @MatchCount int
		Declare @NewPRN varchar(64)

		exec AutoResolveNameToPRN @researcherPRN, @MatchCount output, @NewPRN output, @userID output

		If @MatchCount = 1
		Begin
			-- Single match found; update @researcherPRN
			Set @researcherPRN = @NewPRN
		End
		Else
		Begin
			RAISERROR ('Could not find entry in database for researcher PRN "%s"', 11, 42, @researcherPRN)
			return 51037
		End

	end

	---------------------------------------------------
	-- Resolve organism ID
	---------------------------------------------------

	Declare @organismID int = 0
	exec @organismID = GetOrganismID @organismName
	if @organismID = 0
		RAISERROR ('Could not find entry in database for organism name "%s"', 11, 43, @organismName)

	---------------------------------------------------
	-- Set up and validate wellplate values
	---------------------------------------------------
	Declare @totalCount INT
	Declare @wellIndex int
	--
	SELECT @totalCount = CASE WHEN @mode In ('add', 'check_add') THEN 1 ELSE 0 END
	--
	exec @myError = ValidateWellplateLoading
						@wellplateNum  output,
						@wellNum  output,
						@totalCount,
						@wellIndex output,
						@msg  output
	if @myError <> 0
		RAISERROR ('ValidateWellplateLoading: %s', 11, 44, @msg)

	-- make sure we do not put two experiments in the same place
	--
	if exists (SELECT * FROM T_Experiments WHERE EX_wellplate_num = @wellplateNum AND EX_well_num = @wellNum) AND @mode In ('add', 'check_add')
		RAISERROR ('There is another experiment assigned to the same wellplate and well', 11, 45)
	--
	if exists (SELECT * FROM T_Experiments WHERE EX_wellplate_num = @wellplateNum AND EX_well_num = @wellNum AND Experiment_Num <> @experimentNum) AND @mode In ('update', 'check_update')
		RAISERROR ('There is another experiment assigned to the same wellplate and well', 11, 46)

	---------------------------------------------------
	-- Resolve enzyme ID
	---------------------------------------------------

	Declare @enzymeID int = 0
	exec @enzymeID = GetEnzymeID @enzymeName
	If @enzymeID = 0
	Begin
		If @enzymeName = 'na'
			RAISERROR ('The enzyme cannot be "%s"; use No_Enzyme if enzymatic digestion was not used', 11, 47, @enzymeName)
		Else
			RAISERROR ('Could not find entry in database for enzyme "%s"', 11, 47, @enzymeName)
	End
	
	---------------------------------------------------
	-- Resolve labelling ID
	---------------------------------------------------

	Declare @labelID int = 0
	--
	SELECT @labelID = ID
	FROM T_Sample_Labelling
	WHERE (Label = @labelling)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myRowCount = 0
		RAISERROR ('Could not find entry in database for labelling "%s"; use "none" if unlabeled', 11, 48, @labelling)
	
	---------------------------------------------------
	-- Resolve predigestion internal standard ID
	-- If creating a new experiment, make sure the internal standard is active
	---------------------------------------------------

	Declare @internalStandardID int = 0
	Declare @internalStandardState char = 'I'
	--
	SELECT @internalStandardID = Internal_Std_Mix_ID,
	       @internalStandardState = Active
	FROM T_Internal_Standards
	WHERE (Name = @internalStandard)
	--
	if @internalStandardID = 0
		RAISERROR ('Could not find entry in database for predigestion internal standard "%s"', 11, 49, @internalStandard)

	if (@mode In ('add', 'check_add')) And @internalStandardState <> 'A'
		RAISERROR ('Predigestion internal standard "%s" is not active; this standard cannot be used when creating a new experiment', 11, 49, @internalStandard)

	---------------------------------------------------
	-- Resolve postdigestion internal standard ID
	---------------------------------------------------
	-- 
	Declare @postdigestIntStdID int = 0
	Set @internalStandardState = 'I'
	--
	SELECT @postdigestIntStdID = Internal_Std_Mix_ID,
	       @internalStandardState = Active
	FROM T_Internal_Standards
	WHERE (Name = @postdigestIntStd)
	--
	if @postdigestIntStdID = 0
		RAISERROR ('Could not find entry in database for postdigestion internal standard "%s"', 11, 50, @postdigestIntStd)

	if (@mode In ('add', 'check_add')) And @internalStandardState <> 'A'
		RAISERROR ('Postdigestion internal standard "%s" is not active; this standard cannot be used when creating a new experiment', 11, 49, @postdigestIntStd)

	---------------------------------------------------
	-- Resolve container name to ID
	-- Auto-switch name from 'none' to 'na'
	---------------------------------------------------

	If @container = 'none'
		Set @container = 'na'

	Declare @contID int = 0
	--
	SELECT @contID = ID
	FROM T_Material_Containers
	WHERE (Tag = @container)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @contID = 0 Or @myError <> 0
		RAISERROR ('Invalid container name "%s"', 11, 51, @container)

	---------------------------------------------------
	-- Resolve current container id to name 
	-- (skip if adding experiment)
	---------------------------------------------------
	Declare @curContainerName varchar(125) = ''
	--
	If Not @mode In ('add', 'check_add')
	Begin
		SELECT @curContainerName = Tag 
		FROM T_Material_Containers 
		WHERE ID = @curContainerID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Error resolving name of current container', 11, 53)
	End
	
	---------------------------------------------------
	-- Resolve cell cultures
	-- Auto-switch from 'none' or 'na' to '(none)'
	---------------------------------------------------
	
	If @cellCultureList IN ('none', 'na', '')
		Set @cellCultureList = '(none)'
	
	-- Replace commas with semicolons
	If @cellCultureList Like '%,%'
		Set @cellCultureList = Replace(@cellCultureList, ',', ';')
		
	-- create tempoary table to hold names of cell cultures as input
	--
	create table #CC (
		CC_Name varchar(128) not null
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not create temporary table for cell culture list', 11, 70)

	-- get names of cell cultures from list argument into table
	--
	If @cellCultureList Like '%;%'
	Begin
		INSERT INTO #CC (CC_Name) 
		SELECT item 
		FROM MakeTableFromListDelim(@cellCultureList, ';')
	End
	Else
	Begin
		INSERT INTO #CC (CC_Name) 
		VALUES (@cellCultureList)
	End
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not populate temporary table for cell culture list', 11, 79)
	
	-- verify that cell cultures exist
	--
	Declare @InvalidCCList varchar(255) = null
	
	SELECT @InvalidCCList = Coalesce(@InvalidCCList + ', ' + #CC.CC_Name, #CC.CC_Name)
	FROM #CC
	     LEFT OUTER JOIN T_Cell_Culture
	       ON #CC.CC_Name = T_Cell_Culture.CC_Name
	WHERE T_Cell_Culture.CC_Name IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Was not able to check for cell cultures in database', 11, 80)
	--
	if IsNull(@InvalidCCList, '') <> ''
		RAISERROR ('Invalid cell culture name(s): %s', 11, 81, @InvalidCCList)


	Declare @transName varchar(32)
	Set @logErrors = 1
	
	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	
	if @Mode = 'add'
	begin

		-- Start transaction
		--
		Set @transName = 'AddNewExperiment'
		begin transaction @transName

		INSERT INTO T_Experiments (
				Experiment_Num, 
				EX_researcher_PRN, 
				EX_organism_ID, 
				EX_reason, 
				EX_comment, 
				EX_created, 
				EX_sample_concentration, 
				EX_enzyme_ID, 
				EX_Labelling, 
				EX_lab_notebook_ref, 
				EX_campaign_ID,
				EX_cell_culture_list,
				EX_sample_prep_request_ID,
				EX_internal_standard_ID,
				EX_postdigest_internal_std_ID,
				EX_Container_ID,
				EX_wellplate_num, 
				EX_well_num,
				EX_Alkylation,
				EX_Barcode,
				EX_Tissue_ID,
				Last_Used
			) VALUES (
				@experimentNum, 
				@researcherPRN, 
				@organismID, 
				@reason, 
				@comment, 
				GETDATE(), 
				@sampleConcentration, 
				@enzymeID,
				@labelling, 
				@labNotebookRef,
				@campaignID,
				@cellCultureList,
				@samplePrepRequest,
				@internalStandardID,
				@postdigestIntStdID,
				@contID,
				@wellplateNum,
				@wellNum,
				@alkylation,
				@barcode,
				@tissueIdentifier,
				Cast(GETDATE() as Date)
			)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed: "%s"', 11, 7, @experimentNum)

		-- Get the ID of newly created experiment
		Set @experimentID = SCOPE_IDENTITY()		

		-- As a precaution, query T_Experiments using Experiment name to make sure we have the correct Exp_ID
		Declare @ExpIDConfirm int = 0
		
		SELECT @ExpIDConfirm = Exp_ID
		FROM T_Experiments
		WHERE Experiment_Num = @experimentNum
		
		If @experimentID <> IsNull(@ExpIDConfirm, @experimentID)
		Begin
			Declare @DebugMsg varchar(512)
			Set @DebugMsg = 'Warning: Inconsistent identity values when adding experiment ' + @experimentNum + ': Found ID ' +
			                Cast(@ExpIDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' + 
			                Cast(@experimentID as varchar(12))
			                
			exec postlogentry 'Error', @DebugMsg, 'AddUpdateExperiment'
			
			Set @experimentID = @ExpIDConfirm
		End


		Declare @StateID int = 1
		
		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 3, @experimentID, @StateID, @callingUser

		-- Add the cell cultures
		--
		execute @result = AddExperimentCellCulture
								@experimentID,
								@cellCultureList,
								@msg output
		--
		if @result <> 0
			RAISERROR ('Could not add experiment cell cultures to database for experiment "%s" :%s', 11, 1, @experimentNum, @msg)

		--  material movement logging
		--	
		if @curContainerID != @contID
		begin
			exec PostMaterialLogEntry
				'Experiment Move',
				@experimentNum,
				'na',
				@container,
				@callingUser,
				'Experiment added'
		end

		-- we made it this far, commit
		--
		commit transaction @transName

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------

	if @Mode = 'update' 
	begin
		Set @myError = 0

		-- Start transaction
		--
		Set @transName = 'UpdateExperiment'
		begin transaction @transName

		UPDATE T_Experiments Set 
			EX_researcher_PRN = @researcherPRN, 
			EX_organism_ID = @organismID, 
			EX_reason = @reason, 
			EX_comment = @comment, 
			EX_sample_concentration = @sampleConcentration, 
			EX_enzyme_ID = @enzymeID,
			EX_Labelling = @labelling, 
			EX_lab_notebook_ref = @labNotebookRef, 
			EX_campaign_ID = @campaignID,
			EX_cell_culture_list = @cellCultureList,
			EX_sample_prep_request_ID = @samplePrepRequest,
			EX_internal_standard_ID = @internalStandardID,
			EX_postdigest_internal_std_ID = @postdigestIntStdID,
			EX_Container_ID = @contID,
			EX_wellplate_num = @wellplateNum, 
			EX_well_num = @wellNum,
			EX_Alkylation = @alkylation,
			EX_Barcode = @barcode,
			EX_Tissue_ID = @tissueIdentifier,
			Last_Used = Case When EX_organism_ID <> @organismID OR
			                      EX_reason <> @reason OR
			                      EX_comment <> @comment OR
			                      EX_enzyme_ID <> @enzymeID OR
			                      EX_Labelling <> @labelling OR
			                      EX_campaign_ID <> @campaignID OR
			                      EX_cell_culture_list <> @cellCultureList OR
			                      EX_sample_prep_request_ID <> @samplePrepRequest OR
			                      EX_Alkylation <> @alkylation
			                 Then Cast(GetDate() as Date) 
			                 Else Last_Used 
			            End
		WHERE 
			(Experiment_Num = @experimentNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @experimentNum)

		-- Add the cell cultures
		--
		execute @result = AddExperimentCellCulture
								@experimentID,
								@cellCultureList,
								@msg output
		--
		if @result <> 0
			RAISERROR ('Could not update experiment cell cultures to database for experiment "%s" :%s', 11, 1, @experimentNum, @msg)

		--  material movement logging
		--	
		if @curContainerID != @contID
		begin
			exec PostMaterialLogEntry
				'Experiment Move',
				@experimentNum,
				@curContainerName,
				@container,
				@callingUser,
				'Experiment updated'
		end

		-- we made it this far, commit
		--
		commit transaction @transName

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		If @logErrors > 0
		Begin
			Declare @logMessage varchar(1024) = @message + '; Experiment ' + @experimentNum		
			exec PostLogEntry 'Error', @logMessage, 'AddUpdateExperiment'
		End
		
	END CATCH
	
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperiment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperiment] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperiment] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperiment] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[AddUpdateAnalysisJobRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateAnalysisJobRequest
/****************************************************
**
**	Desc: Adds new analysis job request to request queue
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	10/9/2003
**			02/11/2006 grk added validation for tool compatibility
**			03/28/2006 grk - added protein collection fields
**			04/04/2006 grk - increased sized of param file name
**			04/04/2006 grk - modified to use ValidateAnalysisJobParameters
**			04/10/2006 grk - widened size of list argument to 6000 characters
**			04/11/2006 grk - modified logic to allow changing name of exising request
**			08/31/2006 grk - restored apparently missing prior modification http://prismtrac.pnl.gov/trac/ticket/217
**			10/16/2006 jds - added support for work package number
**			10/16/2006 mem - updated to force @state to 'new' if @mode = 'add'
**			11/13/2006 mem - Now calling ValidateProteinCollectionListForDatasets to validate @protCollNameList
**			11/30/2006 mem - Added column Dataset_Type to #TD (Ticket:335)
**			12/20/2006 mem - Added column DS_rating to #TD (Ticket:339)
**			01/26/2007 mem - Switched to organism ID instead of organism name (Ticket:368)
**			05/22/2007 mem - Updated to prevent addition of duplicate datasets to  (Ticket:481)
**			10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**			01/17/2008 grk - Modified error codes to help debugging DMS2.  Also had to add explicit NULL column attribute to #TD
**			02/22/2008 mem - Updated to convert @comment to '' if null (Ticket:648, http://prismtrac.pnl.gov/trac/ticket/648)
**			09/12/2008 mem - Now passing @parmFileName and @settingsFileName ByRef to ValidateAnalysisJobParameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**			09/24/2008 grk - Increased size of comment argument (and column in database)(Ticket:692, http://prismtrac.pnl.gov/trac/ticket/692)
**			12/02/2008 grk - Disallow editing unless in "New" state
**			09/19/2009 grk - Added field to request admin review (Ticket #747, http://prismtrac.pnl.gov/trac/ticket/747)
**			09/19/2009 grk - Allowed updates from any state
**          09/22/2009 grk - changed state "review_required" to "New (Review Required)"
**			09/22/2009 mem - Now setting state to "New (Review Required)" if @State = 'new' and @adminReviewReqd='Yes'
**			10/02/2009 mem - Revert to only allowing updates if the state is "New" or "New (Review Required)"
**			02/12/2010 mem - Now assuring that rating is not -5 (note: when converting a job request to jobs, you can manually add datasets with a rating of -5; procedure AddAnalysisJobGroup will allow them to be included)
**			04/21/2010 grk - try-catch for error handling
**			05/05/2010 mem - Now passing @requestorPRN to ValidateAnalysisJobParameters as input/output
**			05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**    
*****************************************************/
(
    @datasets varchar(6000),
    @requestName varchar(64),
    @toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(255),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
    @organismName varchar(64),
    @requestorPRN varchar(32),
    @workPackage varchar(24),
    @comment varchar(512) = null,
    @adminReviewReqd VARCHAR(32),
    @state varchar(32),
    @requestID int output,
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	BEGIN TRY 

	---------------------------------------------------
	-- Assure that the comment variable is not null
	---------------------------------------------------
	
	set @comment = IsNull(@comment, '')
	
	set @message = ''

	declare @msg varchar(512)

	declare @organismDBName varchar(64)
	set @organismDBName = 'na'

	---------------------------------------------------
	-- Validate @adminReviewReqd
	---------------------------------------------------
	
	Set @adminReviewReqd = LTrim(RTrim(IsNull(@adminReviewReqd, 'No')))
	If @adminReviewReqd = 'Y' OR @adminReviewReqd = '1'
		Set @adminReviewReqd = 'Yes'
	
	---------------------------------------------------
	-- Resolve mode against presence or absence 
	-- of request in database, and its current state
	---------------------------------------------------

	declare @hit int
	declare @curState int

	-- cannot create an entry with a duplicate name
	--
	if @mode = 'add'
	begin
		set @hit = 0
		SELECT 
			@hit = AJR_requestID
		FROM         T_Analysis_Job_Request
		WHERE (AJR_requestName = @requestName)
		--
		if @hit <> 0
			RAISERROR ('Cannot add: request with same name already in database', 11, 4)
	end

	-- cannot update a non-existent entry
	--
	if @mode = 'update'
	begin
		set @hit = 0
		SELECT 
			@hit = AJR_requestID,
			@curState =  AJR_state
		FROM         T_Analysis_Job_Request
		WHERE (AJR_requestID = @requestID)
		--
		if @hit = 0
			RAISERROR ('Cannot update: entry is not in database', 11, 5)
		--
		if Not (@curState IN (1,5))
			RAISERROR ('Cannot update: entry is not in "New" or New (Review Required) state', 11, 24)
	end

	---------------------------------------------------
	-- dataset list shouldn't be empty
	---------------------------------------------------
	if @datasets = ''
		RAISERROR ('Dataset list is empty', 11, 1)

	---------------------------------------------------
	-- Create temporary table to hold list of datasets
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
		RAISERROR ('Failed to create temporary table', 11, 10)

	---------------------------------------------------
	-- Populate table from dataset list  
	---------------------------------------------------
	--
	INSERT INTO #TD
		(Dataset_Num)
	SELECT
		Item
	FROM
		MakeTableFromList(@datasets)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Error populating temporary table', 11, 8)

	---------------------------------------------------
	-- Validate @protColNameList
	-- Note that ValidateProteinCollectionListForDatasets
	--  will populate @message with an explanatory note
	--  if @protCollNameList is updated
	---------------------------------------------------
	--
	declare @CollectionCountAdded int
	declare @result int
	set @result = 0
	
	Set @protCollNameList = LTrim(RTrim(IsNull(@protCollNameList, '')))
	If Len(@protCollNameList) > 0 And dbo.ValidateNAParameter(@protCollNameList, 1) <> 'na'
	Begin
		exec @result = ValidateProteinCollectionListForDatasets 
							@datasets, 
							@protCollNameList=@protCollNameList output, 
							@CollectionCountAdded=@CollectionCountAdded output, 
							@ShowMessages=1, 
							@message=@message output

		if @result <> 0
			return @result
	End
	
	---------------------------------------------------
	-- Check for duplicate datasets in #TD
	---------------------------------------------------
	--
	declare @DuplicateDatasetList varchar(4000)
	declare @DuplicateDatasetCount int
	--
	Set @DuplicateDatasetCount = 0
	
	SELECT @DuplicateDatasetCount = COUNT(*)
	FROM (	SELECT Dataset_Num
			FROM #TD
			GROUP BY Dataset_Num
			HAVING Count(*) > 1
		 ) DuplicateQ
	
	If @DuplicateDatasetCount > 0
	Begin
		Set @DuplicateDatasetList = ''
		SELECT @DuplicateDatasetList = @DuplicateDatasetList + Dataset_Num + ', '
		FROM #TD
		GROUP BY Dataset_Num
		HAVING Count(*) > 1
		ORDER BY Dataset_Num
		
		-- Remove the trailing comma if the length is less than 400 characters, otherwise truncate
		If Len(@DuplicateDatasetList) < 400
			Set @DuplicateDatasetList = Left(@DuplicateDatasetList, Len(@DuplicateDatasetList)-1)
		Else
			Set @DuplicateDatasetList = Left(@DuplicateDatasetList, 397) + '...'
				
		RAISERROR ('Duplicate dataset(s) found: %s', 11, 9, @DuplicateDatasetList)
	End
	
	---------------------------------------------------
	-- validate job parameters
	---------------------------------------------------
	--
	declare @userID int
	declare @analysisToolID int
	declare @organismID int
	--
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
							@requestorPRN output,
							'', -- blank validation mode to suppress dataset state checking
							@userID output,
							@analysisToolID output, 
							@organismID output,
							@msg output
	--
	if @result <> 0
		RAISERROR (@msg, 11, 8)

	---------------------------------------------------
	-- Make sure none of the datasets has a rating of -5 (Not Released)
	---------------------------------------------------
	--
	declare @NotReleasedList varchar(4000)
	declare @NotReleasedCount int
	--
	Set @NotReleasedCount = 0
	
	SELECT @NotReleasedCount = COUNT(*)
	FROM #TD
	WHERE DS_Rating = -5
	
	If @NotReleasedCount > 0
	Begin
		Set @NotReleasedList = ''
		
		SELECT @NotReleasedList = @NotReleasedList + Dataset_Num + ', '
		FROM #TD
		WHERE DS_Rating = -5
		ORDER BY Dataset_Num
		
		-- Remove the trailing comma if the length is less than 400 characters, otherwise truncate
		If Len(@NotReleasedList) < 400
			Set @NotReleasedList = Left(@NotReleasedList, Len(@NotReleasedList)-1)
		Else
			Set @NotReleasedList = Left(@NotReleasedList, 397) + '...'
			
		RAISERROR ('Dataset(s) found with rating "Not Released": %s', 11, 110, @NotReleasedList)
	End

	---------------------------------------------------
	-- If mode is add, then force @state to 'new'
	---------------------------------------------------
	IF @mode = 'add' 
	BEGIN
		IF @adminReviewReqd = 'Yes' 
			-- Lookup the name for state "New (Review Required)"
			SELECT @state = StateName
			FROM T_Analysis_Job_Request_State
			WHERE (ID = 5)
		ELSE 
			-- Lookup the name for state "New"
			SELECT @state = StateName
			FROM T_Analysis_Job_Request_State
			WHERE (ID = 1)
	END

	IF @mode = 'Update' And @adminReviewReqd='Yes' AND @State = 'New'
	BEGIN
		-- Change the state to  "New (Review Required)"
		SELECT @state = StateName
		FROM T_Analysis_Job_Request_State
		WHERE (ID = 5)
	END

	---------------------------------------------------
	-- Resolve state name to ID
	---------------------------------------------------
	declare @stateID int
	set @stateID = -1
	SELECT @stateID = ID
	FROM         T_Analysis_Job_Request_State
	WHERE     (StateName = @state)
	
	if @stateID = -1
		RAISERROR ('Could not resolve state name to ID', 11, 221)

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		declare @newRequestNum int
		--
		INSERT INTO T_Analysis_Job_Request
		(
			AJR_requestName,
			AJR_created, 
			AJR_analysisToolName, 
			AJR_parmFileName, 
			AJR_settingsFileName, AJR_organismDBName, AJR_organism_ID, 
			AJR_proteinCollectionList, AJR_proteinOptionsList,
			AJR_datasets, AJR_comment, 
			AJR_state, AJR_requestor, AJR_workPackage
		)
		VALUES
		(
			@requestName, getdate(), @toolName, @parmFileName, 
			@settingsFileName, @organismDBName, @organismID, 
			@protCollNameList, @protCollOptionsList,
			@datasets, @comment, 
			@stateID, @userID, @workPackage
		)		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert new job operation failed', 11, 9)
		--
		set @newRequestNum = IDENT_CURRENT('T_Analysis_Job_Request')

		-- return job number of newly created job
		--
		set @requestID = cast(@newRequestNum as varchar(32))

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		-- Lookup the current state of the request
		set @myError = 0
		--
		UPDATE T_Analysis_Job_Request
		SET
		AJR_requestName = @requestName,
		AJR_analysisToolName = @toolName, 
		AJR_parmFileName = @parmFileName, 
		AJR_settingsFileName = @settingsFileName, 
		AJR_organismDBName = @organismDBName, 
		AJR_organism_ID = @organismID, 
		AJR_proteinCollectionList = @protCollNameList, 
		AJR_proteinOptionsList = @protCollOptionsList,
		AJR_datasets = @datasets, 
		AJR_comment = @comment, 
		AJR_state = @stateID,
		AJR_requestor = @userID,
		AJR_workPackage = @workPackage
		WHERE     (AJR_requestID = @requestID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%d"', 11, 4, @requestID)
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
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJobRequest] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJobRequest] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJobRequest] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJobRequest] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJobRequest] TO [PNL\D3M580] AS [dbo]
GO

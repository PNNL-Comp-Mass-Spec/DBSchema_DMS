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
**		Auth: grk
**		Date: 10/9/2003
**            2/11/2006 grk added validation for tool compatibility
**			  03/28/2006 grk - added protein collection fields
**			  04/04/2006 grk - increased sized of param file name
**			  04/04/2006 grk - modified to use ValidateAnalysisJobParameters
**			  04/10/2006 grk - widened size of list argument to 6000 characters
**			  04/11/2006 grk - modified logic to allow changing name of exising request
**			  08/31/2006 grk - restored apparently missing prior modification https://prismtrac.pnl.gov/trac/ticket/217
**    
*****************************************************/
    @datasets varchar(6000),
    @requestName varchar(64),
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(64),
    @protCollNameList varchar(512),
    @protCollOptionsList varchar(256),
    @organismName varchar(64),
    @requestorPRN varchar(32),
    @comment varchar(255) = null,
    @state varchar(32),
    @requestID int output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @msg varchar(512)

    declare @organismDBName varchar(64)
    set @organismDBName = 'na'

	---------------------------------------------------
	-- Resolve mode against presence or absence 
	-- of request in database
	---------------------------------------------------

	declare @hit int

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
		begin
			set @msg = 'Cannot add: request with same name already in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end

	-- cannot update a non-existent entry
	--
	if @mode = 'update'
	begin
		set @hit = 0
		SELECT 
			@hit = AJR_requestID
		FROM         T_Analysis_Job_Request
		WHERE (AJR_requestID = @requestID)
		--
		if @hit = 0
		begin
			set @msg = 'Cannot update: entry is not in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end

	---------------------------------------------------
	-- dataset list shouldn't be empty
	---------------------------------------------------
	if @datasets = ''
	begin
		set @msg = 'Dataset list is empty'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- Create temporary table to hold list of datasets
	---------------------------------------------------

	CREATE TABLE #TD (
		Dataset_Num varchar(128),
		Dataset_ID int,
		IN_class varchar(64), 
		DS_state_ID int, 
		AS_state_ID int
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
	begin
		set @msg = 'Error populating temporary table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

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
							@parmFileName,
							@settingsFileName,
							@organismDBName output,
							@organismName,
							@protCollNameList output,
							@protCollOptionsList output,
							@requestorPRN,
							'', -- blank validation mode to suppress dataset state checking
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
	-- Resolve state name to ID
	---------------------------------------------------
	declare @stateID int
	set @stateID = -1
	SELECT @stateID = ID
	FROM         T_Analysis_Job_Request_State
	WHERE     (StateName = @state)
	
	if @stateID = -1
	begin
		set @msg = 'Could not resolve state name to ID'
		RAISERROR (@msg, 10, 1)
		return 510321
	end

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
			AJR_settingsFileName, AJR_organismDBName, AJR_organismName, 
			AJR_proteinCollectionList, AJR_proteinOptionsList,
			AJR_datasets, AJR_comment, 
			AJR_state, AJR_requestor
		)
		VALUES
		(
			@requestName, getdate(), @toolName, @parmFileName, 
			@settingsFileName, @organismDBName, @organismName, 
			@protCollNameList, @protCollOptionsList,
			@datasets, @comment, 
			@stateID, @userID
		)		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert new job operation failed'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
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
		set @myError = 0
		--
		UPDATE T_Analysis_Job_Request
		SET 
		AJR_requestName = @requestName,
		AJR_analysisToolName = @toolName, 
		AJR_parmFileName = @parmFileName, 
		AJR_settingsFileName = @settingsFileName, 
		AJR_organismDBName = @organismDBName, 
		AJR_organismName = @organismName, 
		AJR_proteinCollectionList = @protCollNameList, 
		AJR_proteinOptionsList = @protCollOptionsList,
		AJR_datasets = @datasets, 
		AJR_comment = @comment, 
		AJR_state = @stateID,
		AJR_requestor = @userID
		WHERE     (AJR_requestID = @requestID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @requestID+ '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode

	return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJobRequest] TO [DMS_User]
GO

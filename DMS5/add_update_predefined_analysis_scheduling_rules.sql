/****** Object:  StoredProcedure [dbo].[AddUpdatePredefinedAnalysisSchedulingRules] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddUpdatePredefinedAnalysisSchedulingRules
/****************************************************
**
**	Desc: Adds new or edits existing T_Predefined_Analysis_Scheduling_Rules
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	06/23/2005
**			03/15/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**			03/16/2007 mem - Updated to use processor group ID (Ticket #419)
**			02/28/2014 mem - Now auto-converting null values to empty strings
**			06/13/2017 mem - Use SCOPE_IDENTITY()
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@evaluationOrder smallint,
	@instrumentClass varchar(32),
	@instrumentName varchar(64),
	@datasetName varchar(128),
	@analysisToolName varchar(64),
	@priority int,
	@processorGroup varchar(64),
	@enabled tinyint,
	@ID int output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	declare @processorGroupID int
	
	set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdatePredefinedAnalysisSchedulingRules', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @processorGroup = LTrim(RTrim(IsNull(@processorGroup, '')))
	set @processorGroupID = Null
	
	Set @instrumentClass = IsNull(@instrumentClass, '')
	Set @instrumentName = IsNull(@instrumentName, '')
	Set @datasetName = IsNull(@datasetName, '')
	
	If Len(@processorGroup) > 0
	Begin
		-- Validate @processorGroup and determine the ID value
		
		SELECT @processorGroupID = ID
		FROM dbo.T_Analysis_Job_Processor_Group
		WHERE Group_Name = @processorGroup
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
				
		if @myRowCount = 0 OR @processorGroupID Is Null
		begin
			set @message = 'Processor group not found: ' + @processorGroup
			RAISERROR (@message, 10, 1)
			return 51007
		end
	End

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_Predefined_Analysis_Scheduling_Rules
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
		begin
			set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			return 51007
		end
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Predefined_Analysis_Scheduling_Rules (
			SR_evaluationOrder, 
			SR_instrumentClass, 
			SR_instrument_Name, 
			SR_dataset_Name, 
			SR_analysisToolName, 
			SR_priority, 
			SR_processorGroupID, 
			SR_enabled
		) VALUES (
			@evaluationOrder, 
			@instrumentClass, 
			@instrumentName, 
			@datasetName, 
			@analysisToolName, 
			@priority, 
			@processorGroupID, 
			@enabled
		)
			--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		end

		-- Return ID of newly created entry
		--
		set @ID = SCOPE_IDENTITY()

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--

		UPDATE T_Predefined_Analysis_Scheduling_Rules 
		SET 
			SR_evaluationOrder = @evaluationOrder, 
			SR_instrumentClass = @instrumentClass, 
			SR_instrument_Name = @instrumentName, 
			SR_dataset_Name = @datasetName, 
			SR_analysisToolName = @analysisToolName, 
			SR_priority = @priority, 
			SR_processorGroupID = @processorGroupID, 
			SR_enabled = @enabled
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + Convert(varchar(12), @ID) + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		end
	end -- update mode

	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePredefinedAnalysisSchedulingRules] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysisSchedulingRules] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysisSchedulingRules] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePredefinedAnalysisSchedulingRules] TO [Limited_Table_Write] AS [dbo]
GO

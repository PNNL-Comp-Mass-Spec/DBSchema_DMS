/****** Object:  StoredProcedure [dbo].[AddUpdatePredefinedAnalysis] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.AddUpdatePredefinedAnalysis
/****************************************************
** 
**	Desc: Adds a new default analysis to DB 
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	grk
**	Date:	06/21/2005 grk - superseded AddUpdateDefaultAnalysis
**			03/28/2006 grk - added protein collection fields
**			01/26/2007 mem - Switched to organism ID instead of organism name (Ticket #368)
**    
*****************************************************/
(
	@level int,
	@sequence varchar(12),
	@instrumentClassCriteria varchar(32),
	@campaignNameCriteria varchar(128),
	@experimentNameCriteria varchar(128),
	@instrumentNameCriteria varchar(64),
	@organismNameCriteria varchar(64),
	@datasetNameCriteria varchar(128),
	@expCommentCriteria varchar(128),
	@labellingInclCriteria varchar(64),
	@labellingExclCriteria varchar(64),
	@analysisToolName varchar(64),
	@parmFileName varchar(255),
	@settingsFileName varchar(255),
	@organismName varchar(64),
	@organismDBName varchar(64),
	@protCollNameList varchar(512),
	@protCollOptionsList varchar(256),
	@priority int,
	@enabled tinyint,
	@description varchar(255),
	@creator varchar(50),
	@nextLevel varchar(12),
	@ID int output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''


	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(IsNull(@analysisToolName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Analysis tool name was blank',
			10, 1)
	end


	if LEN(IsNull(@parmFileName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Parameter file name was blank',
			10, 1)
	end

	if LEN(IsNull(@settingsFileName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Settings file name was blank',
			10, 1)
	end


	if LEN(IsNull(@organismName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Organism name was blank; use "(default)" to auto-assign at job creation',
			10, 1)
	end


	if LEN(IsNull(@organismDBName,'')) < 1
	begin
		set @myError = 51033
		RAISERROR ('Organism DB name was blank',
			10, 1)
	end
	
	---------------------------------------------------
	-- Validate @sequence and @nextLevel
	---------------------------------------------------

	declare @seqVal int
	declare @nextLevelVal int

	if @sequence <> ''
	set @seqVal = convert(int, @sequence)

	if @nextLevel <> ''
	begin
	set @nextLevelVal = convert(int, @nextLevel)
	if @nextLevelVal <= @level 
		begin
			set @message = 'Next level must be greater than current level'
			RAISERROR (@message, 10, 1)
			return 51007
		end
	end

	---------------------------------------------------
	-- Resolve organism ID
	---------------------------------------------------

	declare @organismID int
	execute @organismID = GetOrganismID @organismName
	if @organismID = 0
	begin
		set @message = 'Could not find entry in database for organismName "' + @organismName + '"'
		RAISERROR (@message, 10, 1)
		return 51038
	end

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
	SELECT @tmp = AD_ID
		FROM  T_Predefined_Analysis
	WHERE (AD_ID = @ID)
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

	INSERT INTO T_Predefined_Analysis (
		AD_level, 
		AD_sequence, 
		AD_instrumentClassCriteria, 
		AD_campaignNameCriteria, 
		AD_experimentNameCriteria, 
		AD_instrumentNameCriteria, 
		AD_organismNameCriteria, 
		AD_datasetNameCriteria, 
		AD_expCommentCriteria, 
		AD_labellingInclCriteria, 
		AD_labellingExclCriteria, 
		AD_analysisToolName, 
		AD_parmFileName, 
		AD_settingsFileName, 
		AD_organism_ID, 
		AD_organismDBName, 
		AD_proteinCollectionList,
		AD_proteinOptionsList,
		AD_priority, 
		AD_enabled, 
		AD_description, 
		AD_creator,
		AD_nextLevel 
	) VALUES (
		@level, 
		@seqVal, 
		@instrumentClassCriteria, 
		@campaignNameCriteria, 
		@experimentNameCriteria, 
		@instrumentNameCriteria, 
		@organismNameCriteria, 
		@datasetNameCriteria, 
		@expCommentCriteria, 
		@labellingInclCriteria, 
		@labellingExclCriteria, 
		@analysisToolName, 
		@parmFileName, 
		@settingsFileName, 
		@organismID, 
		@organismDBName, 
		@protCollNameList,
		@protCollOptionsList,
		@priority, 
		@enabled, 
		@description, 
		@creator,
		@nextLevelVal
	)
	/**/
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
	set @message = 'Insert operation failed'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	-- return IDof newly created entry
	--
	set @ID = IDENT_CURRENT('T_Predefined_Analysis')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
	set @myError = 0
	--
	UPDATE T_Predefined_Analysis 
	SET 
		AD_level = @level, 
		AD_sequence = @seqVal, 
		AD_instrumentClassCriteria = @instrumentClassCriteria, 
		AD_campaignNameCriteria = @campaignNameCriteria, 
		AD_experimentNameCriteria = @experimentNameCriteria, 
		AD_instrumentNameCriteria = @instrumentNameCriteria, 
		AD_organismNameCriteria = @organismNameCriteria, 
		AD_datasetNameCriteria = @datasetNameCriteria, 
		AD_expCommentCriteria = @expCommentCriteria, 
		AD_labellingInclCriteria = @labellingInclCriteria, 
		AD_labellingExclCriteria = @labellingExclCriteria, 
		AD_analysisToolName = @analysisToolName, 
		AD_parmFileName = @parmFileName, 
		AD_settingsFileName = @settingsFileName, 
		AD_organism_ID = @organismID, 
		AD_organismDBName = @organismDBName, 
		AD_proteinCollectionList = @protCollNameList,
		AD_proteinOptionsList = @protCollOptionsList,
		AD_priority = @priority, 
		AD_enabled = @enabled, 
		AD_description = @description, 
		AD_creator = @creator,
		AD_nextLevel = @nextLevelVal
	WHERE (AD_ID = @ID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Update operation failed: "' + @ID + '"'
		RAISERROR (@message, 10, 1)
		return 51004
	end
	end -- update mode

	return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysis] TO [DMS_Analysis]
GO

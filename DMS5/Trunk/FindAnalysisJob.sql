/****** Object:  StoredProcedure [dbo].[FindAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.FindAnalysisJob
/****************************************************
**
**	Desc: 
**		Returns result set of Analysis Jobs 
**		satisfying the search parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	07/05/2005
**			03/28/2006 grk - added protein collection fields
**			12/20/2006 mem - Now querying V_Find_Analysis_Job using dynamic SQL (Ticket #349)
**			12/21/2006 mem - Now joining in table T_Analysis_State_Name when querying on State (Ticket #349)
**			10/30/2007 jds - Added support for list of RunRequest IDs (Ticket #560)
**			12/12/2007 mem - No longer joining V_Analysis_Job_and_Dataset_Archive_State since that view is longer used in V_Find_Analysis_Job (Ticket #585)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@Job varchar(20) = '',
	@Pri varchar(20) = '',
	@State varchar(32) = '',
	@Tool varchar(64) = '',
	@Dataset varchar(128) = '',
	@Campaign varchar(50) = '',
	@Experiment varchar(50) = '',
	@Instrument varchar(24) = '',
	@ParmFile varchar(255) = '',
	@SettingsFile varchar(255) = '',
	@Organism varchar(50) = '',
	@OrganismDB varchar(64) = '',
	@proteinCollectionList varchar(512) = '',
	@proteinOptionsList varchar(256) = '',
	@Comment varchar(255) = '',
	@Created_After varchar(20) = '',
	@Created_Before varchar(20) = '',
	@Started_After varchar(20) = '',
	@Started_Before varchar(20) = '',
	@Finished_After varchar(20) = '',
	@Finished_Before varchar(20) = '',
	@Processor varchar(64) = '',
	@RunRequest varchar(255) = '',
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	declare @S varchar(4000)
	declare @W varchar(3800)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated

	---------------------------------------------------
	-- Convert input fields
	---------------------------------------------------

	DECLARE @i_Job int
	SET @i_Job = CONVERT(int, @Job)
	--
	DECLARE @i_Pri int
	SET @i_Pri = CONVERT(int, @Pri)
	--
	DECLARE @i_State varchar(32)
	SET @i_State = '%' + @State + '%'
	--
	DECLARE @i_Tool varchar(64)
	SET @i_Tool = '%' + @Tool + '%'
	--
	DECLARE @i_Dataset varchar(128)
	SET @i_Dataset = '%' + @Dataset + '%'
	--
	DECLARE @i_Campaign varchar(50)
	SET @i_Campaign = '%' + @Campaign + '%'
	--
	DECLARE @i_Experiment varchar(50)
	SET @i_Experiment = '%' + @Experiment + '%'
	--
	DECLARE @i_Instrument varchar(24)
	SET @i_Instrument = '%' + @Instrument + '%'
	--
	DECLARE @i_Parm_File varchar(255)
	SET @i_Parm_File = '%' + @ParmFile + '%'
	--
	DECLARE @i_Settings_File varchar(255)
	SET @i_Settings_File = '%' + @SettingsFile + '%'
	--
	DECLARE @i_Organism varchar(50)
	SET @i_Organism = '%' + @Organism + '%'
	--
	DECLARE @i_Organism_DB varchar(64)
	SET @i_Organism_DB = '%' + @OrganismDB + '%'
	--
	DECLARE @i_Comment varchar(255)
	SET @i_Comment = '%' + @Comment + '%'
	--
	DECLARE @i_Created_after smalldatetime
	DECLARE @i_Created_before smalldatetime
	SET @i_Created_after = CONVERT(smalldatetime, @Created_After)
	SET @i_Created_before = CONVERT(smalldatetime, @Created_Before)
	--
	DECLARE @i_Started_after smalldatetime
	DECLARE @i_Started_before smalldatetime
	SET @i_Started_after = CONVERT(smalldatetime, @Started_After)
	SET @i_Started_before = CONVERT(smalldatetime, @Started_Before)
	--
	DECLARE @i_Finished_after smalldatetime
	DECLARE @i_Finished_before smalldatetime
	SET @i_Finished_after = CONVERT(smalldatetime, @Finished_After)
	SET @i_Finished_before = CONVERT(smalldatetime, @Finished_Before)
	--
	DECLARE @i_Processor varchar(64)
	SET @i_Processor = '%' + @Processor + '%'
	--
	--DECLARE @i_Run_Request int
	--SET @i_Run_Request = CONVERT(int, @RunRequest)
	--
	DECLARE @iAJ_proteinCollectionList varchar(512)
	SET @iAJ_proteinCollectionList = '%' + @proteinCollectionList + '%'
	--
	DECLARE @iAJ_proteinOptionsList varchar(256)
	SET @iAJ_proteinOptionsList = '%' + @proteinOptionsList + '%'
	--

	---------------------------------------------------
	-- Construct the query
	---------------------------------------------------
	Set @S = ' SELECT FAJ.* FROM V_Find_Analysis_Job AS FAJ'
	
	Set @W = ''
	If Len(@Job) > 0
		Set @W = @W + ' AND ([Job] = ' + Convert(varchar(19), @i_Job) + ' )'
	If Len(@Pri) > 0
		Set @W = @W + ' AND ([Pri] = ' + Convert(varchar(19), @i_Pri) + ' )'
	If Len(@State) > 0
		Set @W = @W + ' AND ([State] LIKE ''' + @i_State + ''' )'
	If Len(@Tool) > 0
		Set @W = @W + ' AND ([Tool] LIKE ''' + @i_Tool + ''' )'
	If Len(@Dataset) > 0
		Set @W = @W + ' AND ([Dataset] LIKE ''' + @i_Dataset + ''' )'
	If Len(@Campaign) > 0
		Set @W = @W + ' AND ([Campaign] LIKE ''' + @i_Campaign + ''' )'
	If Len(@Experiment) > 0
		Set @W = @W + ' AND ([Experiment] LIKE ''' + @i_Experiment + ''' )'
	If Len(@Instrument) > 0
		Set @W = @W + ' AND ([Instrument] LIKE ''' + @i_Instrument + ''' )'
	If Len(@ParmFile) > 0
		Set @W = @W + ' AND ([Parm_File] LIKE ''' + @i_Parm_File + ''' )'
	If Len(@SettingsFile) > 0
		Set @W = @W + ' AND ([Settings_File] LIKE ''' + @i_Settings_File + ''' )'
	If Len(@Organism) > 0
		Set @W = @W + ' AND ([Organism] LIKE ''' + @i_Organism + ''' )'
	If Len(@OrganismDB) > 0
		Set @W = @W + ' AND ([Organism_DB] LIKE ''' + @i_Organism_DB + ''' )'
	If Len(@Comment) > 0
		Set @W = @W + ' AND ([Comment] LIKE ''' + @i_Comment + ''' )'
		
	If Len(@Created_After) > 0
		Set @W = @W + ' AND ([Created] >= ''' + Convert(varchar(32), @i_Created_after, 121) + ''' )'
	If Len(@Created_Before) > 0
		Set @W = @W + ' AND ([Created] < ''' + Convert(varchar(32), @i_Created_before, 121) + ''' )'
	If Len(@Started_After) > 0
		Set @W = @W + ' AND ([Started] >= ''' + Convert(varchar(32), @i_Started_after, 121) + ''' )'
	If Len(@Started_Before) > 0
		Set @W = @W + ' AND ([Started] < ''' + Convert(varchar(32), @i_Started_before, 121) + ''' )'
	If Len(@Finished_After) > 0
		Set @W = @W + ' AND ([Finished] >= ''' + Convert(varchar(32), @i_Finished_after, 121) + ''' )'
	If Len(@Finished_Before) > 0
		Set @W = @W + ' AND ([Finished] < ''' + Convert(varchar(32), @i_Finished_before, 121) + ''' )'

	If Len(@Processor) > 0
		Set @W = @W + ' AND ([Processor] LIKE ''' + @i_Processor + ''' )'
	If Len(@RunRequest) > 0
		Set @W = @W + ' AND ([Run_Request] IN (' + @RunRequest + ') )'
	If Len(@proteinCollectionList) > 0
		Set @W = @W + ' AND ([ProteinCollection_List] LIKE ''' + @iAJ_proteinCollectionList + ''' )'
	If Len(@proteinOptionsList) > 0
		Set @W = @W + ' AND ([Protein_Options] LIKE ''' + @iAJ_proteinOptionsList + ''' )'
	
	If Len(@W) > 0
	Begin
		-- One or more filters are defined
		-- Remove the first AND from the start of @W and add the word WHERE
		Set @W = 'WHERE ' + Substring(@W, 6, Len(@W) - 5)
		Set @S = @S + ' ' + @W
	End

	---------------------------------------------------
	-- Run the query
	---------------------------------------------------
	EXEC (@S)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error occurred attempting to execute query'
		RAISERROR (@message, 10, 1)
		return 51007
	end
    
	return @myError

GO
GRANT EXECUTE ON [dbo].[FindAnalysisJob] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindAnalysisJob] TO [DMS_User]
GO

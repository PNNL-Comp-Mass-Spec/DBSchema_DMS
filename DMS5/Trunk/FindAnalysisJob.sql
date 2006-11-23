/****** Object:  StoredProcedure [dbo].[FindAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindAnalysisJob
/****************************************************
**
**  Desc: 
**    Returns result set of analysis jobs 
**    satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 07/05/2005
**		    03/28/2006 grk - added protein collection fields
**
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
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
  @RunRequest varchar(20) = '',
  @message varchar(512) output
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
	DECLARE @i_Run_Request int
	SET @i_Run_Request = CONVERT(int, @RunRequest)
	--
	DECLARE @iAJ_proteinCollectionList varchar(512)
	SET @iAJ_proteinCollectionList = '%' + @proteinCollectionList + '%'
	--
	DECLARE @iAJ_proteinOptionsList varchar(256)
	SET @iAJ_proteinOptionsList = '%' + @proteinOptionsList + '%'
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Find_Analysis_Job
  WHERE 
      ( ([Job] = @i_Job ) OR (@Job = '') ) 
  AND ( ([Pri] = @i_Pri ) OR (@Pri = '') ) 
  AND ( ([State] LIKE @i_State ) OR (@State = '') ) 
  AND ( ([Tool] LIKE @i_Tool ) OR (@Tool = '') ) 
  AND ( ([Dataset] LIKE @i_Dataset ) OR (@Dataset = '') ) 
  AND ( ([Campaign] LIKE @i_Campaign ) OR (@Campaign = '') ) 
  AND ( ([Experiment] LIKE @i_Experiment ) OR (@Experiment = '') ) 
  AND ( ([Instrument] LIKE @i_Instrument ) OR (@Instrument = '') ) 
  AND ( ([Parm_File] LIKE @i_Parm_File ) OR (@ParmFile = '') ) 
  AND ( ([Settings_File] LIKE @i_Settings_File ) OR (@SettingsFile = '') ) 
  AND ( ([Organism] LIKE @i_Organism ) OR (@Organism = '') ) 
  AND ( ([Organism_DB] LIKE @i_Organism_DB ) OR (@OrganismDB = '') ) 
  AND ( ([Comment] LIKE @i_Comment ) OR (@Comment = '') ) 
  AND ( ([Created] > @i_Created_after) OR (@Created_After = '') ) 
  AND ( ([Created] < @i_Created_before) OR (@Created_Before = '') ) 
  AND ( ([Started] > @i_Started_after) OR (@Started_After = '') ) 
  AND ( ([Started] < @i_Started_before) OR (@Started_Before = '') ) 
  AND ( ([Finished] > @i_Finished_after) OR (@Finished_After = '') ) 
  AND ( ([Finished] < @i_Finished_before) OR (@Finished_Before = '') ) 
  AND ( ([Processor] LIKE @i_Processor ) OR (@Processor = '') ) 
  AND ( ([Run_Request] = @i_Run_Request ) OR (@RunRequest = '') ) 
  AND ( ([ProteinCollection_List] LIKE @iAJ_proteinCollectionList ) OR (@proteinCollectionList = '') ) 
  AND ( ([Protein_Options] LIKE @iAJ_proteinOptionsList ) OR (@proteinOptionsList = '') ) 
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

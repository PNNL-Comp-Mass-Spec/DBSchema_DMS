/****** Object:  StoredProcedure [dbo].[FindExperiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindExperiment
/****************************************************
**
**  Desc: 
**    Returns result set of Experiment
**    satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 07/06/2005
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @Experiment varchar(50) = '',
  @Researcher varchar(50) = '',
  @Organism varchar(50) = '',
  @Reason varchar(500) = '',
  @Comment varchar(500) = '',
  @Created_After varchar(20) = '',
  @Created_Before varchar(20) = '',
  @Campaign varchar(50) = '',
  @CellCultures varchar(1024) = '',
  @ID varchar(20) = '',
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

	DECLARE @iExperiment varchar(50)
	SET @iExperiment = '%' + @Experiment + '%'
	--
	DECLARE @iResearcher varchar(50)
	SET @iResearcher = '%' + @Researcher + '%'
	--
	DECLARE @iOrganism varchar(50)
	SET @iOrganism = '%' + @Organism + '%'
	--
	DECLARE @iReason varchar(500)
	SET @iReason = '%' + @Reason + '%'
	--
	DECLARE @iComment varchar(500)
	SET @iComment = '%' + @Comment + '%'
	--
	DECLARE @iCreated_after datetime
	DECLARE @iCreated_before datetime
	SET @iCreated_after = CONVERT(datetime, @Created_After)
	SET @iCreated_before = CONVERT(datetime, @Created_Before)
	--
	DECLARE @iCampaign varchar(50)
	SET @iCampaign = '%' + @Campaign + '%'
	--
	DECLARE @iCellCultures varchar(1024)
	SET @iCellCultures = '%' + @CellCultures + '%'
	--
	DECLARE @iID int
	SET @iID = CONVERT(int, @ID)
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Find_Experiment
  WHERE 
      ( ([Experiment] LIKE @iExperiment ) OR (@Experiment = '') ) 
  AND ( ([Researcher] LIKE @iResearcher ) OR (@Researcher = '') ) 
  AND ( ([Organism] LIKE @iOrganism ) OR (@Organism = '') ) 
  AND ( ([Reason] LIKE @iReason ) OR (@Reason = '') ) 
  AND ( ([Comment] LIKE @iComment ) OR (@Comment = '') ) 
  AND ( ([Created] > @iCreated_after) OR (@Created_After = '') ) 
  AND ( ([Created] < @iCreated_before) OR (@Created_Before = '') ) 
  AND ( ([Campaign] LIKE @iCampaign ) OR (@Campaign = '') ) 
  AND ( ([Cell Cultures] LIKE @iCellCultures ) OR (@CellCultures = '') ) 
  AND ( ([ID] = @iID ) OR (@ID = '') ) 
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
GRANT EXECUTE ON [dbo].[FindExperiment] TO [DMS_User]
GO

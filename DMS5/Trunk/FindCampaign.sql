/****** Object:  StoredProcedure [dbo].[FindCampaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindCampaign
/****************************************************
**
**  Desc: 
**    Returns result set of Campaign_Detail_Report_Ex
**    satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 07/31/2006
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @Campaign varchar(50) = '',
  @Project varchar(50) = '',
  @ProjectMgr varchar(103) = '',
  @PI varchar(103) = '',
  @Comment varchar(500) = '',
  @Created_After varchar(20) = '',
  @Created_Before varchar(20) = '',
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

	DECLARE @iCampaign varchar(50)
	SET @iCampaign = '%' + @Campaign + '%'
	--
	DECLARE @iProject varchar(50)
	SET @iProject = '%' + @Project + '%'
	--
	DECLARE @iProjectMgr varchar(103)
	SET @iProjectMgr = '%' + @ProjectMgr + '%'
	--
	DECLARE @iPI varchar(103)
	SET @iPI = '%' + @PI + '%'
	--
	DECLARE @iComment varchar(500)
	SET @iComment = '%' + @Comment + '%'
	--
	DECLARE @iCreated_after datetime
	DECLARE @iCreated_before datetime
	SET @iCreated_after = CONVERT(datetime, @Created_After)
	SET @iCreated_before = CONVERT(datetime, @Created_Before)
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Campaign_Detail_Report_Ex
  WHERE 
      ( ([Campaign] LIKE @iCampaign ) OR (@Campaign = '') ) 
  AND ( ([Project] LIKE @iProject ) OR (@Project = '') ) 
  AND ( ([ProjectMgr] LIKE @iProjectMgr ) OR (@ProjectMgr = '') ) 
  AND ( ([PI] LIKE @iPI ) OR (@PI = '') ) 
  AND ( ([Comment] LIKE @iComment ) OR (@Comment = '') ) 
  AND ( ([Created] > @iCreated_after) OR (@Created_After = '') ) 
  AND ( ([Created] < @iCreated_before) OR (@Created_Before = '') ) 
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
GRANT EXECUTE ON [dbo].[FindCampaign] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindCampaign] TO [DMS_User]
GO

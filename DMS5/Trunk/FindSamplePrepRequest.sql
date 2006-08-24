/****** Object:  StoredProcedure [dbo].[FindSamplePrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindSamplePrepRequest
/****************************************************
**
**  Desc: 
**    Returns result set of sample prep requests
**    satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 05/15/2006
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @RequestID varchar(20) = '',
  @RequestName varchar(128) = '',
  @Created_After varchar(20) = '',
  @Created_Before varchar(20) = '',
  @EstComplete_After varchar(20) = '',
  @EstComplete_Before varchar(20) = '',
  @Priority varchar(20) = '',
  @State varchar(32) = '',
  @Reason varchar(512) = '',
  @PrepMethod varchar(128) = '',
  @RequestedPersonnel varchar(32) = '',
  @AssignedPersonnel varchar(256) = '',
  @Requester varchar(85) = '',
  @Organism varchar(128) = '',
  @BiohazardLevel varchar(12) = '',
  @Campaign varchar(128) = '',
  @Comment varchar(1024) = '',
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

	DECLARE @iRequest_ID int
	SET @iRequest_ID = CONVERT(int, @RequestID)
	--
	DECLARE @iRequest_Name varchar(128)
	SET @iRequest_Name = '%' + @RequestName + '%'
	--
	DECLARE @iCreated_after datetime
	DECLARE @iCreated_before datetime
	SET @iCreated_after = CONVERT(datetime, @Created_After)
	SET @iCreated_before = CONVERT(datetime, @Created_Before)
	--
	DECLARE @iEst_Complete_after datetime
	DECLARE @iEst_Complete_before datetime
	SET @iEst_Complete_after = CONVERT(datetime, @EstComplete_After)
	SET @iEst_Complete_before = CONVERT(datetime, @EstComplete_Before)
	--
	DECLARE @iPriority tinyint
	SET @iPriority = CONVERT(tinyint, @Priority)
	--
	DECLARE @iState varchar(32)
	SET @iState = '%' + @State + '%'
	--
	DECLARE @iReason varchar(512)
	SET @iReason = '%' + @Reason + '%'
	--
	DECLARE @iPrep_Method varchar(128)
	SET @iPrep_Method = '%' + @PrepMethod + '%'
	--
	DECLARE @iRequested_Personnel varchar(32)
	SET @iRequested_Personnel = '%' + @RequestedPersonnel + '%'
	--
	DECLARE @iAssigned_Personnel varchar(256)
	SET @iAssigned_Personnel = '%' + @AssignedPersonnel + '%'
	--
	DECLARE @iRequester varchar(85)
	SET @iRequester = '%' + @Requester + '%'
	--
	DECLARE @iOrganism varchar(128)
	SET @iOrganism = '%' + @Organism + '%'
	--
	DECLARE @iBiohazard_Level varchar(12)
	SET @iBiohazard_Level = '%' + @BiohazardLevel + '%'
	--
	DECLARE @iCampaign varchar(128)
	SET @iCampaign = '%' + @Campaign + '%'
	--
	DECLARE @iComment varchar(1024)
	SET @iComment = '%' + @Comment + '%'
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Find_Sample_Prep_Request
  WHERE 
      ( ([Request_ID] = @iRequest_ID ) OR (@RequestID = '') ) 
  AND ( ([Request_Name] LIKE @iRequest_Name ) OR (@RequestName = '') ) 
  AND ( ([Created] > @iCreated_after) OR (@Created_After = '') ) 
  AND ( ([Created] < @iCreated_before) OR (@Created_Before = '') ) 
  AND ( ([Est_Complete] > @iEst_Complete_after) OR (@EstComplete_After = '') ) 
  AND ( ([Est_Complete] < @iEst_Complete_before) OR (@EstComplete_Before = '') ) 
  AND ( ([Priority] = @iPriority ) OR (@Priority = '') ) 
  AND ( ([State] LIKE @iState ) OR (@State = '') ) 
  AND ( ([Reason] LIKE @iReason ) OR (@Reason = '') ) 
  AND ( ([Prep_Method] LIKE @iPrep_Method ) OR (@PrepMethod = '') ) 
  AND ( ([Requested_Personnel] LIKE @iRequested_Personnel ) OR (@RequestedPersonnel = '') ) 
  AND ( ([Assigned_Personnel] LIKE @iAssigned_Personnel ) OR (@AssignedPersonnel = '') ) 
  AND ( ([Requester] LIKE @iRequester ) OR (@Requester = '') ) 
  AND ( ([Organism] LIKE @iOrganism ) OR (@Organism = '') ) 
  AND ( ([Biohazard_Level] LIKE @iBiohazard_Level ) OR (@BiohazardLevel = '') ) 
  AND ( ([Campaign] LIKE @iCampaign ) OR (@Campaign = '') ) 
  AND ( ([Comment] LIKE @iComment ) OR (@Comment = '') ) 
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
GRANT EXECUTE ON [dbo].[FindSamplePrepRequest] TO [DMS_User]
GO

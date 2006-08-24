/****** Object:  StoredProcedure [dbo].[Find_Scheduled_Run_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE Find_Scheduled_Run_History
/****************************************************
**
**  Desc: 
**    Returns result set of Scheduled Run History
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
  @ReqCreated_After varchar(20) = '',
  @ReqCreated_Before varchar(20) = '',
  @Experiment varchar(50) = '',
  @Dataset varchar(128) = '',
  @DScreated_After varchar(20) = '',
  @DScreated_Before varchar(20) = '',
  @WorkPackage varchar(50) = '',
  @Campaign varchar(50) = '',
  @Requestor varchar(50) = '',
  @Instrument varchar(128) = '',
  @RunType varchar(50) = '',
  @Comment varchar(244) = '',
  @Batch varchar(20) = '',
  @BlockingFactor varchar(50) = '',
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
	DECLARE @iReq_Created_after datetime
	DECLARE @iReq_Created_before datetime
	SET @iReq_Created_after = CONVERT(datetime, @ReqCreated_After)
	SET @iReq_Created_before = CONVERT(datetime, @ReqCreated_Before)
	--
	DECLARE @iExperiment varchar(50)
	SET @iExperiment = '%' + @Experiment + '%'
	--
	DECLARE @iDataset varchar(128)
	SET @iDataset = '%' + @Dataset + '%'
	--
	DECLARE @iDS_created_after datetime
	DECLARE @iDS_created_before datetime
	SET @iDS_created_after = CONVERT(datetime, @DScreated_After)
	SET @iDS_created_before = CONVERT(datetime, @DScreated_Before)
	--
	DECLARE @iWork_Package varchar(50)
	SET @iWork_Package = '%' + @WorkPackage + '%'
	--
	DECLARE @iCampaign varchar(50)
	SET @iCampaign = '%' + @Campaign + '%'
	--
	DECLARE @iRequestor varchar(50)
	SET @iRequestor = '%' + @Requestor + '%'
	--
	DECLARE @iInstrument varchar(128)
	SET @iInstrument = '%' + @Instrument + '%'
	--
	DECLARE @iRun_Type varchar(50)
	SET @iRun_Type = '%' + @RunType + '%'
	--
	DECLARE @iComment varchar(244)
	SET @iComment = '%' + @Comment + '%'
	--
	DECLARE @iBatch int
	SET @iBatch = CONVERT(int, @Batch)
	--
	DECLARE @iBlocking_Factor varchar(50)
	SET @iBlocking_Factor = '%' + @BlockingFactor + '%'
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Find_Scheduled_Run_History
  WHERE 
      ( ([Request_ID] = @iRequest_ID ) OR (@RequestID = '') ) 
  AND ( ([Request_Name] LIKE @iRequest_Name ) OR (@RequestName = '') ) 
  AND ( ([Req_Created] > @iReq_Created_after) OR (@ReqCreated_After = '') ) 
  AND ( ([Req_Created] < @iReq_Created_before) OR (@ReqCreated_Before = '') ) 
  AND ( ([Experiment] LIKE @iExperiment ) OR (@Experiment = '') ) 
  AND ( ([Dataset] LIKE @iDataset ) OR (@Dataset = '') ) 
  AND ( ([DS_created] > @iDS_created_after) OR (@DScreated_After = '') ) 
  AND ( ([DS_created] < @iDS_created_before) OR (@DScreated_Before = '') ) 
  AND ( ([Work_Package] LIKE @iWork_Package ) OR (@WorkPackage = '') ) 
  AND ( ([Campaign] LIKE @iCampaign ) OR (@Campaign = '') ) 
  AND ( ([Requestor] LIKE @iRequestor ) OR (@Requestor = '') ) 
  AND ( ([Instrument] LIKE @iInstrument ) OR (@Instrument = '') ) 
  AND ( ([Run_Type] LIKE @iRun_Type ) OR (@RunType = '') ) 
  AND ( ([Comment] LIKE @iComment ) OR (@Comment = '') ) 
  AND ( ([Batch] = @iBatch ) OR (@Batch = '') ) 
  AND ( ([Blocking_Factor] LIKE @iBlocking_Factor ) OR (@BlockingFactor = '') ) 
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
GRANT EXECUTE ON [dbo].[Find_Scheduled_Run_History] TO [DMS_User]
GO

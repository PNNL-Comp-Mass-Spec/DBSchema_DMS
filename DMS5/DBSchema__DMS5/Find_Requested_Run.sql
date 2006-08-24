/****** Object:  StoredProcedure [dbo].[Find_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE Find_Requested_Run
/****************************************************
**
**  Desc: 
**    Returns result set of requested/scheduled runs
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
  @Experiment varchar(50) = '',
  @Instrument varchar(128) = '',
  @Requester varchar(50) = '',
  @Created_After varchar(20) = '',
  @Created_Before varchar(20) = '',
  @WorkPackage varchar(50) = '',
  @Usage varchar(50) = '',
  @Proposal varchar(10) = '',
  @Comment varchar(244) = '',
  @Note varchar(512) = '',
  @RunType varchar(50) = '',
  @Wellplate varchar(50) = '',
  @Well varchar(50) = '',
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
	DECLARE @iExperiment varchar(50)
	SET @iExperiment = '%' + @Experiment + '%'
	--
	DECLARE @iInstrument varchar(128)
	SET @iInstrument = '%' + @Instrument + '%'
	--
	DECLARE @iRequester varchar(50)
	SET @iRequester = '%' + @Requester + '%'
	--
	DECLARE @iCreated_after datetime
	DECLARE @iCreated_before datetime
	SET @iCreated_after = CONVERT(datetime, @Created_After)
	SET @iCreated_before = CONVERT(datetime, @Created_Before)
	--
	DECLARE @iWork_Package varchar(50)
	SET @iWork_Package = '%' + @WorkPackage + '%'
	--
	DECLARE @iUsage varchar(50)
	SET @iUsage = '%' + @Usage + '%'
	--
	DECLARE @iProposal varchar(10)
	SET @iProposal = '%' + @Proposal + '%'
	--
	DECLARE @iComment varchar(244)
	SET @iComment = '%' + @Comment + '%'
	--
	DECLARE @iNote varchar(512)
	SET @iNote = '%' + @Note + '%'
	--
	DECLARE @iRun_Type varchar(50)
	SET @iRun_Type = '%' + @RunType + '%'
	--
	DECLARE @iWellplate varchar(50)
	SET @iWellplate = '%' + @Wellplate + '%'
	--
	DECLARE @iWell varchar(50)
	SET @iWell = '%' + @Well + '%'
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
  FROM V_Find_Requested_Run
  WHERE 
      ( ([Request_ID] = @iRequest_ID ) OR (@RequestID = '') ) 
  AND ( ([Request_Name] LIKE @iRequest_Name ) OR (@RequestName = '') ) 
  AND ( ([Experiment] LIKE @iExperiment ) OR (@Experiment = '') ) 
  AND ( ([Instrument] LIKE @iInstrument ) OR (@Instrument = '') ) 
  AND ( ([Requester] LIKE @iRequester ) OR (@Requester = '') ) 
  AND ( ([Created] > @iCreated_after) OR (@Created_After = '') ) 
  AND ( ([Created] < @iCreated_before) OR (@Created_Before = '') ) 
  AND ( ([Work_Package] LIKE @iWork_Package ) OR (@WorkPackage = '') ) 
  AND ( ([Usage] LIKE @iUsage ) OR (@Usage = '') ) 
  AND ( ([Proposal] LIKE @iProposal ) OR (@Proposal = '') ) 
  AND ( ([Comment] LIKE @iComment ) OR (@Comment = '') ) 
  AND ( ([Note] LIKE @iNote ) OR (@Note = '') ) 
  AND ( ([Run_Type] LIKE @iRun_Type ) OR (@RunType = '') ) 
  AND ( ([Wellplate] LIKE @iWellplate ) OR (@Wellplate = '') ) 
  AND ( ([Well] LIKE @iWell ) OR (@Well = '') ) 
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
GRANT EXECUTE ON [dbo].[Find_Requested_Run] TO [DMS_User]
GO

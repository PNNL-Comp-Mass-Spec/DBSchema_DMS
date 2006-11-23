/****** Object:  StoredProcedure [dbo].[FindDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindDataset
/****************************************************
**
**  Desc: 
**    Returns result set of Dataset
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
  @ID varchar(20) = '',
  @Dataset varchar(128) = '',
  @Experiment varchar(50) = '',
  @Campaign varchar(50) = '',
  @State varchar(50) = '',
  @Instrument varchar(24) = '',
  @Created_After varchar(20) = '',
  @Created_Before varchar(20) = '',
  @Comment varchar(500) = '',
  @Operator varchar(50) = '',
  @Rating varchar(32) = '',
  @DatasetFolderPath varchar(511) = '',
  @AcqStart_After varchar(20) = '',
  @AcqStart_Before varchar(20) = '',
  @AcqLength_min varchar(20) = '',
  @AcqLength_max varchar(20) = '',
  @ScanCount_min varchar(20) = '',
  @ScanCount_max varchar(20) = '',
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

	DECLARE @iID int
	SET @iID = CONVERT(int, @ID)
	--
	DECLARE @iDataset varchar(128)
	SET @iDataset = '%' + @Dataset + '%'
	--
	DECLARE @iExperiment varchar(50)
	SET @iExperiment = '%' + @Experiment + '%'
	--
	DECLARE @iCampaign varchar(50)
	SET @iCampaign = '%' + @Campaign + '%'
	--
	DECLARE @iState varchar(50)
	SET @iState = '%' + @State + '%'
	--
	DECLARE @iInstrument varchar(24)
	SET @iInstrument = '%' + @Instrument + '%'
	--
	DECLARE @iCreated_after datetime
	DECLARE @iCreated_before datetime
	SET @iCreated_after = CONVERT(datetime, @Created_After)
	SET @iCreated_before = CONVERT(datetime, @Created_Before)
	--
	DECLARE @iComment varchar(500)
	SET @iComment = '%' + @Comment + '%'
	--
	DECLARE @iOperator varchar(50)
	SET @iOperator = '%' + @Operator + '%'
	--
	DECLARE @iRating varchar(32)
	SET @iRating = '%' + @Rating + '%'
	--
	DECLARE @iDatasetFolderPath varchar(511)
	SET @iDatasetFolderPath = '%' + @DatasetFolderPath + '%'
	--
	DECLARE @iAcqStart_after datetime
	DECLARE @iAcqStart_before datetime
	SET @iAcqStart_after = CONVERT(datetime, @AcqStart_After)
	SET @iAcqStart_before = CONVERT(datetime, @AcqStart_Before)
	--
	DECLARE @iAcqLength_min int
	SET @iAcqLength_min = CONVERT(int, @AcqLength_min)
	DECLARE @iAcqLength_max int
	SET @iAcqLength_max = CONVERT(int, @AcqLength_max)
	--
	DECLARE @iScanCount_min int
	SET @iScanCount_min = CONVERT(int, @ScanCount_min)
	DECLARE @iScanCount_max int
	SET @iScanCount_max = CONVERT(int, @ScanCount_max)
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Find_Dataset
  WHERE 
      ( ([ID] = @iID ) OR (@ID = '') ) 
  AND ( ([Dataset] LIKE @iDataset ) OR (@Dataset = '') ) 
  AND ( ([Experiment] LIKE @iExperiment ) OR (@Experiment = '') ) 
  AND ( ([Campaign] LIKE @iCampaign ) OR (@Campaign = '') ) 
  AND ( ([State] LIKE @iState ) OR (@State = '') ) 
  AND ( ([Instrument] LIKE @iInstrument ) OR (@Instrument = '') ) 
  AND ( ([Created] > @iCreated_after) OR (@Created_After = '') ) 
  AND ( ([Created] < @iCreated_before) OR (@Created_Before = '') ) 
  AND ( ([Comment] LIKE @iComment ) OR (@Comment = '') ) 
  AND ( ([Operator] LIKE @iOperator ) OR (@Operator = '') ) 
  AND ( ([Rating] LIKE @iRating ) OR (@Rating = '') ) 
  AND ( ([Dataset Folder Path] LIKE @iDatasetFolderPath ) OR (@DatasetFolderPath = '') ) 
  AND ( ([Acq Start] > @iAcqStart_after) OR (@AcqStart_After = '') ) 
  AND ( ([Acq Start] < @iAcqStart_before) OR (@AcqStart_Before = '') ) 
  AND ( ([Acq Length] >= @iAcqLength_min ) OR (@AcqLength_min = '') ) 
  AND ( ([Acq Length] <= @iAcqLength_max ) OR (@AcqLength_max = '') ) 
  AND ( ([Scan Count] >= @iScanCount_min ) OR (@ScanCount_min = '') ) 
  AND ( ([Scan Count] <= @iScanCount_max ) OR (@ScanCount_max = '') ) 
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
GRANT EXECUTE ON [dbo].[FindDataset] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindDataset] TO [DMS_User]
GO

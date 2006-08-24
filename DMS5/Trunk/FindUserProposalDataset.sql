/****** Object:  StoredProcedure [dbo].[FindUserProposalDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE FindUserProposalDataset
/****************************************************
**
**  Desc: 
**    Returns result set of Datasets
**    satisfying the EUS search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 08/09/2006
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @UserProposalIDList varchar(512) = '',
  @DatasetName varchar(128) = '',
  @InstrumentName varchar(24) = '',
  @AcquisitionStart_After varchar(20) = '',
  @AcquisitionStart_Before varchar(20) = '',
  @AcquisitionEnd_After varchar(20) = '',
  @AcquisitionEnd_Before varchar(20) = '',
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

	--
	DECLARE @iDataset_Name varchar(128)
	SET @iDataset_Name = '%' + @DatasetName + '%'
	--
	DECLARE @iInstrument_Name varchar(24)
	SET @iInstrument_Name = '%' + @InstrumentName + '%'
	--
	DECLARE @iAcquisition_Start_after datetime
	DECLARE @iAcquisition_Start_before datetime
	SET @iAcquisition_Start_after = CONVERT(datetime, @AcquisitionStart_After)
	SET @iAcquisition_Start_before = CONVERT(datetime, @AcquisitionStart_Before)
	--
	DECLARE @iAcquisition_End_after datetime
	DECLARE @iAcquisition_End_before datetime
	SET @iAcquisition_End_after = CONVERT(datetime, @AcquisitionEnd_After)
	SET @iAcquisition_End_before = CONVERT(datetime, @AcquisitionEnd_Before)
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Find_User_Proposal_Dataset
  WHERE 
      ( ([User_Proposal_ID] IN (select Item from MakeTableFromList(@UserProposalIDList)) ) OR (@UserProposalIDList = '') ) 
  AND ( ([Dataset_Name] LIKE @iDataset_Name ) OR (@DatasetName = '') ) 
  AND ( ([Instrument_Name] LIKE @iInstrument_Name ) OR (@InstrumentName = '') ) 
  AND ( ([Acquisition_Start] > @iAcquisition_Start_after) OR (@AcquisitionStart_After = '') ) 
  AND ( ([Acquisition_Start] < @iAcquisition_Start_before) OR (@AcquisitionStart_Before = '') ) 
  AND ( ([Acquisition_End] > @iAcquisition_End_after) OR (@AcquisitionEnd_After = '') ) 
  AND ( ([Acquisition_End] < @iAcquisition_End_before) OR (@AcquisitionEnd_Before = '') ) 
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
GRANT EXECUTE ON [dbo].[FindUserProposalDataset] TO [DMS_User]
GO

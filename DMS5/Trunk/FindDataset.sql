/****** Object:  StoredProcedure [dbo].[FindDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE dbo.FindDataset
/****************************************************
**
**	Desc: 
**		Returns result set of Datasets
**		satisfying the search parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	07/06/2005
**			12/20/2006 mem - Now querying V_Find_Dataset using dynamic SQL (Ticket #349)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
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
	-- Construct the query
	---------------------------------------------------
	Set @S = ' SELECT * FROM V_Find_Dataset'
	
	Set @W = ''
	If Len(@ID) > 0
		Set @W = @W + ' AND ([ID] = ' + Convert(varchar(19), @iID) + ' )'
	If Len(@Dataset) > 0
		Set @W = @W + ' AND ([Dataset] LIKE ''' + @iDataset + ''' )'
	If Len(@Experiment) > 0
		Set @W = @W + ' AND ([Experiment] LIKE ''' + @iExperiment + ''' )'
	If Len(@Campaign) > 0
		Set @W = @W + ' AND ([Campaign] LIKE ''' + @iCampaign + ''' )'
	If Len(@State) > 0
		Set @W = @W + ' AND ([State] LIKE ''' + @iState + ''' )'
	If Len(@Instrument) > 0
		Set @W = @W + ' AND ([Instrument] LIKE ''' + @iInstrument + ''' )'
	If Len(@Created_After) > 0
		Set @W = @W + ' AND ([Created] >= ''' + Convert(varchar(32), @iCreated_after, 121) + ''' )'
	If Len(@Created_Before) > 0
		Set @W = @W + ' AND ([Created] < ''' + Convert(varchar(32), @iCreated_before, 121) + ''' )'
	If Len(@Comment) > 0
		Set @W = @W + ' AND ([Comment] LIKE ''' + @iComment + ''' )'
	If Len(@Operator) > 0
		Set @W = @W + ' AND ([Operator] LIKE ''' + @iOperator + ''' )'
	If Len(@Rating) > 0
		Set @W = @W + ' AND ([Rating] LIKE ''' + @iRating + ''' )'
	If Len(@DatasetFolderPath) > 0
		Set @W = @W + ' AND ([Dataset Folder Path] LIKE ''' + @iDatasetFolderPath + ''' )'

	If Len(@AcqStart_After) > 0
		Set @W = @W + ' AND ([Acq Start] >= ''' + Convert(varchar(32), @iAcqStart_after, 121) + ''' )'
	If Len(@AcqStart_Before) > 0
		Set @W = @W + ' AND ([Acq Start] < ''' + Convert(varchar(32), @iAcqStart_before, 121) + ''' )'
	If Len(@AcqLength_min) > 0
		Set @W = @W + ' AND ([Acq Length] >= ' + Convert(varchar(19), @iAcqLength_min) + ' )'
	If Len(@AcqLength_max) > 0
		Set @W = @W + ' AND ([Acq Length] < ' + Convert(varchar(19), @iAcqLength_max) + ' )'
	If Len(@ScanCount_min) > 0
		Set @W = @W + ' AND ([Scan Count] >= ' + Convert(varchar(19), @iScanCount_min) + ' )'
	If Len(@ScanCount_max) > 0
		Set @W = @W + ' AND ([Scan Count] < ' + Convert(varchar(19), @iScanCount_max) + ' )'

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
GRANT EXECUTE ON [dbo].[FindDataset] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindDataset] TO [DMS_User]
GO

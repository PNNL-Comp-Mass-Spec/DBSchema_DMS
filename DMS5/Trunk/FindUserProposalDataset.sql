/****** Object:  StoredProcedure [dbo].[FindUserProposalDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE dbo.FindUserProposalDataset
/****************************************************
**
**	Desc: 
**		Returns result set of Datasets
**		satisfying the EUS search parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	08/09/2006
**			12/20/2006 mem - Now querying V_Find_User_Proposal_Dataset using dynamic SQL (Ticket #349)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@UserProposalIDList varchar(512) = '',
	@DatasetName varchar(128) = '',
	@InstrumentName varchar(24) = '',
	@AcquisitionStart_After varchar(20) = '',
	@AcquisitionStart_Before varchar(20) = '',
	@AcquisitionEnd_After varchar(20) = '',
	@AcquisitionEnd_Before varchar(20) = '',
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
	-- Construct the query
	---------------------------------------------------
	Set @S = ' SELECT * FROM V_Find_User_Proposal_Dataset'
	
	Set @W = ''
	If Len(@UserProposalIDList) > 0
		Set @W = @W + ' AND ( [User_Proposal_ID] IN (select Item from MakeTableFromList(''' + @UserProposalIDList + ''')) )'
	If Len(@DatasetName) > 0
		Set @W = @W + ' AND ([Dataset_Name] LIKE ''' + @iDataset_Name + ''' )'
	If Len(@InstrumentName) > 0
		Set @W = @W + ' AND ([Instrument_Name] LIKE ''' + @iInstrument_Name + ''' )'

	If Len(@AcquisitionStart_After) > 0
		Set @W = @W + ' AND ([Acquisition_Start] >= ''' + Convert(varchar(32), @iAcquisition_Start_after, 121) + ''' )'
	If Len(@AcquisitionStart_Before) > 0
		Set @W = @W + ' AND ([Acquisition_Start] < ''' + Convert(varchar(32), @iAcquisition_Start_before, 121) + ''' )'
	If Len(@AcquisitionEnd_After) > 0
		Set @W = @W + ' AND ([Acquisition_End] >= ''' + Convert(varchar(32), @iAcquisition_End_after, 121) + ''' )'
	If Len(@AcquisitionEnd_Before) > 0
		Set @W = @W + ' AND ([Acquisition_End] < ''' + Convert(varchar(32), @iAcquisition_End_before, 121) + ''' )'

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
GRANT EXECUTE ON [dbo].[FindUserProposalDataset] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindUserProposalDataset] TO [DMS_User]
GO

/****** Object:  StoredProcedure [dbo].[RequestSynopsisCountOrDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.RequestSynopsisCountOrDataset
/****************************************************
**
**	Desc: Gets the count or dataset for a Synopsis request
**	If the getCount value is set to 1 then the count is returned
**	otherwise, the dataset is returned.  The count is used for 
**	validation when the request is initially entered.
**	When requesting the dataset the Scrolling Dates input parameters 
**	are ignored.
**
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	jds
**	Date:	12/16/2004
**			12/17/2004 jds
**			07/25/2005 jds - Increased size of the @datasetMatchList parameter from 255 to 2048 characters
**			07/27/2005 mem - Increased size of variables populated using CreateLikeClauseFromSeparatedString
**			06/29/2006 mem - Added support for Protein Collection Lists
*****************************************************/
(
	@getCount int,
	@SynScrollDSDates varchar(32),
	@SynScrollDSTimeFrame varchar(32),
	@SynScrollJobDates varchar(32),
	@SynScrollJobTimeFrame varchar(32),
	@datasetRecCount int output,						-- Old, unused parameter
	@datasetMatchList varchar(2048) = '' output,
	@instrumentMatchList varchar(255) = '' output,
	@paramFileMatchList varchar(255) = '' output,
	@fastaFileMatchList varchar(255) = '' output,		-- Compared to [Organism DB] and to [Protein Collection List]
	@comparisonJobNumber int = NULL output,
	@datasetStartDate varchar(10) = '1/1/2000' output,
	@datasetEndDate varchar(10) output,
	@jobStartDate varchar(10) = '1/1/2000' output,
	@jobEndDate varchar(10) output,
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	set @message = ''

	declare @DatasetStr varchar(4096)
	declare @InstrumentStr varchar(1024)
	declare @ParamFileStr varchar(1024)
	declare @OrganismStr varchar(1024)
	declare @ProtCollectionStr varchar(1024)
	declare @DSStartDateStr varchar(200)
	declare @JobStartDateStr varchar(200)
	declare @SqlA varchar(6000)
	declare @SqlB varchar(8000)
	declare	@SynDSStartDateTemp varchar(10)
	declare	@SynDSEndDateTemp varchar(10)
	declare	@SynJobStartDateTemp varchar(10)
	declare	@SynJobEndDateTemp varchar(10)

	---------------------------------------------------
	-- build the dynamic query 
	---------------------------------------------------
	set @DatasetStr = (select dbo.CreateLikeClauseFromSeparatedString(@datasetMatchList, '[Dataset]', ','))
	set @InstrumentStr = (select dbo.CreateLikeClauseFromSeparatedString(@instrumentMatchList, '[Instrument]', ','))
	set @ParamFileStr = (select dbo.CreateLikeClauseFromSeparatedString(@paramFileMatchList, '[Parm File]', ','))
	set @OrganismStr = (select dbo.CreateLikeClauseFromSeparatedString(@fastaFileMatchList, '[Organism DB]', ','))
	
	-- Also look for protein collections matching @fastaFileMatchList
	-- Note that we remove .fasta from the end of @fastaFileMatchList if it is present
	declare @ProteinCollectionMatchList varchar(255)
	Set @ProteinCollectionMatchList = LTrim(RTrim(@fastaFileMatchList))
	If @ProteinCollectionMatchList Like '%.fasta'
		Set @ProteinCollectionMatchList = Left(@ProteinCollectionMatchList, Len(@ProteinCollectionMatchList)-6)

	set @ProtCollectionStr = (select dbo.CreateLikeClauseFromSeparatedString(@ProteinCollectionMatchList, '[Protein Collection List]', ','))
	
	set @SqlA = ''
	set @SqlB = ''
	if @getCount = 1 
	begin
		set @SynDSStartDateTemp = ISNULL(@datasetStartDate, '1/1/2000')
		set @SynDSEndDateTemp = ISNULL(@datasetEndDate, convert(char(10), getdate(), 101))
		if cast(@SynScrollDSDates as int) = 1
		begin
			set @SynDSEndDateTemp = convert(char(10), getdate(), 101)
			set @SynDSStartDateTemp = convert(char(10), DATEADD(day,-Cast(@SynScrollDSTimeFrame as integer), getdate()), 101)
		end
		set @DSStartDateStr = ' AND ([Dataset_Created]>''' + @SynDSStartDateTemp + ''')'
		set @DSStartDateStr = @DSStartDateStr + ' AND ([Dataset_Created]<''' + @SynDSEndDateTemp + ''')'
		set @SynJobStartDateTemp = ISNULL(@jobStartDate, '1/1/2000')
		set @SynJobEndDateTemp = ISNULL(@jobEndDate, convert(char(10), getdate(), 101))
		if cast(@SynScrollJobDates as int) = 1
		begin
			set @SynJobEndDateTemp = convert(char(10), getdate(), 101)
			set @SynJobStartDateTemp = convert(char(10), DATEADD(day,-Cast(@SynScrollDSTimeFrame as integer), getdate()), 101)
		end
		set @JobStartDateStr = ' AND ([Finished]>''' + @SynJobStartDateTemp + ''')'
		set @JobStartDateStr = @JobStartDateStr + ' AND ([Finished]<''' + @SynJobEndDateTemp + ''')'
		set @SqlA = @SqlA + ' SELECT COUNT(*) '
	end
	else
	begin
		set @DSStartDateStr = ' AND ([Dataset_Created]>''' + @datasetStartDate + ''')'
		set @DSStartDateStr = @DSStartDateStr + ' AND ([Dataset_Created]<''' + @datasetEndDate + ''')'
		set @JobStartDateStr = ' AND ([Finished]>''' + @jobStartDate + ''')'
		set @JobStartDateStr = @JobStartDateStr + ' AND ([Finished]<''' + @jobEndDate + ''')'
		set @SqlA = @SqlA + ' SELECT * ' 
	end
	set @SqlA = @SqlA + 'FROM (SELECT AJR.*, DDR.Created AS Dataset_Created'
	set @SqlA = @SqlA + ' FROM dbo.V_Analysis_Job_ReportEx AJR INNER JOIN'
	set @SqlA = @SqlA + ' dbo.V_Dataset_Detail_Report DDR ON AJR.Dataset = DDR.Dataset) AS V_JobsForSynopsisReporter'
	set @SqlA = @SqlA + ' WHERE ('
	-- Note: @DatasetStr will be added in to @SqlA and @SqlB below
	
	set @SqlB = @SqlB + ' AND ' + @InstrumentStr
	set @SqlB = @SqlB + ' AND ' + @ParamFileStr
	set @SqlB = @SqlB + ' AND (' + @OrganismStr + ' OR ' + @ProtCollectionStr + ') '
	set @SqlB = @SqlB + @DSStartDateStr
	set @SqlB = @SqlB + @JobStartDateStr
	set @SqlB = @SqlB + ' AND ([Finished] IS NOT NULL)'
	set @SqlB = @SqlB + ' AND ([State]=''Complete'')'
	set @SqlB = @SqlB + ' AND ([Tool Name] in (''Sequest'', ''AgilentSequest'')))'
	set @SqlB = @SqlB + ' OR ([JobNum]=' + cast(@comparisonJobNumber as varchar(32)) + ') '

	-- We're sending three separate varchar variables to Exec() to get around the 8000 character limit of a varchar() variable
	Exec (@SqlA + @DatasetStr + @SqlB)

/*
**  Method using sp_executesql; this is limited to a nvarchar(4000) variable
**

	if @getCount = 1 
		exec sp_executesql @SqlA, N'@xCount int output', @xCount = @datasetRecCount output
	else
		exec sp_executesql @SqlA
*/

	return 0

Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[RequestSynopsisCountOrDataset] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestSynopsisCountOrDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestSynopsisCountOrDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestSynopsisCountOrDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestSynopsisCountOrDataset] TO [PNL\D3M580] AS [dbo]
GO

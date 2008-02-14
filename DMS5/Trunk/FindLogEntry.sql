/****** Object:  StoredProcedure [dbo].[FindLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.FindLogEntry
/****************************************************
**
**	Desc: 
**		Returns result set of main log
**		satisfying the search parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	08/23/2006
**			12/20/2006 mem - Now querying V_Log_Report using dynamic SQL (Ticket #349)
**			01/24/2008 mem - Switched the @i_ variables to use the datetime data type (Ticket #225)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@Entry varchar(20) = '',
	@PostedBy varchar(64) = '',
	@PostingTime_After varchar(20) = '',
	@PostingTime_Before varchar(20) = '',
	@EntryType varchar(32) = '',
	@MessageText varchar(500) = '',
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

	DECLARE @iEntry int
	SET @iEntry = CONVERT(int, @Entry)
	--
	DECLARE @iPostedBy varchar(64)
	SET @iPostedBy = '%' + @PostedBy + '%'
	--
	DECLARE @iPostingTime_after datetime
	DECLARE @iPostingTime_before datetime
	SET @iPostingTime_after = CONVERT(datetime, @PostingTime_After)
	SET @iPostingTime_before = CONVERT(datetime, @PostingTime_Before)
	--
	DECLARE @iType varchar(32)
	SET @iType = '%' + @EntryType + '%'
	--
	DECLARE @iMessage varchar(500)
	SET @iMessage = '%' + @MessageText + '%'
	--

	---------------------------------------------------
	-- Construct the query
	---------------------------------------------------
	Set @S = ' SELECT * FROM V_Log_Report'
	
	Set @W = ''
	If Len(@Entry) > 0
		Set @W = @W + ' AND ([Entry] = ' + Convert(varchar(19), @iEntry) + ' )'
	If Len(@PostedBy) > 0
		Set @W = @W + ' AND ([Posted By] LIKE ''' + @iPostedBy + ''' )'
	If Len(@PostingTime_After) > 0
		Set @W = @W + ' AND ([Posting Time] >= ''' + Convert(varchar(32), @iPostingTime_after, 121) + ''' )'
	If Len(@PostingTime_Before) > 0
		Set @W = @W + ' AND ([Posting Time] < ''' + Convert(varchar(32), @iPostingTime_before, 121) + ''' )'
	If Len(@EntryType) > 0
		Set @W = @W + ' AND ([Type] LIKE ''' + @iType + ''' )'
	If Len(@MessageText) > 0
		Set @W = @W + ' AND ([Message] LIKE ''' + @iMessage + ''' )'

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
GRANT EXECUTE ON [dbo].[FindLogEntry] TO [DMS_Guest]
GO

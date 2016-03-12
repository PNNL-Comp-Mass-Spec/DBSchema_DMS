/****** Object:  StoredProcedure [dbo].[FindArchive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindArchive
/****************************************************
**
**  Desc: 
**    Returns result set
**    satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 08/21/2007
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
  @Dataset varchar(128) = '',
  @ID varchar(20) = '',
  @Instrument varchar(24) = '',
  @Created_After varchar(20) = '',
  @Created_Before varchar(20) = '',
  @State varchar(50) = '',
  @Update varchar(32) = '',
  @Entered_After varchar(20) = '',
  @Entered_Before varchar(20) = '',
  @LastUpdate_After varchar(20) = '',
  @LastUpdate_Before varchar(20) = '',
  @LastVerify_After varchar(20) = '',
  @LastVerify_Before varchar(20) = '',
  @ArchivePath varchar(50) = '',
  @ArchiveServer varchar(32) = '',
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

 	DECLARE @iDataset varchar(128)
	SET @iDataset = '%' + @Dataset + '%'
	--
	DECLARE @iID int
	SET @iID = CONVERT(int, @ID)
	--
 	DECLARE @iInstrument varchar(24)
	SET @iInstrument = '%' + @Instrument + '%'
	--
	DECLARE @iCreated_after datetime
	DECLARE @iCreated_before datetime
	SET @iCreated_after = CONVERT(datetime, @Created_After)
	SET @iCreated_before = CONVERT(datetime, @Created_Before)
	--
 	DECLARE @iState varchar(50)
	SET @iState = '%' + @State + '%'
	--
 	DECLARE @iUpdate varchar(32)
	SET @iUpdate = '%' + @Update + '%'
	--
	DECLARE @iEntered_after datetime
	DECLARE @iEntered_before datetime
	SET @iEntered_after = CONVERT(datetime, @Entered_After)
	SET @iEntered_before = CONVERT(datetime, @Entered_Before)
	--
	DECLARE @iLastUpdate_after datetime
	DECLARE @iLastUpdate_before datetime
	SET @iLastUpdate_after = CONVERT(datetime, @LastUpdate_After)
	SET @iLastUpdate_before = CONVERT(datetime, @LastUpdate_Before)
	--
	DECLARE @iLastVerify_after datetime
	DECLARE @iLastVerify_before datetime
	SET @iLastVerify_after = CONVERT(datetime, @LastVerify_After)
	SET @iLastVerify_before = CONVERT(datetime, @LastVerify_Before)
	--
 	DECLARE @iArchivePath varchar(50)
	SET @iArchivePath = '%' + @ArchivePath + '%'
	--
 	DECLARE @iArchiveServer varchar(32)
	SET @iArchiveServer = '%' + @ArchiveServer + '%'
	--

	---------------------------------------------------
	-- Construct the query
	---------------------------------------------------
	Set @S = ' SELECT * FROM V_Find_Archive'
	Set @W = ''
	If Len(@Dataset) > 0
		Set @W = @W + ' AND ([Dataset] LIKE ''' + @iDataset + ''' )'
	If Len(@ID) > 0
		Set @W = @W + ' AND ([ID] = ' + Convert(varchar(19), @iID) + ' )'
	If Len(@Instrument) > 0
		Set @W = @W + ' AND ([Instrument] LIKE ''' + @iInstrument + ''' )'
	If Len(@Created_After) > 0
		Set @W = @W + ' AND ([Created] >= ''' + Convert(varchar(32), @iCreated_after, 121) + ''' )'
	If Len(@Created_Before) > 0
		Set @W = @W + ' AND ([Created] < ''' + Convert(varchar(32), @iCreated_before, 121) + ''' )'
	If Len(@State) > 0
		Set @W = @W + ' AND ([State] LIKE ''' + @iState + ''' )'
	If Len(@Update) > 0
		Set @W = @W + ' AND ([Update] LIKE ''' + @iUpdate + ''' )'
	If Len(@Entered_After) > 0
		Set @W = @W + ' AND ([Entered] >= ''' + Convert(varchar(32), @iEntered_after, 121) + ''' )'
	If Len(@Entered_Before) > 0
		Set @W = @W + ' AND ([Entered] < ''' + Convert(varchar(32), @iEntered_before, 121) + ''' )'
	If Len(@LastUpdate_After) > 0
		Set @W = @W + ' AND ([Last Update] >= ''' + Convert(varchar(32), @iLastUpdate_after, 121) + ''' )'
	If Len(@LastUpdate_Before) > 0
		Set @W = @W + ' AND ([Last Update] < ''' + Convert(varchar(32), @iLastUpdate_before, 121) + ''' )'
	If Len(@LastVerify_After) > 0
		Set @W = @W + ' AND ([Last Verify] >= ''' + Convert(varchar(32), @iLastVerify_after, 121) + ''' )'
	If Len(@LastVerify_Before) > 0
		Set @W = @W + ' AND ([Last Verify] < ''' + Convert(varchar(32), @iLastVerify_before, 121) + ''' )'
	If Len(@ArchivePath) > 0
		Set @W = @W + ' AND ([Archive Path] LIKE ''' + @iArchivePath + ''' )'
	If Len(@ArchiveServer) > 0
		Set @W = @W + ' AND ([Archive Server] LIKE ''' + @iArchiveServer + ''' )'

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
GRANT VIEW DEFINITION ON [dbo].[FindArchive] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindArchive] TO [PNL\D3M578] AS [dbo]
GO

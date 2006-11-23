/****** Object:  StoredProcedure [dbo].[FindLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.FindLogEntry
/****************************************************
**
**  Desc: 
**    Returns result set of main log
**    satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 08/23/2006
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @Entry varchar(20) = '',
  @PostedBy varchar(64) = '',
  @PostingTime_After varchar(20) = '',
  @PostingTime_Before varchar(20) = '',
  @EntryType varchar(32) = '',
  @MessageText varchar(500) = '',
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

	DECLARE @iEntry int
	SET @iEntry = CONVERT(int, @Entry)
	--
	DECLARE @iPostedBy varchar(64)
	SET @iPostedBy = '%' + @PostedBy + '%'
	--
	DECLARE @iPostingTime_after smalldatetime
	DECLARE @iPostingTime_before smalldatetime
	SET @iPostingTime_after = CONVERT(smalldatetime, @PostingTime_After)
	SET @iPostingTime_before = CONVERT(smalldatetime, @PostingTime_Before)
	--
	DECLARE @iType varchar(32)
	SET @iType = '%' + @EntryType + '%'
	--
	DECLARE @iMessage varchar(500)
	SET @iMessage = '%' + @MessageText + '%'
	--

  ---------------------------------------------------
  -- run query
  ---------------------------------------------------
 
  SELECT *
  FROM V_Log_Report
  WHERE 
      ( ([Entry] = @iEntry ) OR (@Entry = '') ) 
  AND ( ([Posted By] LIKE @iPostedBy ) OR (@PostedBy = '') ) 
  AND ( ([Posting Time] > @iPostingTime_after) OR (@PostingTime_After = '') ) 
  AND ( ([Posting Time] < @iPostingTime_before) OR (@PostingTime_Before = '') ) 
  AND ( ([Type] LIKE @iType ) OR (@EntryType = '') ) 
  AND ( ([Message] LIKE @iMessage ) OR (@MessageText = '') ) 
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

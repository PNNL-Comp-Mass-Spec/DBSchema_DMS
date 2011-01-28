/****** Object:  StoredProcedure [dbo].[AddArchiveDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddArchiveDataset
/****************************************************
**
**	Desc: Make new entry into the archive table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: @datasetID  new entry references this
**                          dataset
**	
**
**		Auth: grk
**		Date: 1/26/2001
**            04/04/2006 grk - added setting holdoff interval
**            01/14/2010 grk - assign storage path on creation of archive entry
**            01/22/2010 grk - existing entry in archive table prevents duplicate, but doesn't raise error
**    
*****************************************************/
(
	@datasetID int
)
As
	declare @holdOffHours int
	set @holdOffHours = 72
	
	DECLARE @myError INT
	SET @myError = 0
	DECLARE @message VARCHAR(512)
	SET @message = ''
	
   	---------------------------------------------------
	-- don't allow duplicate datasetIDs in table
	---------------------------------------------------
	--
	declare @n int
	SELECT @n = COUNT(*)
	FROM T_Dataset_Archive 
	GROUP BY AS_Dataset_ID 
	HAVING (AS_Dataset_ID = @datasetID)
	if @n > 0
	begin
		return
/*
		RAISERROR ('Dataset already in archive table',
			10, 1)
		return 51101
*/
	end

   	---------------------------------------------------
	-- get assigned archive path
	---------------------------------------------------
	--
	declare @archivePathID int
	set @archivePathID = 0
	--
	exec @myError = GetAssignedArchivePath
						@datasetID,
						@archivePathID output,
						@message output
	--
	if @myError <> 0
	begin
		RAISERROR (@message, 10, 1)
		return @myError
	end
	
   	---------------------------------------------------
	-- make entry into archive table
	---------------------------------------------------
	--
	INSERT INTO T_Dataset_Archive
		( AS_Dataset_ID,
		  AS_state_ID,
		  AS_update_state_ID,
		  AS_storage_path_ID,
		  AS_datetime,
		  AS_purge_holdoff_date
		)
	VALUES
		( @datasetID,
		  1,
		  1,
		  @archivePathID,
		  GETDATE(),
		  DATEADD(Hour, @holdOffHours, GETDATE())
		)
	--
	if @@rowcount <> 1
	begin
		RAISERROR ('Update was unsuccessful for archive table',
			10, 1)
		return 51100
	end
	--	print 'new archive table entry'  -- debug only
	return


GO
GRANT EXECUTE ON [dbo].[AddArchiveDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddArchiveDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [PNL\D3M580] AS [dbo]
GO

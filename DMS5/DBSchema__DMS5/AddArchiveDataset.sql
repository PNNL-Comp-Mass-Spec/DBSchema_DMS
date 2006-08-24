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
**            4/4/2006 grk - added setting holdoff interval
**    
*****************************************************/
(
	@datasetID int
)
As
	declare @holdOffHours int
	set @holdOffHours = 72
	
	-- don't allow duplicate datasetIDs in table
	declare @n int
	SELECT @n = COUNT(*)
	FROM T_Dataset_Archive 
	GROUP BY AS_Dataset_ID 
	HAVING (AS_Dataset_ID = @datasetID)
	if @n > 0
	begin
		RAISERROR ('Dataset already in archive table',
			10, 1)
		return 51101
	end
	
	INSERT INTO T_Dataset_Archive
						(AS_Dataset_ID, AS_state_ID, AS_update_state_ID, AS_storage_path_ID, AS_datetime, AS_purge_holdoff_date)
	VALUES     (@datasetID, 1, 1, 0, GETDATE(), DATEADD(Hour, @holdOffHours, GETDATE()))
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
GRANT EXECUTE ON [dbo].[AddArchiveDataset] TO [DMS_SP_User]
GO

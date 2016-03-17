/****** Object:  StoredProcedure [dbo].[GetArchivePathID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




Create Procedure GetArchivePathID
/****************************************************
**
**	Desc: Gets archivePathID for given archive path
**
**	Return values: 0: failure, otherwise, archiveID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
	@archivePath varchar(255)
)
As
	declare @archivePathID int
	set @archivePathID = 0

	SELECT @archivePathID = AP_path_ID 
	FROM T_Archive_Path 
	WHERE (AP_archive_path = @archivePath)
	
	return(@archivePathID)
GO
GRANT EXECUTE ON [dbo].[GetArchivePathID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetArchivePathID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetArchivePathID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetArchivePathID] TO [PNL\D3M580] AS [dbo]
GO

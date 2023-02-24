/****** Object:  StoredProcedure [dbo].[GetArchivePathID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetArchivePathID]
/****************************************************
**
**  Desc: Gets archivePathID for given archive path
**
**  Return values: 0: failure, otherwise, archiveID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @archivePath varchar(255)
)
AS
    Set NoCount On

    Declare @archivePathID int = 0

    SELECT @archivePathID = AP_path_ID
    FROM T_Archive_Path
    WHERE AP_archive_path = @archivePath

    return @archivePathID
GO
GRANT VIEW DEFINITION ON [dbo].[GetArchivePathID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetArchivePathID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetArchivePathID] TO [Limited_Table_Write] AS [dbo]
GO

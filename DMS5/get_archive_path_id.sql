/****** Object:  UserDefinedFunction [dbo].[get_archive_path_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_archive_path_id]
/****************************************************
**
**  Desc: Gets archivePathID for given archive path
**
**  Return values: 0: failure, otherwise, archiveID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @archivePath varchar(255)
)
RETURNS int
AS
BEGIN
    Declare @archivePathID int = 0

    SELECT @archivePathID = AP_path_ID
    FROM T_Archive_Path
    WHERE AP_archive_path = @archivePath

    return @archivePathID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_archive_path_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_archive_path_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_archive_path_id] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[preview_purge_task_candidates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[preview_purge_task_candidates]
/****************************************************
**
**  Desc:
**      Returns the next N datasets that would be purged on the specified server,
**      or on a series of servers (if @StorageServerName and/or @StorageVol are blank)
**      N is 10 if @infoOnly = 1; N is @infoOnly if @infoOnly is greater than 1
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/30/2010 mem - Initial version
**          01/11/2011 mem - Renamed parameter @ServerVol to @ServerDisk when calling request_purge_task
**          02/01/2011 mem - Now passing parameter @ExcludeStageMD5RequiredDatasets to request_purge_task
**          06/07/2013 mem - Now auto-updating @StorageServerName and @StorageVol to match the format required by request_purge_task
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @storageServerName varchar(64) = '',        -- Storage server to use, for example 'proto-9'; if blank, then returns candidates for all storage servers; when blank, then @StorageVol is ignored
    @storageVol varchar(256) = '',              -- Volume on storage server to use, for example 'g:\'; if blank, then returns candidates for all drives on given server (or all servers if @StorageServerName is blank)
    @datasetsPerShare int = 5,                  -- Number of purge candidates to return for each share on each server
    @previewSql tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    --------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------

    Set @StorageServerName = IsNull(@StorageServerName, '')
    Set @StorageVol = IsNull(@StorageVol, '')
    Set @DatasetsPerShare = IsNull(@DatasetsPerShare, 5)
    Set @PreviewSql = IsNull(@PreviewSql, 0)

    Set @message = ''

    If @DatasetsPerShare < 1
        Set @DatasetsPerShare = 1

    -- Auto change \\proto-6 to proto-6
    If @StorageServerName Like '\\%'
        Set @StorageServerName = Substring(@StorageServerName, 3, 50)

    -- Auto change proto-6\ to proto-6
    If @StorageServerName Like '%\'
        Set @StorageServerName = Substring(@StorageServerName, 1, Len(@StorageServerName)-1)

    -- Auto change drive F to F:\
    If @StorageVol Like '[A-Z]'
        Set @StorageVol = @StorageVol + ':\'

    -- Auto change drive F: to F:\
    If @StorageVol Like '[a-z]:'
        Set @StorageVol = @StorageVol + '\'

    Print 'Server: ' + @StorageServerName
    Print 'Volume: ' + @StorageVol

    --------------------------------------------------
    -- Call request_purge_task to obtain the data
    --------------------------------------------------

    Exec @myError = request_purge_task
                        @StorageServerName = @StorageServerName,
                        @ServerDisk = @StorageVol,
                        @ExcludeStageMD5RequiredDatasets = 0,
                        @message = @message output,
                        @infoOnly = @DatasetsPerShare,
                        @PreviewSql = @PreviewSql

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[preview_purge_task_candidates] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[preview_purge_task_candidates] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[preview_purge_task_candidates] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[preview_purge_task_candidates] TO [svc-dms] AS [dbo]
GO

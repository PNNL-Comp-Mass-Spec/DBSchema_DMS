/****** Object:  StoredProcedure [dbo].[GetRemoteInfoID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetRemoteInfoID
/****************************************************
**
**  Desc:
**      Resolves @remoteInfo to the ID in T_Remote_Info
**      Adds a new row to T_Remote_Info if new
**
**  Return values: RemoteInfoID, or 0 if @remoteInfo is empty
**
**  Auth:   mem
**  Date:   05/18/2017 mem - Initial release
**
*****************************************************/
(
    @remoteInfo varchar(900) = '',
    @infoOnly tinyint = 0               -- If 0, update T_Remote_Info if @remoteInfo is new; otherwise, shows a message if @remoteInfo is new
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @remoteInfoId int

    Set @remoteInfo = IsNull(@remoteInfo, '')
    Set @infoOnly = IsNull(@infoOnly, 0)

    If IsNull(@remoteInfo, '') = ''
        Return 0

    ---------------------------------------------------
    -- Look for an existing remote info item
    ---------------------------------------------------

    SELECT @remoteInfoID = Remote_Info_ID
    FROM T_Remote_Info
    WHERE Remote_Info = @remoteInfo
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        If @infoOnly <> 0
        Begin
            SELECT 'Remote info not found in T_Remote_Info' As Status, Null As Remote_Info_ID, @remoteInfo As Remote_Info
        End
        Else
        Begin
            ---------------------------------------------------
            -- Add a new entry to T_Remote_Info
            -- Use a Merge statement to avoid the use of an explicit transaction
            ---------------------------------------------------
            --
            MERGE T_Remote_Info AS target
            USING
                (SELECT @remoteInfo AS Remote_Info
                ) AS Source ( Remote_Info)
            ON (target.Remote_Info = source.Remote_Info)
            WHEN Not Matched THEN
                INSERT (Remote_Info, Entered)
                VALUES (source.Remote_Info, GetDate());
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            SELECT @remoteInfoID = Remote_Info_ID
            FROM T_Remote_Info
            WHERE Remote_Info = @remoteInfo
        End
    End
    Else
    Begin
        If @infoOnly <> 0
        Begin
            SELECT 'Existing item found' As Status, *
            FROM T_Remote_Info
            WHERE Remote_Info_ID = @remoteInfoID
        End
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Return @remoteInfoID

GO

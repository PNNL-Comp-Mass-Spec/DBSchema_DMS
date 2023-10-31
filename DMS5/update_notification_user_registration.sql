/****** Object:  StoredProcedure [dbo].[update_notification_user_registration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_notification_user_registration]
/****************************************************
**
**  Desc:
**  Sets user registration for notification entities
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/03/2010
**          09/02/2011 mem - Now calling post_usage_log_entry
**          06/11/2012 mem - Renamed @Dataset to @DatasetNotReleased
**                         - Added @DatasetReleased
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @username varchar(15),
    @name varchar(64),
    @requestedRunBatch varchar(4),      -- 'Yes' or 'No'
    @analysisJobRequest varchar(4),     -- 'Yes' or 'No'
    @samplePrepRequest varchar(4),      -- 'Yes' or 'No'
    @datasetNotReleased varchar(4),     -- 'Yes' or 'No'
    @datasetReleased varchar(4),        -- 'Yes' or 'No'
    @mode varchar(12) = 'update',
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_notification_user_registration', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Lookup user
    ---------------------------------------------------
    --
    Declare @userID INT = 0
    --
    SELECT @userID = ID
    FROM T_Users
    WHERE U_PRN = @username
    --
    If @userID = 0
    Begin
        Set @message = 'Username "' + @username + '" is not valid'
        Set @myError = 15
        Goto Done
    End

    ---------------------------------------------------
    -- Populate a temporary table with Entity Type IDs and Entity Type Params
    ---------------------------------------------------

    Declare @tblNotificationOptions AS table (
        EntityTypeID int,
        NotifyUser varchar(15)
    )

    INSERT INTO @tblNotificationOptions VALUES (1, @RequestedRunBatch)
    INSERT INTO @tblNotificationOptions VALUES (2, @AnalysisJobRequest)
    INSERT INTO @tblNotificationOptions VALUES (3, @SamplePrepRequest)
    INSERT INTO @tblNotificationOptions VALUES (4, @DatasetNotReleased)
    INSERT INTO @tblNotificationOptions VALUES (5, @DatasetReleased)

    ---------------------------------------------------
    -- Process each entry in @tblNotificationOptions
    ---------------------------------------------------

    Declare @entityTypeID int = 0
    Declare @NotifyUser VARCHAR(15) = 'Yes'
    Declare @continue tinyint = 1

    While @continue = 1
    Begin
        SELECT TOP 1 @entityTypeID = EntityTypeID, @NotifyUser = NotifyUser
        FROM @tblNotificationOptions
        WHERE EntityTypeID > @entityTypeID
        ORDER BY EntityTypeID
        --
        SELECT @myRowCount = @@RowCount

        If @myRowCount = 0
            Set @Continue = 0
        Else
        Begin

            IF @NotifyUser = 'Yes'
            Begin
                IF NOT EXISTS ( SELECT *
                                FROM T_Notification_Entity_User
                                WHERE User_ID = @userID AND Entity_Type_ID = @entityTypeID )
                Begin
                    INSERT  INTO dbo.T_Notification_Entity_User
                            ( User_ID, Entity_Type_ID )
                    VALUES
                            ( @userID, @entityTypeID )
                End
            End

            If @NotifyUser = 'No'
            Begin
                DELETE FROM
                    T_Notification_Entity_User
                WHERE
                    User_ID = @userID
                    AND Entity_Type_ID = @entityTypeID
            End

        End
    End


Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'User ' + IsNull(@username, 'NULL')
    Exec post_usage_log_entry 'update_notification_user_registration', @UsageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_notification_user_registration] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_notification_user_registration] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_notification_user_registration] TO [Limited_Table_Write] AS [dbo]
GO

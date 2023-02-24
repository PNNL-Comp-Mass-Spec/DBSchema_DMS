/****** Object:  StoredProcedure [dbo].[UpdateNotificationUserRegistration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateNotificationUserRegistration]
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
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          06/11/2012 mem - Renamed @Dataset to @DatasetNotReleased
**                         - Added @DatasetReleased
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @PRN varchar(15),
    @Name varchar(64),
    @RequestedRunBatch varchar(4),      -- 'Yes' or 'No'
    @AnalysisJobRequest varchar(4),     -- 'Yes' or 'No'
    @SamplePrepRequest varchar(4),      -- 'Yes' or 'No'
    @DatasetNotReleased varchar(4),     -- 'Yes' or 'No'
    @DatasetReleased varchar(4),        -- 'Yes' or 'No'
    @mode varchar(12) = 'update',
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateNotificationUserRegistration', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Lookup user
    ---------------------------------------------------
    --
    DECLARE @userID INT = 0
    --
    SELECT @userID = ID
    FROM T_Users
    WHERE U_PRN = @PRN
    --
    IF @userID = 0
    BEGIN
        SET @message = 'User PRN "' + @PRN + '" is not valid'
        SET @myError = 15
        GOTO Done
    END

    ---------------------------------------------------
    -- Populate a temporary table with Entity Type IDs and Entity Type Params
    ---------------------------------------------------

    DECLARE @tblNotificationOptions AS table (
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
            BEGIN
            IF NOT EXISTS ( SELECT
                                *
                            FROM
                                T_Notification_Entity_User
                            WHERE
                                User_ID = @userID
                                AND Entity_Type_ID = @entityTypeID )
                BEGIN
                INSERT  INTO dbo.T_Notification_Entity_User
                        ( User_ID, Entity_Type_ID )
                VALUES
                        ( @userID, @entityTypeID )
                END
            END

            IF @NotifyUser = 'No'
            BEGIN
                DELETE FROM
                    T_Notification_Entity_User
                WHERE
                    User_ID = @userID
                    AND Entity_Type_ID = @entityTypeID
            END

        End
    End


Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'User ' + IsNull(@PRN, 'NULL')
    Exec PostUsageLogEntry 'UpdateNotificationUserRegistration', @UsageMessage


    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateNotificationUserRegistration] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateNotificationUserRegistration] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateNotificationUserRegistration] TO [Limited_Table_Write] AS [dbo]
GO

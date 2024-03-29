/****** Object:  StoredProcedure [dbo].[assign_eus_users_to_requested_run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[assign_eus_users_to_requested_run]
/****************************************************
**
**  Desc:
**    Associates the given list of EUS users with given requested run
**
**    No validation is performed.  Caller should call
**    validate_eus_usage before calling this procedure
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/21/2006
**          11/09/2006 grk - Added numeric test for eus user ID (Ticket #318)
**          07/11/2007 grk - factored out EUS proposal validation (Ticket #499)
**          11/16/2016 mem - Use parse_delimited_integer_list to parse @eusUsersList
**          03/24/2017 mem - Validate user IDs in @eusUsersList
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @request int,
    @eusProposalID varchar(10) = '',            -- Only used for logging
    @eusUsersList varchar(1024) = '',           -- Comma separated list of EUS user IDs (integers)
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Set @eusProposalID = IsNull(@eusProposalID, '')
    Set @eusUsersList = IsNull(@eusUsersList, '')

    ---------------------------------------------------
    -- clear all associations if the user list is blank
    ---------------------------------------------------

    if @eusUsersList = ''
    begin
        DELETE FROM T_Requested_Run_EUS_Users
        WHERE (Request_ID = @request)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            Set @message = 'Error trying to clear all user associations for this proposal'
            return 51081
        end

        return 0
    end

    ---------------------------------------------------
    -- Populate a temporary table with the user IDs in @eusUsersList
    ---------------------------------------------------
    --
    Declare @tmpUserIDs TABLE (ID int)

    INSERT INTO @tmpUserIDs (ID)
    SELECT Value
    FROM dbo.parse_delimited_integer_list(@eusUsersList, ',')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Look for unknown EUS users
    -- Upstream validation should have already identified these and prevented this procedure from getting called
    -- Post a log entry if unknown users are found
    ---------------------------------------------------

    Declare @UnknownUsers varchar(255) = ''

    SELECT @UnknownUsers = @UnknownUsers + Cast(ID as varchar(9)) + ','
    FROM @tmpUserIDs NewUsers LEFT OUTER JOIN T_EUS_Users U ON NewUsers.ID = U.PERSON_ID
    WHERE U.PERSON_ID IS Null
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    IF @myRowCount > 0
    Begin
        -- remove the trailing comma
        Set @UnknownUsers = Left(@UnknownUsers, Len(@UnknownUsers)-1)

        Declare @msg varchar(255)
        Declare @userText varchar(10) = dbo.check_plural(@myRowCount, 'user', 'users')
        Declare @logType varchar(24) = 'Error'

        Set @msg = 'Trying to associate ' + Cast(@myRowCount as varchar(9)) + ' unknown EUS ' + @userText +
                   ' with request ' + Cast(@request as varchar(9)) + '; ignoring unknown ' + @userText + ' ' + @UnknownUsers

        Declare @validateEUSData tinyint = 1

        SELECT @validateEUSData = Value
        FROM T_MiscOptions
        WHERE (Name = 'ValidateEUSData')
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @validateEUSData = 1

        If IsNull(@validateEUSData, 0) = 0
        Begin
            -- EUS validation is disabled; log this as a warning
            Set @logType = 'Warning'
        End

        exec post_log_entry @logType, @msg, assign_eus_users_to_requested_run

    End

    ---------------------------------------------------
    -- Add associations between request and users who are in list, but not in association table
    -- Skip unknown EUS users
    ---------------------------------------------------
    --
    INSERT INTO T_Requested_Run_EUS_Users( EUS_Person_ID,
                                           Request_ID )
    SELECT NewUsers.ID AS EUS_Person_ID,
           @request AS Request_ID
    FROM @tmpUserIDs NewUsers
         INNER JOIN T_EUS_Users U
           ON NewUsers.ID = U.PERSON_ID
    WHERE NewUsers.ID NOT IN ( SELECT EUS_Person_ID
                               FROM T_Requested_Run_EUS_Users
                               WHERE Request_ID = @request )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        Set @message = 'Error trying to add associations for new users'
        return 51083
    end

    ---------------------------------------------------
    -- Remove associations between request and users
    -- who are in association table but not in list
    ---------------------------------------------------
    --
    DELETE FROM T_Requested_Run_EUS_Users
    WHERE Request_ID = @request AND
          EUS_Person_ID NOT IN ( SELECT ID
                                 FROM @tmpUserIDs )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        Set @message = 'Error trying to remove existing associations for users that are not currently in the list'
        return 51084
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[assign_eus_users_to_requested_run] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[assign_eus_users_to_requested_run] TO [Limited_Table_Write] AS [dbo]
GO

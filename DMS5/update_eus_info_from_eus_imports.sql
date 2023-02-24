/****** Object:  StoredProcedure [dbo].[update_eus_info_from_eus_imports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_eus_info_from_eus_imports]
/****************************************************
**
**  Desc:
**      Wrapper procedure to call update_eus_proposals_from_eus_imports,
**      update_eus_users_from_eus_imports, and update_eus_instruments_from_eus_imports
**
**      Intended to be manually run on an on-demand basis
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/25/2011 mem - Initial version
**          09/02/2011 mem - Now calling post_usage_log_entry
**          01/08/2013 mem - Now calling update_eus_instruments_from_eus_imports
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/12/2021 mem - Add option to update EUS Users for Inactive proposals
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @updateUsersOnInactiveProposals tinyint = 0,
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @entryID int = 0
    Declare @statusMessage Varchar(512) = ''

    Set @updateUsersOnInactiveProposals = IsNull(@updateUsersOnInactiveProposals, 0)
    Set @message= ''

    -- Lookup the highest entry_ID in T_Log_Entries
    SELECT @entryID = MAX(entry_ID)
    FROM T_Log_Entries

    If @myError = 0
    Begin
        -- Update EUS proposals
        exec @myError = update_eus_proposals_from_eus_imports @message = @message

        If @myError <> 0 And @statusMessage = ''
        Begin
            If @message = ''
                Set @statusMessage = 'Error calling update_eus_proposals_from_eus_imports'
            Else
                Set @statusMessage = @message
        End
    End

    If @myError = 0
    Begin
        -- Update EUS users
        exec @myError = update_eus_users_from_eus_imports @updateUsersOnInactiveProposals, @message = @message

        If @myError <> 0 And @statusMessage = ''
        Begin
            If @message = ''
                Set @statusMessage = 'Error calling update_eus_users_from_eus_imports'
            Else
                Set @statusMessage = @message
        End
    End

    If @myError = 0
    Begin
        -- Update EUS instruments
        exec @myError = update_eus_instruments_from_eus_imports @message = @message

        If @myError <> 0 And @statusMessage = ''
        Begin
            If @message = ''
                Set @statusMessage = 'Error calling update_eus_instruments_from_eus_imports'
            Else
                Set @statusMessage = @message
        End
    End

    If @myError = 0
    Begin
        If @statusMessage = ''
            Set @statusMessage = 'Update complete'

        SELECT @statusMessage AS Message
    End
    Else
    Begin
        SELECT ISNULL(@message, '??') AS [Error Message]
    End

    -- Show any new entries to T_Log_Entrires
    If Exists (Select * from T_Log_Entries WHERE Entry_ID > @entryID AND posted_By Like 'UpdateEUS%')
    Begin
        SELECT *
        FROM T_Log_Entries
        WHERE Entry_ID > @entryID AND
              posted_By LIKE 'UpdateEUS%'
    End

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512) = ''
    Exec post_usage_log_entry 'update_eus_info_from_eus_imports', @usageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_eus_info_from_eus_imports] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_eus_info_from_eus_imports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_eus_info_from_eus_imports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_eus_info_from_eus_imports] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_eus_info_from_eus_imports] TO [PNL\D3M578] AS [dbo]
GO

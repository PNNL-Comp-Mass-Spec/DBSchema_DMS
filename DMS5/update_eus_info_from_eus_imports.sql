/****** Object:  StoredProcedure [dbo].[UpdateEUSInfoFromEUSImports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateEUSInfoFromEUSImports]
/****************************************************
**
**  Desc:
**      Wrapper procedure to call UpdateEUSProposalsFromEUSImports,
**      UpdateEUSUsersFromEUSImports, and UpdateEUSInstrumentsFromEUSImports
**
**      Intended to be manually run on an on-demand basis
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/25/2011 mem - Initial version
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          01/08/2013 mem - Now calling UpdateEUSInstrumentsFromEUSImports
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/12/2021 mem - Add option to update EUS Users for Inactive proposals
**
*****************************************************/
(
    @updateUsersOnInactiveProposals tinyint = 0,
    @message varchar(512) = '' output
)
As
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
        exec @myError = UpdateEUSProposalsFromEUSImports @message = @message

        If @myError <> 0 And @statusMessage = ''
        Begin
            If @message = ''
                Set @statusMessage = 'Error calling UpdateEUSProposalsFromEUSImports'
            Else
                Set @statusMessage = @message
        End
    End

    If @myError = 0
    Begin
        -- Update EUS users
        exec @myError = UpdateEUSUsersFromEUSImports @updateUsersOnInactiveProposals, @message = @message

        If @myError <> 0 And @statusMessage = ''
        Begin
            If @message = ''
                Set @statusMessage = 'Error calling UpdateEUSUsersFromEUSImports'
            Else
                Set @statusMessage = @message
        End
    End

    If @myError = 0
    Begin
        -- Update EUS instruments
        exec @myError = UpdateEUSInstrumentsFromEUSImports @message = @message

        If @myError <> 0 And @statusMessage = ''
        Begin
            If @message = ''
                Set @statusMessage = 'Error calling UpdateEUSInstrumentsFromEUSImports'
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
    Exec PostUsageLogEntry 'UpdateEUSInfoFromEUSImports', @usageMessage

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSInfoFromEUSImports] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEUSInfoFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSInfoFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSInfoFromEUSImports] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEUSInfoFromEUSImports] TO [PNL\D3M578] AS [dbo]
GO

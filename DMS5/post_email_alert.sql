/****** Object:  StoredProcedure [dbo].[post_email_alert] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[post_email_alert]
/****************************************************
**
**  Desc: Add a new elert to T_Email_Alerts
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/14/2018 mem - Initial version
**          08/26/2022 mem - Fix bug subtracting @duplicateEntryHoldoffHours from the current date/time
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @type varchar(32),                          -- Typically Normal, Warning, or Error, but can be any text value
    @message varchar(2048),
    @postedBy varchar(128) = 'na',
    @recipients varchar(512) = 'admins',        -- Either a semicolon separated list of e-mail addresses, or a keyword to use to query T_MiscPaths using 'Email_alert_' + @recipients
    @postMessageToLogEntries tinyint = 1,       -- When 1, also post this message to T_Log_Entries
    @duplicateEntryHoldoffHours int = 0         -- Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @duplicateRowCount int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @type = Rtrim(Ltrim(IsNull(@type, 'Error')))
    Set @message = Rtrim(Ltrim(IsNull(@message, '')))
    Set @postedBy = Rtrim(Ltrim(IsNull(@postedBy, 'Unknown')))
    Set @recipients = Rtrim(Ltrim(IsNull(@recipients, '')))
    Set @postMessageToLogEntries= IsNull(@postMessageToLogEntries, 1)
    Set @duplicateEntryHoldoffHours = IsNull(@duplicateEntryHoldoffHours, 0)

    If IsNull(@duplicateEntryHoldoffHours, 0) > 0
    Begin
        SELECT @duplicateRowCount = COUNT(*)
        FROM T_Email_Alerts
        WHERE Message = @message AND Alert_Type = @type AND Posting_Time >= DateAdd(hour, -@duplicateEntryHoldoffHours, GetDate())
    End

    If @duplicateRowCount > 0
    Begin
        Goto Done
    End

    SET ANSI_WARNINGS OFF;

    If @recipients <> '' And Not @recipients Like '%@%'
    Begin
        SELECT @recipients = [Server]
        FROM   T_MiscPaths
        WHERE ([Function] = 'Email_alert_' + @recipients)
    End

    If @recipients = ''
    Begin
        -- Use the default recipients
        SELECT @recipients = [Server]
        FROM   T_MiscPaths
        WHERE ([Function] = 'Email_alert_admins')

        If @recipients = ''
        Begin
            Set @recipients = 'proteomics@pnnl.gov'
        End
    End

    INSERT INTO T_Email_Alerts( Posted_by,
                                Posting_Time,
                                Alert_Type,
                                [Message],
                                Recipients )
    VALUES(@postedBy, GETDATE(), @type, @message, @recipients);
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount;

    SET ANSI_WARNINGS ON;
    --
    If @myError <> 0
    Begin
        Exec post_log_entry 'Error', 'Update was unsuccessful for T_Email_Alerts table', 'post_email_alert'
        RAISERROR ('Insert was unsuccessful for T_Email_Alerts table', 10, 1)
        return 51191
    end

    If @postMessageToLogEntries > 0
    Begin
        Exec post_log_entry @type, @message, @postedBy, @duplicateEntryHoldoffHours
    End

Done:
    return 0

GO
GRANT EXECUTE ON [dbo].[post_email_alert] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[post_email_alert] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[post_email_alert] TO [Limited_Table_Write] AS [dbo]
GO

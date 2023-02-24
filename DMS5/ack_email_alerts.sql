/****** Object:  StoredProcedure [dbo].[AckEmailAlerts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AckEmailAlerts]
/****************************************************
**
**  Desc:   Updates the state of alerts in T_Email_Alerts
**          The DMSEmailManager calls this procedure after e-mailing admins regarding alerts with state 1
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/16/2018 mem - Initial Version
**
*****************************************************/
(
    @alertIDs varchar(4000),
    @infoOnly tinyint = 0,
    @message varchar(255) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @alertCountToUpdate int = 0
    Declare @alertCountUpdated int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @alertIDs = IsNull(@alertIDs, '')
    Set @infoOnly = IsNull(@infoOnly, 1)

    Set @message = ''

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TABLE #TmpAlertIDs (
        AlertID int NOT NULL
    )

    INSERT INTO #TmpAlertIDs( AlertID )
    SELECT VALUE
    FROM dbo.udfParseDelimitedIntegerList ( @alertIDs, ',' )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    SELECT @alertCountToUpdate = Count(*)
    FROM #TmpAlertIDs

    If @alertCountToUpdate = 0
    Begin
        Set @message = 'No integers were found in ' + @alertIDs
        Goto Done
    End

    ---------------------------------------------------
    -- Update the alerts or preview changes
    ---------------------------------------------------

    If @infoOnly = 0
    Begin
        UPDATE T_Email_Alerts
        SET Alert_State = 2
        FROM T_Email_Alerts Alerts
             INNER JOIN #TmpAlertIDs
               ON Alerts.ID = #TmpAlertIDs.AlertID
        WHERE Alerts.Alert_State = 1
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @alertCountUpdated = @myRowCount

        Set @message = 'Acknowledged ' + Cast(@alertCountUpdated As varchar(12)) + ' ' +
                       dbo.CheckPlural(@alertCountUpdated, 'alert', 'alerts')  + ' in T_Email_Alerts'

        If @alertCountUpdated < @alertCountToUpdate
        Begin
            Set @message = @message + '; one or more alerts were skipped since already acknowledged'
        End

        Exec PostLogEntry 'Normal', @message, 'AckEmailAlerts'

    End
    Else
    Begin
        SELECT Alerts.*
        FROM V_Email_Alerts Alerts
             INNER JOIN #TmpAlertIDs
               ON Alerts.ID = #TmpAlertIDs.AlertID
        ORDER BY Alerts.ID
    End

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AckEmailAlerts] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AckEmailAlerts] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AckEmailAlerts] TO [DMS_SP_User] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[update_cached_wp_activation_states] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_wp_activation_states]
/****************************************************
**
**  Desc:
**      Update cached work package activation states in table T_Requested_Run
**
**  Arguments:
**    @workPackage      Work package to update; if an empty string, update all requested runs
**    @showDebug        When true, show debug info
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/17/2024 mem - Initial version
**
*****************************************************/
(
    @workPackage varchar(32) = '',        -- Work package to update; if an empty string, update all requested runs
    @message varchar(512) = '' output,
    @showDebug tinyint = 0
)
AS
    Set nocount on

    Declare @rowCountUpdated int = 0
    Declare @myError int = 0

    Declare @requestedRunCount int

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @workPackage = LTrim(RTrim(IsNull(@workPackage, '')))
    Set @message = ''
    Set @showDebug = IsNull(@showDebug, 0)

    If @workPackage = ''
    Begin
        ------------------------------------------------
        -- Update cached WP activation states for all requested runs
        ------------------------------------------------

        If @showDebug > 0
        Begin
            SELECT @requestedRunCount = COUNT(ID)
            FROM T_Requested_Run

            Print 'Updating cached work package activation states for all ' + Cast(@requestedRunCount As varchar(12)) + ' requested runs'
        End

        UPDATE T_Requested_Run
        SET Cached_WP_Activation_State = CC.Activation_State
        FROM T_Requested_Run RR
             LEFT OUTER JOIN T_Charge_Code CC
               ON RR.RDS_WorkPackage = CC.Charge_Code
        WHERE Cached_WP_Activation_State <> Coalesce(CC.Activation_State, 0)
        --
        SELECT @myError = @@error, @rowCountUpdated = @@rowcount
    End
    Else
    Begin
        ------------------------------------------------
        -- Update cached WP activation states for one work package
        ------------------------------------------------

        If @showDebug > 0
        Begin
            If Not Exists (SELECT Charge_Code FROM T_Charge_Code WHERE Charge_Code = @workPackage)
            Begin
                Print 'Warning: Work package ' + @workPackage + ' does not exist'
            End
            Else
            Begin
                SELECT @requestedRunCount = COUNT(ID)
                FROM T_Requested_Run

                Print 'Updating cached work package activation states for requested runs with work package ' + @workPackage
            End
        End

        UPDATE T_Requested_Run
        SET Cached_WP_Activation_State = CC.Activation_State
        FROM T_Charge_Code CC
        WHERE T_Requested_Run.RDS_WorkPackage = @workPackage AND
              T_Requested_Run.RDS_WorkPackage = CC.Charge_Code AND
              T_Requested_Run.cached_wp_activation_state <> CC.Activation_State;
        --
        SELECT @myError = @@error, @rowCountUpdated = @@rowcount
    End

    If @rowCountUpdated > 0
    Begin
        Set @message = 'Updated ' + Convert(varchar(12), @rowCountUpdated) + dbo.check_plural(@rowCountUpdated, ' row', ' rows') + ' in T_Requested_Run'

        If @showDebug > 0
        Begin
            Print @message
        End
    End

    Return @myError

GO

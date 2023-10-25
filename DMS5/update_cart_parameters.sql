/****** Object:  StoredProcedure [dbo].[update_cart_parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cart_parameters]
/****************************************************
**
**  Desc:
**      Changes cart parameters for given requested run
**      This procedure is used by add_update_dataset
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**    @mode         Type of update begin performed (note that 'CartConfigID' mode only updates the database if @newValue corresponds to a row in T_LC_Cart_Configuration)
**    @requestID    ID of requested run being updated
**    @newValue     New value to store
**    @message      Blank if update was successful, error description of error if not
**
**  Auth:   grk
**  Date:   12/16/2003
**          02/27/2006 grk - Added cart ID stuff
**          05/10/2006 grk - Added verification of request ID
**          09/02/2011 mem - Now calling post_usage_log_entry
**          04/02/2013 mem - Now using @message to return errors looking up cart name from T_LC_Cart
**          01/09/2017 mem - Update @message when using RAISERROR
**          01/10/2023 mem - Include previous @message text when updating @message
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          10/24/2023 mem - Add mode 'CartConfigID'
**                         - Change @newValue to a normal input parameter since none of the modes uses it as an output parameter
**
*****************************************************/
(
    @mode varchar(32), -- 'CartName', 'CartConfigID', 'RunStart', 'RunFinish', 'RunStatus', 'InternalStandard'
    @requestID int,
    @newValue varchar(512),
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @dt datetime

    Set @mode = Coalesce(@mode, 'InvalidMode')
    Set @requestID = Coalesce(@requestID, 0)

    ---------------------------------------------------
    -- Verify that request ID is correct
    ---------------------------------------------------
    Declare @tmp int = 0

    SELECT @tmp = ID
    FROM T_Requested_Run
    WHERE ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @msg = 'Error trying to verify requested run ID'
        Set @message = @msg
        RAISERROR (@msg, 10, 1)
        Return @myError
    End

    If @tmp = 0
    Begin
        Set @msg = 'Requested run ID not found: ' + CAST(@requestID as varchar(12))
        Set @message = @msg
        RAISERROR (@msg, 10, 1)
        Return 52131
    End

    If @mode = 'CartName'
    Begin
        ---------------------------------------------------
        -- Resolve ID for LC Cart and update requested run table
        ---------------------------------------------------

        Declare @cartID int = 0
        --
        SELECT @cartID = ID
        FROM T_LC_Cart
        WHERE Cart_Name = @newValue
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error trying to look up cart ID using "' + @newValue + '"'
        End
        Else If @cartID = 0
        Begin
            Set @message = 'Invalid LC Cart name: ' + @newValue
            Set @myError = 52117
        End
        Else
        Begin
            -- Note: Only update the value if the Cart ID has changed
            --
            UPDATE T_Requested_Run
            SET RDS_Cart_ID = @cartID
            WHERE ID = @requestID AND Coalesce(RDS_Cart_ID, 0) <> @cartID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError = 0 And @myRowCount < 1
            Begin
                Set @myRowCount = 1
            End

            If @myError <> 0
            Begin
                Set @message = 'Update query reported error code ' + Cast(@myError As Varchar(12))
            End
        End
    End

    If @mode = 'CartConfigID'
    Begin
        ---------------------------------------------------
        -- Resolve ID for Cart Config ID and update requested run table
        ---------------------------------------------------

        Declare @cartConfigID int = TRY_CAST(@newValue AS int)

        If @cartConfigID Is Null
        Begin
            Set @message = 'Cannot update T_Requested_Run since cart config ID is not an integer: ' + Coalesce(@newValue, '??')
            Set @myError = 52118
        End
        Else If Not Exists (SELECT Cart_Config_ID FROM T_LC_Cart_Configuration WHERE Cart_Config_ID = @cartConfigID)
        Begin
            Set @message = 'Invalid Cart Config ID: ' + @newValue
            Set @myError = 52119
        End
        Else
        Begin
            UPDATE T_Requested_Run
            SET RDS_Cart_Config_ID = @cartConfigID
            WHERE ID = @requestID AND Coalesce(RDS_Cart_Config_ID, 0) <> @cartConfigID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError = 0 And @myRowCount < 1
            Begin
                Set @myRowCount = 1
            End
        End
    End

    If @mode = 'RunStatus'
    Begin
        UPDATE T_Requested_Run
        SET    RDS_note = @newValue
        WHERE ID = @requestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    If @mode = 'RunStart'
    Begin
        If @newValue = ''
            Set @dt = getdate()
        Else
            Set @dt = cast(@newValue as datetime)

        UPDATE T_Requested_Run
        SET RDS_Run_Start = @dt
        WHERE ID = @requestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    If @mode = 'RunFinish'
    Begin
        If @newValue = ''
            Set @dt = getdate()
        Else
            Set @dt = cast(@newValue as datetime)

        UPDATE T_Requested_Run
        SET     RDS_Run_Finish = @dt
        WHERE ID = @requestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    If @mode = 'InternalStandard'
    Begin
        UPDATE T_Requested_Run
        SET RDS_Internal_Standard = @newValue
        WHERE ID = @requestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512) = 'Request ' + Convert(varchar(12), @requestID)

    Exec post_usage_log_entry 'update_cart_parameters', @UsageMessage

    ---------------------------------------------------
    -- Report any errors
    ---------------------------------------------------

    If @myError <> 0 or @myRowCount = 0
    Begin
        Set @message = 'operation failed for mode ' + @mode + ' (' + Coalesce(@message, '??') + ')'
        RAISERROR ('operation failed: "%s"', 10, 1, @mode)
        Return 51310
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_cart_parameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cart_parameters] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_cart_parameters] TO [Limited_Table_Write] AS [dbo]
GO

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
**    @mode      - type of update begin performed
**    @requestID - ID of scheduled run being updated
**    @newValue  - new vale that is being set, or value retured
**                 depending on mode
**    @message   - blank if update was successful,
**                 description of error if not
**
**  Auth:   grk
**  Date:   12/16/2003
**          02/27/2006 grk - added cart ID stuff
**          05/10/2006 grk - added verification of request ID
**          09/02/2011 mem - Now calling post_usage_log_entry
**          04/02/2013 mem - Now using @message to return errors looking up cart name from T_LC_Cart
**          01/09/2017 mem - Update @message when using RAISERROR
**          01/10/2023 mem - Include previous @message text when updating @message
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @mode varchar(32), -- 'CartName', 'RunStart', 'RunFinish', 'RunStatus', 'InternalStandard'
    @requestID int,
    @newValue varchar(512) output,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @msg varchar(256)
    Declare @dt datetime

    Set @mode = Coalesce(@mode, 'InvalidMode')
    Set @requestID = Coalesce(@requestID, 0)

    ---------------------------------------------------
    -- verify that request ID is correct
    ---------------------------------------------------
    Declare @tmp int = 0
    --
    SELECT @tmp = ID
    FROM T_Requested_Run
    WHERE (ID = @requestID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Error trying verify request ID'
        Set @message = @msg
        RAISERROR (@msg, 10, 1)
        return @myError
    End

    if @tmp = 0
    begin
        set @msg = 'Request ID not found'
        Set @message = @msg
        RAISERROR (@msg, 10, 1)
        return 52131
    end

    if @mode = 'CartName'
    begin
        ---------------------------------------------------
        -- Resolve ID for LC Cart and update requested run table
        ---------------------------------------------------

        declare @cartID int
        set @cartID = 0
        --
        SELECT @cartID = ID
        FROM T_LC_Cart
        WHERE (Cart_Name = @newValue)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to look up cart ID using "' + @newValue + '"'
        end
        else
        if @cartID = 0
        begin
            set @myError = 52117
            set @message = 'Invalid LC Cart name "' + @newValue + '"'
        end
        else
        begin
            -- Note: Only update the value if RDS_Cart_ID has changed
            --
            UPDATE T_Requested_Run
            SET    RDS_Cart_ID = @cartID
            WHERE (ID = @requestID AND RDS_Cart_ID <> @cartID)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError = 0 And @myRowCount < 1
                Set @myRowCount = 1

            If @myError <> 0
            Begin
                Set @message = 'Update query reported error code ' + Cast(@myError As Varchar(12))
            End
        end
    end

    if @mode = 'RunStatus'
    begin
        UPDATE T_Requested_Run
        SET    RDS_note = @newValue
        WHERE (ID = @requestID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    end

    if @mode = 'RunStart'
    begin
        if @newValue = ''
            set @dt = getdate()
        else
            set @dt = cast(@newValue as datetime)

        UPDATE T_Requested_Run
        SET    RDS_Run_Start = @dt
        WHERE (ID = @requestID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    end

    if @mode = 'RunFinish'
    begin
        if @newValue = ''
            set @dt = getdate()
        else
            set @dt = cast(@newValue as datetime)

        UPDATE T_Requested_Run
        SET     RDS_Run_Finish = @dt
        WHERE (ID = @requestID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    end

    if @mode = 'InternalStandard'
    begin
        UPDATE T_Requested_Run
        SET    RDS_Internal_Standard = @newValue
        WHERE (ID = @requestID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    end


    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'Request ' + Convert(varchar(12), @requestID)
    Exec post_usage_log_entry 'update_cart_parameters', @UsageMessage

    ---------------------------------------------------
    -- report any errors
    ---------------------------------------------------
    if @myError <> 0 or @myRowCount = 0
    begin
        Set @message = 'operation failed for mode ' + @mode + ' (' + Coalesce(@message, '??') + ')'
        RAISERROR ('operation failed: "%s"', 10, 1, @mode)
        return 51310
    end

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_cart_parameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cart_parameters] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_cart_parameters] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[update_requested_run_blocking_and_factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_blocking_and_factors]
/****************************************************
**
**  Desc:
**      Update requested run factors and blocking from input XML lists
**      Called from https://dms2.pnl.gov/requested_run_batch_blocking/param
**
**      Example contents of @blockingList:
**      <r i="545496" t="Run_Order" v="2" /><r i="545496" t="Block" v="2" />
**      <r i="545497" t="Run_Order" v="1" /><r i="545497" t="Block" v="1" />
**
**      Example contents of @factorList:
**      <id type="Request" /><r i="545496" f="TempFactor" v="a" /><r i="545497" f="TempFactor" v="b" />
**
**      @blockingList can be empty if @factorList is defined
**      Conversely, @factorList may be simply '<id type="Request" />' if updating run order and blocking
**
**    Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/21/2010
**          09/02/2011 mem - Now calling post_usage_log_entry
**          11/07/2016 mem - Add optional logging via post_log_entry
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/04/2019 mem - Tabs to spaces
**          12/13/2022 mem - Log stored procedure usage even if update_requested_run_batch_parameters returns a non-zero return code
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @blockingList text,
    @factorList text,
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
AS
    SET NOCOUNT ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @xml AS xml
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_requested_run_blocking_and_factors', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Declare @debugEnabled tinyint = 0

    If @debugEnabled > 0
    Begin
        Declare @logMessage varchar(4096)

        Set @logMessage = Cast(@blockingList as varchar(4000))
        If IsNull(@logMessage, '') = ''
            Set @logMessage = '@blockingList is empty'
        Else
            Set @logMessage = '@blockingList: ' + @logMessage

        exec post_log_entry 'Debug', @logMessage, 'update_requested_run_blocking_and_factors'

        Set @logMessage = Cast(@factorList as varchar(4000))
        If IsNull(@logMessage, '') = ''
            Set @logMessage = '@factorList is empty'
        Else
            Set @logMessage = '@factorList: ' + @logMessage

        exec post_log_entry 'Debug', @logMessage, 'update_requested_run_blocking_and_factors'
    End

    -----------------------------------------------------------
    -- Update the blocking and run order
    -----------------------------------------------------------
    --
    IF DATALENGTH(@blockingList) > 0
    BEGIN
        EXEC @myError = update_requested_run_batch_parameters
                            @blockingList,
                            'update',
                            @message OUTPUT,
                            @callingUser
    END

    If @myError = 0
    Begin
        -----------------------------------------------------------
        -- Update the factors
        -----------------------------------------------------------
        --

        EXEC @myError = update_requested_run_factors
                                @factorList,
                                @message OUTPUT,
                                @callingUser
    End

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512) = ''
    Set @UsageMessage = ''
    Exec post_usage_log_entry 'update_requested_run_blocking_and_factors', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_blocking_and_factors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_blocking_and_factors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_blocking_and_factors] TO [Limited_Table_Write] AS [dbo]
GO

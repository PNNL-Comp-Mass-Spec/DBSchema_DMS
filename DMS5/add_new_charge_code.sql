/****** Object:  StoredProcedure [dbo].[add_new_charge_code] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_charge_code]
/****************************************************
**
**  Desc:
**      Adds a charge code (work package) to T_Charge_Code
**
**      Useful when a work package is not auto-adding to the table
**      (charge codes are auto-added if the owner is a DMS user or DMS guest)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          08/13/2015 mem - Initial Version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/17/2024 mem - Trim leading and trailing whitespace from @chargeCodeList
**
*****************************************************/
(
    @chargeCodeList varchar(2000),          -- Comma-separated list of work packages
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @ChargeCodeList = LTrim(RTrim(IsNull(@ChargeCodeList, '')))
    Set @message = ''

    If @ChargeCodeList = ''
    Begin
        Set @message = '@ChargeCodeList is empty; nothing to do'
        Print @message
    End
    Else
    Begin
        Exec @myError = update_charge_codes_from_warehouse @infoOnly=@infoOnly, @updateAll=0, @ExplicitChargeCodeList=@ChargeCodeList, @message=@message output

        If @message <> ''
            Print @message
    End

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_charge_code] TO [DDL_Viewer] AS [dbo]
GO

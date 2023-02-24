/****** Object:  StoredProcedure [dbo].[AddNewChargeCode] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddNewChargeCode]
/****************************************************
**
**  Desc:
**      Adds a charge code (work package) to T_Charge_Code
**      Useful when a work package is not auto-adding to the table
**      (charge codes are auto-added if the owner is a DMS user or DMS guest)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          08/13/2015 mem - Initial Version
**
*****************************************************/
(
    @ChargeCodeList varchar(2000),
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @ChargeCodeList = IsNull(@ChargeCodeList, '')
    Set @message = ''

    If @ChargeCodeList = ''
    Begin
        set @message = '@ChargeCodeList is empty; nothing to do'
        print @message
    End
    Else
    Begin
        exec UpdateChargeCodesFromWarehouse @infoOnly=@infoOnly, @updateAll=0, @ExplicitChargeCodeList=@ChargeCodeList, @message=@message output

        if @message <> ''
            Print @message
    End

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddNewChargeCode] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[validate_wp] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_wp]
/****************************************************
**
**  Desc:   Verifies that given work package exists in T_Charge_Code
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial Version
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          11/27/2023 mem - Return a value between 50030 and 50035 when validation fails
**
*****************************************************/
(
    @workPackage varchar(64),
    @allowNoneWP tinyint,                    -- Set to 1 to allow @WorkPackage to be "none"
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0

    Set @WorkPackage = IsNull(@WorkPackage, '')
    Set @allowNoneWP = IsNull(@allowNoneWP, 0)
    Set @message = ''

    If IsNull(@WorkPackage, '') = ''
    Begin
        set @message = 'Work package cannot be blank'
        Set @myError = 50030
    End

    If @myError = 0 And @allowNoneWP > 0 And @WorkPackage = 'none'
    Begin
        -- Allow the work package to be 'none'
        Set @myError = 0
    End
    Else
    Begin

        If @myError = 0 And @WorkPackage IN ('none', 'na', 'n/a', '(none)')
        Begin
            set @message = 'A valid work package must be provided; see https://dms2.pnl.gov/helper_charge_code/report'
            Set @myError = 50031
        End

        If @myError = 0 And Not Exists (SELECT * FROM T_Charge_Code Where Charge_Code = @WorkPackage)
        Begin
            set @message = 'Could not find entry in database for Work Package "' + @WorkPackage + '"; see https://dms2.pnl.gov/helper_charge_code/report'
            Set @myError = 50032
        End
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[validate_wp] TO [DDL_Viewer] AS [dbo]
GO

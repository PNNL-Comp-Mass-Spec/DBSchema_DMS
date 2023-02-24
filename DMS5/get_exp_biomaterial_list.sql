/****** Object:  UserDefinedFunction [dbo].[GetExpCellCultureList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetExpCellCultureList]
/****************************************************
**
**  Desc:
**  Builds delimited list of cell cultures for given experiment
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/04/2005
**          11/29/2017 mem - Expand the return value to varchar(2048) and use Coalesce
**
*****************************************************/
(
    @experimentNum varchar(50)
)
RETURNS varchar(2048)
AS
BEGIN
    Declare @list varchar(2048) = null

    SELECT @list = Coalesce(@list + '; ' + CC.CC_Name, CC.CC_Name)
    FROM T_Experiment_Cell_Cultures ECC
            INNER JOIN T_Experiments E
            ON ECC.Exp_ID = E.Exp_ID
            INNER JOIN T_Cell_Culture CC
            ON ECC.CC_ID = CC.CC_ID
    WHERE E.Experiment_Num = @experimentNum

    If @list Is Null
        Set @list = ''

    RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetExpCellCultureList] TO [DDL_Viewer] AS [dbo]
GO

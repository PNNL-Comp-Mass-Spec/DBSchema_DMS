/****** Object:  UserDefinedFunction [dbo].[GetAuxInfoAllowedValues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetAuxInfoAllowedValues]
/****************************************************
**
**  Desc:
**      Builds delimited list of allowed values for given aux info item
**
**  Return value: vertical bar delimited list
**
**  Auth:   grk
**  Date:   08/24/2010
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new aux info table and column names
**
*****************************************************/
(
    @ID int
)
RETURNS varchar(1024)
AS
BEGIN
    Declare @list varchar(1024) = ''

    SELECT
            @list = @list + CASE
                            WHEN @list = '' THEN Value
                            ELSE ' | ' + Value
                        END
        FROM T_Aux_Info_Allowed_Values
        WHERE Aux_Description_ID = @ID

    RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetAuxInfoAllowedValues] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetAuxInfoAllowedValues] TO [DMS2_SP_User] AS [dbo]
GO

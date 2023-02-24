/****** Object:  UserDefinedFunction [dbo].[get_user_operations_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_user_operations_list]
/****************************************************
**
**  Desc: Builds delimited list of Operations for
**            given DMS User
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   jds
**  Date:   12/13/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @userID int
)
RETURNS varchar(8000)
AS
    BEGIN
    declare @list varchar(8000)
    set @list = ''

    SELECT
        @list = @list + CASE
        WHEN @list = '' THEN U.Operation
        ELSE ', ' + U.Operation END
    FROM
        T_User_Operations_Permissions O
        JOIN T_User_Operations U on O.Op_ID = U.ID
    WHERE   O.U_ID = @userID
    ORDER BY U.Operation

    return @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_user_operations_list] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  UserDefinedFunction [dbo].[get_permissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_permissions]
/****************************************************
**
**  Desc:
**  Builds delimited list of users/roles
**  that have granted access to object
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/15/2005
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @name varchar(128)
)
RETURNS varchar(1024)
AS
    BEGIN
        declare @list varchar(1024)
        set @list = ''

        SELECT
            @list = @list + CASE
                                WHEN @list = '' THEN USER_NAME(sysprotects.uid)
                                ELSE ', ' + USER_NAME(sysprotects.uid)
                            END
        FROM
            sysprotects
        WHERE
            sysprotects.id = OBJECT_ID(@name)

        --if @list = '' set @list = '(unknown)'

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_permissions] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_permissions] TO [public] AS [dbo]
GO

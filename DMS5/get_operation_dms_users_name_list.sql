/****** Object:  UserDefinedFunction [dbo].[get_operation_dms_users_name_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_operation_dms_users_name_list]
/****************************************************
**
**  Desc: Builds delimited list of DMS users for the given Operation
**
**  Return value: delimited list
**
**  Auth:   jds
**  Date:   12/11/2006 jds - Initial version
**          06/28/2010 ??? - Now limiting to active users
**          12/08/2014 mem - Now using Name_with_PRN to obtain each user's name and username
**          11/17/2016 mem - Add parameter @formatAsTable
**                         - Also change parameter @operationID to an integer
**          08/24/2018 mem - Tabs to spaces
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @operationID int,
    @formatAsTable tinyint = 0      -- When 0, separate usernames with semicolons.  When 1, include a vertical bar between each user and use a colon between the user's name and network login
)
RETURNS varchar(8000)
AS
BEGIN

    Set @formatAsTable = IsNull(@formatAsTable, 0)

    Declare @list varchar(8000) = ''

    If @formatAsTable = 1
    Begin
        SELECT @list = @List + U.U_Name + ':' + U.U_PRN + '|'
        FROM T_User_Operations_Permissions O
             INNER JOIN T_Users U
               ON O.U_ID = U.ID
        WHERE O.Op_ID = @operationID AND
              (U.U_Status = 'Active')
        ORDER BY U.U_Name

    End
    Else
    Begin
        SELECT @list = @list + U.Name_with_PRN + '; '
        FROM T_User_Operations_Permissions O
             INNER JOIN T_Users U
               ON O.U_ID = U.ID
        WHERE O.Op_ID = @operationID AND
              (U.U_Status = 'Active')
        ORDER BY U.U_Name

    End

    -- Trim the trailing vertical bar or semicolon
    If @list <> ''
        Set @list = Substring(@list, 1, Len(@list)-1)

    Return @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_operation_dms_users_name_list] TO [DDL_Viewer] AS [dbo]
GO

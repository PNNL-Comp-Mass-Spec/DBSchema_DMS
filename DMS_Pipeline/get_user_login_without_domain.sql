/****** Object:  UserDefinedFunction [dbo].[get_user_login_without_domain] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_user_login_without_domain]
/****************************************************
**
**  Desc:
**  Return the network login (username) of the calling user
**
**  Return value: username
**
**  Parameters:
**
**  Auth:   mem
**  Date:   11/08/2016 mem - Initial Version
**          11/10/2016 mem - Add parameter @callingUser, which is used in place of DMSWebUser
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @callingUser varchar(128) = ''
)
RETURNS varchar(128)
AS
BEGIN

    Declare @login varchar(128) = SUSER_SNAME()
    Declare @slashLoc int

    -- Username is likely in the form PNL\D3M123 or PNL\pers1234
    -- Only return the portion after the last backslash

    If @login LIKE '%\%'
    Begin
        Set @slashLoc = CharIndex('\', Reverse(@login))
        Set @login = Substring(@login, Len(@login) - @slashloc + 2, 100)
    END

    If @login = 'DMSWebUser' And IsNull(@callingUser, '') <> ''
    Begin
        Set @login = @callingUser
        If @login LIKE '%\%'
        Begin
            Set @slashLoc = CharIndex('\', Reverse(@login))
            Set @login = Substring(@login, Len(@login) - @slashloc + 2, 100)
        End
    End

    RETURN @login
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_user_login_without_domain] TO [DDL_Viewer] AS [dbo]
GO

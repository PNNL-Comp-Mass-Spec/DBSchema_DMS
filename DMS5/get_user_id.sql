/****** Object:  UserDefinedFunction [dbo].[get_user_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_user_id]
/****************************************************
**
**  Desc: Gets UserID for given username
**
**  Return values: 0: failure, otherwise, user ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add set nocount on
**          10/22/2020 mem - Add support for names of the form 'LastName, FirstName (Username)'
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @username varchar(80) = ''
)
RETURNS int
AS
BEGIN
    Declare @userID int = 0
    Declare @startLoc INT

    If @username LIKE '%(%)'
    Begin
        Set @startLoc = CharIndex('(', @username)
        If @startLoc > 0
        Begin
            Set @username = Substring(@username, @startLoc + 1, LEN(@username) - @startLoc - 1)
        End
    End

    SELECT @userID = ID
    FROM T_Users
    WHERE U_PRN = @username

    return @userID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_user_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_user_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_user_id] TO [Limited_Table_Write] AS [dbo]
GO

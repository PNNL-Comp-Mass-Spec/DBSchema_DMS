/****** Object:  StoredProcedure [dbo].[GetUserID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetUserID]
/****************************************************
**
**  Desc: Gets UserID for given user PRN
**
**  Return values: 0: failure, otherwise, user ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add set nocount on
**          10/22/2020 mem - Add support for names of the form 'LastName, FirstName (Username)'
**
*****************************************************/
(
    @userPRN varchar(80) = ''
)
AS
    set nocount on

    Declare @userID int = 0
    Declare @startLoc INT

    If @userPRN LIKE '%(%)'
    Begin
        Set @startLoc = CharIndex('(', @userPRN)
        If @startLoc > 0
        Begin
            Set @userPRN = Substring(@userPRN, @startLoc + 1, LEN(@userPRN) - @startLoc - 1)
        End
    End

    SELECT @userID = ID
    FROM T_Users
    WHERE U_PRN = @userPRN

    return @userID

GO
GRANT VIEW DEFINITION ON [dbo].[GetUserID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetUserID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetUserID] TO [Limited_Table_Write] AS [dbo]
GO

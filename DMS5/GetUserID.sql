/****** Object:  StoredProcedure [dbo].[GetUserID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetUserID
/****************************************************
**
**	Desc: Gets UserID for given user PRN
**
**	Return values: 0: failure, otherwise, user ID
**
**	Auth:	grk
**	Date:	01/26/2001
**			08/03/2017 mem - Add set nocount on
**    
*****************************************************/
(
	@userPRN varchar(80) = " "
)
As
	set nocount on
	
	Declare @userID int = 0
	
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

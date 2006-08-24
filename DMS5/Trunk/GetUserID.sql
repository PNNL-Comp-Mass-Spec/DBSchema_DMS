/****** Object:  StoredProcedure [dbo].[GetUserID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








Create Procedure GetUserID
/****************************************************
**
**	Desc: Gets UserID for given user PRN
**
**	Return values: 0: failure, otherwise, user ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
	@userPRN varchar(80) = " "
)
As
	declare @userID int
	set @userID = 0
	SELECT @userID = ID FROM T_Users WHERE (U_PRN = @userPRN)
	return(@userID)
GO
GRANT EXECUTE ON [dbo].[GetUserID] TO [DMS_SP_User]
GO

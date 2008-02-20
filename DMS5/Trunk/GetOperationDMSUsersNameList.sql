/****** Object:  UserDefinedFunction [dbo].[GetOperationDMSUsersNameList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION dbo.GetOperationDMSUsersNameList
/****************************************************
**
**	Desc: Builds delimited list of DMS users for
**            given Operation
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: jds
**		Date: 12/11/2006
**    
*****************************************************/
(
@operationID varchar(10)
)
RETURNS varchar(8000)
AS

	BEGIN
	declare @list varchar(8000)
	set @list = ''

	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN U.U_Name + ' (' + CAST(U.U_PRN AS Varchar(12)) + ')' 
		ELSE '; ' + U.U_Name + ' (' + CAST(U.U_PRN AS Varchar(12)) + ')' END
	FROM
		T_User_Operations_Permissions O 
		JOIN T_Users U on O.U_ID = U.ID
	WHERE   O.Op_ID = @operationID
	ORDER BY U.U_Name

	return @list
	END


GO

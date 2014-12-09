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
**	Auth:	jds
**	Date:	12/11/2006 jds - Initial version
**			06/28/2010 ??? - Now limiting to active users
**			12/08/2014 mem - Now using Name_with_PRN to obtain each user's name and PRN
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

	SELECT @list = @list + CASE WHEN @list = '' THEN U.Name_with_PRN
	                            ELSE '; ' + U.Name_with_PRN
	                       END
	FROM T_User_Operations_Permissions O
	     INNER JOIN T_Users U
	       ON O.U_ID = U.ID
	WHERE O.Op_ID = @operationID AND
	      (U.U_Status = 'Active')
	ORDER BY U.U_Name

	return @list
	END



GO

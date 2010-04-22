/****** Object:  UserDefinedFunction [dbo].[GetPermissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION GetPermissions
/****************************************************
**
**	Desc: 
**  Builds delimited list of users/roles
**  that have granted access to object
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 2/15/2005
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
GRANT EXECUTE ON [dbo].[GetPermissions] TO [public] AS [dbo]
GO

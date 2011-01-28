/****** Object:  StoredProcedure [dbo].[CheckAccessPermission] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE CheckAccessPermission
/****************************************************
**
**	Desc: 
**  Does current user have permission to execute 
**  given stored procedure
**
**	Return values: 0: no, >0: yes
**
**	Parameters:
**
**		Auth: grk
**		Date: 02/08/2005
**    
*****************************************************/
@sprocName varchar(128)
AS
	SET NOCOUNT ON
	declare @result int
	set @result = 0
	
	select @result = (PERMISSIONS(OBJECT_ID(@sprocName)) & 0x20) 

	RETURN @result

GO
GRANT VIEW DEFINITION ON [dbo].[CheckAccessPermission] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CheckAccessPermission] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CheckAccessPermission] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[CheckAccessPermission] TO [public] AS [dbo]
GO

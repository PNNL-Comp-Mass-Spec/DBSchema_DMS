/****** Object:  StoredProcedure [dbo].[GetQRollDatabases] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  Procedure GetQRollDatabases
/****************************************************
**
**	Desc: Gets list of databases from passed server name
**
**	Return values: 0: failure, otherwise, list of databases
**
**	Parameters: 
**
**		Auth: jds
**		Date: 3/1/2005
**    
*****************************************************/
(
	@serverName varchar(50) = " "
)
As
	declare @result int
	declare @tmpQry as Nvarchar(1000)
	set @tmpQry = 'select [Name] from DBASE.Master.dbo.sysdatabases order by name'
	set @tmpQry = replace(@tmpQry, 'DBASE', @serverName)

	exec @result = sp_executesql @tmpQry

GO
GRANT VIEW DEFINITION ON [dbo].[GetQRollDatabases] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetQRollDatabases] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetQRollDatabases] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetQRollDatabases] TO [Limited_Table_Write] AS [dbo]
GO

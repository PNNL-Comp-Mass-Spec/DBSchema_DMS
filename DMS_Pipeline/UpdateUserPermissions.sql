/****** Object:  StoredProcedure [dbo].[UpdateUserPermissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.UpdateUserPermissions
/****************************************************
**
**	Desc: Updates user permissions in the current DB
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	07/31/2012 mem - Initial Version
**			08/13/2012 mem - Added update permission for T_Scripts_History
**			03/16/2016 mem - Add users gigasax\msdadmin and gigasax\ftms
**						   - Allow the DMS_SP_User role to update the Entered_By column in T_Job_Events
**    
*****************************************************/
AS
	Set NoCount On
	

	if exists (select * from sys.schemas where name = 'DMSReader')
		drop schema DMSReader
	if exists (select * from sys.sysusers where name = 'DMSReader')
		drop user DMSReader
	create user DMSReader for login DMSReader
	ALTER Role db_datareader add Member [DMSReader]
			
		
	if exists (select * from sys.schemas where name = 'DMSWebUser')
		drop schema DMSWebUser
	if exists (select * from sys.sysusers where name = 'DMSWebUser')
		drop user DMSWebUser
	create user DMSWebUser for login DMSWebUser	
	ALTER Role db_datareader add Member [DMSWebUser]
	ALTER Role DMS_SP_User add Member [DMSWebUser]


	if exists (select * from sys.sysusers where name = 'GIGASAX\msdadmin')
		drop user [GIGASAX\msdadmin]
		
	CREATE USER [GIGASAX\msdadmin] WITH DEFAULT_SCHEMA=[dbo]

	ALTER role db_datareader add Member [GIGASAX\msdadmin]
	ALTER role DMS_Analysis_Job_Runner add Member [GIGASAX\msdadmin]
	
	
	if exists (select * from sys.sysusers where name = 'GIGASAX\ftms')
		drop user [GIGASAX\ftms]
		
	CREATE USER [GIGASAX\ftms] WITH DEFAULT_SCHEMA=[dbo]

	ALTER role db_datareader add Member [GIGASAX\ftms]
	ALTER role DMS_Analysis_Job_Runner add Member [GIGASAX\ftms]
	ALTER role DMS_SP_User add Member [GIGASAX\ftms]


	grant showplan to DMSReader
	grant showplan to DMSWebUser


	GRANT UPDATE ON [dbo].[T_Scripts_History] ([Entered_By]) TO [DMS_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_Job_Events] ([Entered_By]) TO [DMS_SP_User] AS [dbo]

	Return 0



GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUserPermissions] TO [DDL_Viewer] AS [dbo]
GO

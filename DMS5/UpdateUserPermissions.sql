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
**	Date:	07/31/2012 mem - Initial Version (ported from MTS)
**			08/13/2012 mem - Added update permission for role DMS2_SP_User for several tables
**			03/16/2016 mem - Add users gigasax\msdadmin and gigasax\ftms
**						   - Grante update on T_File_Attachment to DMSWebUser
**    
*****************************************************/
AS
	Set NoCount On
	

	if exists (select * from sys.schemas where name = 'DMSReader')
		drop schema DMSReader
	if exists (select * from sys.sysusers where name = 'DMSReader')
		drop user DMSReader
	create user DMSReader for login DMSReader
	
	ALTER Role db_datareader              Add Member [DMSReader]
	ALTER Role MTS_SP_User                Add Member [DMSReader]
		
		
	if exists (select * from sys.schemas where name = 'DMSWebUser')
		drop schema DMSWebUser
	if exists (select * from sys.sysusers where name = 'DMSWebUser')
		drop user DMSWebUser
	create user DMSWebUser for login DMSWebUser
	
	ALTER Role db_datareader              Add Member [DMSWebUser]
	ALTER Role DMS_Limited_Organism_Write Add Member [DMSWebUser]
	ALTER Role DMS2_SP_User               Add Member [DMSWebUser]
	ALTER Role MTS_SP_User                Add Member [DMSWebUser]


	if exists (select * from sys.schemas where name = 'NWFS_Samba_User')
		drop schema NWFS_Samba_User
	if exists (select * from sys.sysusers where name = 'NWFS_Samba_User')
		drop user NWFS_Samba_User
	create user NWFS_Samba_User for login NWFS_Samba_User

	ALTER Role db_datareader              Add Member [NWFS_Samba_User]


	if exists (select * from sys.schemas where name = 'LCMSNetUser')
		drop schema LCMSNetUser
	if exists (select * from sys.sysusers where name = 'LCMSNetUser')
		drop user LCMSNetUser
	create user LCMSNetUser for login LCMSNetUser

	ALTER Role db_datareader              Add Member [LCMSNetUser]
	ALTER Role DMS_LCMSNet_User           Add Member [LCMSNetUser]


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

	GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Group] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Group_Associations] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Group_Membership] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Tools] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_Analysis_Job_Processors] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_File_Attachment] to [DMSWebUser]
	GRANT UPDATE ON [dbo].[T_Organisms_Change_History] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_Param_Entries] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
	GRANT UPDATE ON [dbo].[T_Sample_Prep_Request_Updates] ([System_Account]) TO [DMS2_SP_User] AS [dbo]

	-- Call UpdateUserPermissionsViewDefinitions to grant view definition for each Stored Procedure and grant showplan
	exec UpdateUserPermissionsViewDefinitions @UserList='PNL\D3M578, PNL\D3M580'

	Return 0


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUserPermissions] TO [DDL_Viewer] AS [dbo]
GO

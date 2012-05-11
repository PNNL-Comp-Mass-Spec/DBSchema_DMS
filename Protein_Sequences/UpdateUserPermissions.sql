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
**	Date:	12/13/2004
**			01/27/2005 mem - Added MTS_DB_Dev and MTS_DB_Lite
**			07/15/2006 mem - Updated to use Sql Server 2005 syntax if possible
**			08/10/2006 mem - Added MTS_DB_Reader
**			11/20/2006 mem - Added DMS Logins
**    
*****************************************************/
AS
	Set NoCount On
	
	---------------------------------------------------
	-- Determine whether or not we're running Sql Server 2005 or newer
	---------------------------------------------------
	Declare @VersionMajor int
	Declare @UseSystemViews tinyint
	Declare @S nvarchar(256)
	
	exec MT_Main.dbo.GetServerVersionInfo @VersionMajor output

	If @VersionMajor >= 9
		set @UseSystemViews = 1
	else
		set @UseSystemViews = 0

	If @UseSystemViews = 0
	Begin
		exec sp_revokedbaccess 'MTUser'
		exec sp_grantdbaccess 'MTUser'

		exec sp_revokedbaccess 'MTAdmin'
		exec sp_grantdbaccess 'MTAdmin'

		exec sp_revokedbaccess 'MTS_DB_Dev'
		set @S = @@ServerName + '\MTS_DB_DEV'
		exec sp_grantdbaccess @S, 'MTS_DB_DEV'

		exec sp_revokedbaccess 'MTS_DB_Lite'
		set @S = @@ServerName + '\MTS_DB_Lite'
		exec sp_grantdbaccess @S, 'MTS_DB_Lite'

		exec sp_revokedbaccess 'MTS_DB_Reader'
		set @S = @@ServerName + '\MTS_DB_Reader'
		exec sp_grantdbaccess @S, 'MTS_DB_Reader'


		exec sp_revokedbaccess 'DMSReader'
		exec sp_grantdbaccess 'DMSReader'

		exec sp_revokedbaccess 'DMSWebUser'
		exec sp_grantdbaccess 'DMSWebUser'

		exec sp_revokedbaccess 'PRISMSeqReader'
		exec sp_grantdbaccess 'PRISMSeqReader'

		exec sp_revokedbaccess 'EMSL-Prism.Users.DMS_User'
		set @S = 'pnl\EMSL-Prism.Users.DMS_User'
		exec sp_grantdbaccess @S, 'EMSL-Prism.Users.DMS_User'

		exec sp_revokedbaccess 'emsl-prism.Users.DMS_Guest'
		set @S = 'pnl\emsl-prism.Users.DMS_Guest'
		exec sp_grantdbaccess @S, 'emsl-prism.Users.DMS_Guest'

		exec sp_revokedbaccess 'emsl-prism.Users.DMS_JobRunner'
		set @S = 'pnl\emsl-prism.Users.DMS_JobRunner'
		exec sp_grantdbaccess @S, 'emsl-prism.Users.DMS_JobRunner'

		exec sp_revokedbaccess 'RBAC-Web_Analysis'
		exec sp_revokedbaccess 'emsl-prism.Users.Web_Analysis'
		set @S = 'pnl\emsl-prism.Users.Web_Analysis'
		exec sp_grantdbaccess @S, 'emsl-prism.Users.Web_Analysis'

		set @S = 'ProteinSeqs\ProteinSeqs_Upload_Users'
		exec sp_grantdbaccess @S, 'ProteinSeqs_Upload_Users'
	End
	Else
	Begin
		SELECT 'Uncomment this section when running on SQL Server 2005'
		
		if exists (select * from sys.schemas where name = 'MTUser')
			drop schema MTUser
		if exists (select * from sys.sysusers where name = 'MTUser')
			drop user MTUser
		create user MTUser for login MTUser
		exec sp_addrolemember 'db_datareader', 'MTUser'
		exec sp_addrolemember 'DMS_SP_User', 'MTUser'
		exec sp_addrolemember 'DMS_Analysis', 'MTUser'
		exec sp_addrolemember 'DMS_User', 'MTUser'
		exec sp_addrolemember 'MTS_SP_User', 'MTUser'
			
		if exists (select * from sys.schemas where name = 'MTAdmin')
			drop schema MTAdmin
		if exists (select * from sys.sysusers where name = 'MTAdmin')
			drop user MTAdmin
		create user MTAdmin for login MTAdmin
		exec sp_addrolemember 'db_datareader', 'MTAdmin'
		exec sp_addrolemember 'db_datawriter', 'MTAdmin'
		exec sp_addrolemember 'DMS_SP_User', 'MTAdmin'

		if exists (select * from sys.schemas where name = 'MTS_DB_Dev')
			drop schema MTS_DB_Dev
		if exists (select * from sys.sysusers where name = 'MTS_DB_Dev')
			drop user MTS_DB_Dev
			
		set @S = 'create user MTS_DB_Dev for login [' + @@ServerName + '\MTS_DB_Dev]'
		exec sp_executesql @S
		
		exec sp_addrolemember 'db_owner', 'MTS_DB_DEV'
		exec sp_addrolemember 'db_ddladmin', 'MTS_DB_DEV'
		exec sp_addrolemember 'db_backupoperator', 'MTS_DB_DEV'
		exec sp_addrolemember 'db_datareader', 'MTS_DB_DEV'
		exec sp_addrolemember 'db_datawriter', 'MTS_DB_DEV'
		exec sp_addrolemember 'DMS_SP_User', 'MTS_DB_DEV'

		if exists (select * from sys.schemas where name = 'MTS_DB_Lite')
			drop schema MTS_DB_Lite
		if exists (select * from sys.sysusers where name = 'MTS_DB_Lite')
			drop user MTS_DB_Lite


		set @S = 'create user MTS_DB_Lite for login [' + @@ServerName + '\MTS_DB_Lite]'
		exec sp_executesql @S
		exec sp_addrolemember 'db_datareader', 'MTS_DB_Lite'
		exec sp_addrolemember 'db_datawriter', 'MTS_DB_Lite'
		exec sp_addrolemember 'DMS_SP_User', 'MTS_DB_Lite'


		if exists (select * from sys.schemas where name = 'MTS_DB_Reader')
			drop schema MTS_DB_Reader
		if exists (select * from sys.sysusers where name = 'MTS_DB_Reader')
			drop user MTS_DB_Reader
			
		set @S = 'create user MTS_DB_Reader for login [' + @@ServerName + '\MTS_DB_Reader]'
		exec sp_executesql @S
		
		exec sp_addrolemember 'db_datareader', 'MTS_DB_Reader'
		exec sp_addrolemember 'DMS_SP_User', 'MTS_DB_Reader'


		if exists (select * from sys.schemas where name = 'DMSReader')
			drop schema DMSReader
		if exists (select * from sys.sysusers where name = 'DMSReader')
			drop user DMSReader
		create user DMSReader for login DMSReader
		exec sp_addrolemember 'db_datareader', 'DMSReader'
		exec sp_addrolemember 'MTS_SP_User', 'DMSReader'


		if exists (select * from sys.schemas where name = 'DMSWebUser')
			drop schema DMSWebUser
		if exists (select * from sys.sysusers where name = 'DMSWebUser')
			drop user DMSWebUser
		create user DMSWebUser for login DMSWebUser
		exec sp_addrolemember 'db_datareader', 'DMSWebUser'
		exec sp_addrolemember 'MTS_SP_User', 'DMSWebUser'


		if exists (select * from sys.schemas where name = 'PRISMSeqReader')
			drop schema PRISMSeqReader
		if exists (select * from sys.sysusers where name = 'PRISMSeqReader')
			drop user PRISMSeqReader
		create user PRISMSeqReader for login PRISMSeqReader
		exec sp_addrolemember 'db_datareader', 'PRISMSeqReader'
		exec sp_addrolemember 'MTS_SP_User', 'PRISMSeqReader'


		if exists (select * from sys.schemas where name = 'EMSL-Prism.Users.DMS_User')
			drop schema [EMSL-Prism.Users.DMS_User]
		if exists (select * from sys.sysusers where name = 'EMSL-Prism.Users.DMS_User')
			drop user [EMSL-Prism.Users.DMS_User]
			
		set @S = 'create user [EMSL-Prism.Users.DMS_User] for login [pnl\EMSL-Prism.Users.DMS_User]'
		exec sp_executesql @S
		
		exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_User'
		exec sp_addrolemember 'DMS_User', 'EMSL-Prism.Users.DMS_User'
		exec sp_addrolemember 'MTS_SP_User', 'EMSL-Prism.Users.DMS_User'


		if exists (select * from sys.schemas where name = 'EMSL-Prism.Users.DMS_Guest')
			drop schema [EMSL-Prism.Users.DMS_Guest]
		if exists (select * from sys.sysusers where name = 'EMSL-Prism.Users.DMS_Guest')
			drop user [EMSL-Prism.Users.DMS_Guest]
			
		set @S = 'create user [EMSL-Prism.Users.DMS_Guest] for login [pnl\EMSL-Prism.Users.DMS_Guest]'
		exec sp_executesql @S
		
		exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_Guest'


		if exists (select * from sys.schemas where name = 'EMSL-Prism.Users.DMS_JobRunner')
			drop schema [EMSL-Prism.Users.DMS_JobRunner]
		if exists (select * from sys.sysusers where name = 'EMSL-Prism.Users.DMS_JobRunner')
			drop user [EMSL-Prism.Users.DMS_JobRunner]
			
		set @S = 'create user [EMSL-Prism.Users.DMS_JobRunner] for login [pnl\EMSL-Prism.Users.DMS_JobRunner]'
		exec sp_executesql @S
		
		exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_JobRunner'
		exec sp_addrolemember 'DMS_User', 'EMSL-Prism.Users.DMS_JobRunner'
		exec sp_addrolemember 'MTS_SP_User', 'EMSL-Prism.Users.DMS_JobRunner'


		if exists (select * from sys.schemas where name = 'RBAC-Web_Analysis')
			drop schema [RBAC-Web_Analysis]
		if exists (select * from sys.sysusers where name = 'RBAC-Web_Analysis')
			drop user [RBAC-Web_Analysis]
		if exists (select * from sys.schemas where name = 'emsl-prism.Users.Web_Analysis')
			drop schema [emsl-prism.Users.Web_Analysis]
		if exists (select * from sys.sysusers where name = 'emsl-prism.Users.Web_Analysis')
			drop user [emsl-prism.Users.Web_Analysis]
						
		set @S = 'create user [emsl-prism.Users.Web_Analysis] for login [pnl\emsl-prism.Users.Web_Analysis]'
		exec sp_executesql @S
		
		exec sp_addrolemember 'db_datareader', 'emsl-prism.Users.Web_Analysis'
		exec sp_addrolemember 'DMS_Analysis', 'emsl-prism.Users.Web_Analysis'
		exec sp_addrolemember 'MTS_SP_User', 'emsl-prism.Users.Web_Analysis'

	End

	exec sp_addrolemember 'db_datareader', 'MTUser'
	exec sp_addrolemember 'DMS_SP_User', 'MTUser'

	exec sp_addrolemember 'db_datareader', 'MTAdmin'
	exec sp_addrolemember 'db_datawriter', 'MTAdmin'
	exec sp_addrolemember 'DMS_SP_User', 'MTAdmin'
	
	exec sp_addrolemember 'db_owner', 'MTS_DB_DEV'
	exec sp_addrolemember 'db_ddladmin', 'MTS_DB_DEV'
	exec sp_addrolemember 'db_backupoperator', 'MTS_DB_DEV'
	exec sp_addrolemember 'db_datareader', 'MTS_DB_DEV'
	exec sp_addrolemember 'db_datawriter', 'MTS_DB_DEV'
	exec sp_addrolemember 'DMS_SP_User', 'MTS_DB_DEV'

	exec sp_addrolemember 'db_datareader', 'MTS_DB_Lite'
	exec sp_addrolemember 'db_datawriter', 'MTS_DB_Lite'
	exec sp_addrolemember 'DMS_SP_User', 'MTS_DB_Lite'

	exec sp_addrolemember 'db_datareader', 'MTS_DB_Reader'
	exec sp_addrolemember 'DMS_SP_User', 'MTS_DB_Reader'

	exec sp_addrolemember 'db_datareader', 'DMSReader'
	exec sp_addrolemember 'MTS_SP_User', 'DMSReader'

	exec sp_addrolemember 'db_datareader', 'DMSWebUser'
	exec sp_addrolemember 'MTS_SP_User', 'DMSWebUser'

	exec sp_addrolemember 'db_datareader', 'PRISMSeqReader'
	exec sp_addrolemember 'MTS_SP_User', 'PRISMSeqReader'

	exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_User'
	exec sp_addrolemember 'DMS_User', 'EMSL-Prism.Users.DMS_User'
	exec sp_addrolemember 'MTS_SP_User', 'EMSL-Prism.Users.DMS_User'

	exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_Guest'

	exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_JobRunner'
	exec sp_addrolemember 'DMS_User', 'EMSL-Prism.Users.DMS_JobRunner'
	exec sp_addrolemember 'MTS_SP_User', 'EMSL-Prism.Users.DMS_JobRunner'

	exec sp_addrolemember 'db_datareader', 'emsl-prism.Users.Web_Analysis'
	exec sp_addrolemember 'DMS_Analysis', 'emsl-prism.Users.Web_Analysis'
	exec sp_addrolemember 'MTS_SP_User', 'emsl-prism.Users.Web_Analysis'

	exec sp_addrolemember 'db_datareader', 'ProteinSeqs\ProteinSeqs_Upload_Users'
	exec sp_addrolemember 'DMS_Analysis', 'ProteinSeqs\ProteinSeqs_Upload_Users'
	exec sp_addrolemember 'MTS_SP_User', 'ProteinSeqs\ProteinSeqs_Upload_Users'



	Return 0

GO
GRANT EXECUTE ON [dbo].[UpdateUserPermissions] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO

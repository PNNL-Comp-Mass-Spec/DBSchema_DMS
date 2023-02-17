/****** Object:  StoredProcedure [dbo].[UpdateUserPermissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateUserPermissions]
/****************************************************
**
**  Desc: Updates user permissions in the current DB
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   07/31/2012 mem - Initial Version
**          08/08/2012 mem - Added permissions for DMSWebUser
**
*****************************************************/
AS
    Set NoCount On


    if exists (select * from sys.schemas where name = 'DMSReader')
        drop schema DMSReader
    if exists (select * from sys.sysusers where name = 'DMSReader')
        drop user DMSReader
    create user DMSReader for login DMSReader
    exec sp_addrolemember 'db_datareader', 'DMSReader'


    if exists (select * from sys.schemas where name = 'DMSWebUser')
        drop schema DMSWebUser
    if exists (select * from sys.sysusers where name = 'DMSWebUser')
        drop user DMSWebUser
    create user DMSWebUser for login DMSWebUser
    exec sp_addrolemember 'db_datareader', 'DMSWebUser'
    exec sp_addrolemember 'DMS_SP_User', 'DMSWebUser'
    exec sp_addrolemember 'Mgr_Config_Admin', 'DMSWebUser'


    if exists (select * from sys.schemas where name = 'MTUser')
        drop schema MTUser
    if exists (select * from sys.sysusers where name = 'MTUser')
        drop user MTUser
    create user MTUser for login MTUser
    exec sp_addrolemember 'db_datareader', 'MTUser'
    exec sp_addrolemember 'DMS_SP_User', 'MTUser'

    grant showplan to DMSReader
    grant showplan to DMSWebUser
    grant showplan to MTUser


    GRANT EXECUTE ON [dbo].[AckManagerUpdateRequired] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddManagers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateManager] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateManagerParamDefaults] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateManagerParams] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateManagerState] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateManagerType] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateMgrTypeControlParams] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateParamByManagerType] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[AddUpdateParamType] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[CheckAccessPermission] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[CheckForParamChanged]  TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[DisableAnalysisManagers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[DisableArchiveDependentManagers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[DisableSequestClusters] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[EnableArchiveDependentManagers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[EnableDisableAllManagers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[EnableDisableManagers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[LocalErrorHandler] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[NextField] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[ParseManagerNameList] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[PostLogEntry] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[ReportManagerErrorCleanup]  TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[SelectManagerControlParams] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[SetManagerErrorCleanupMode] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[SetManagerParams] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[SetManagerUpdateRequired] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[SetParamForManagerList] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[UpdateManagerControlParams] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[UpdateSingleMgrControlParam] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[UpdateSingleMgrTypeControlParam] TO [Mgr_Config_Admin] AS [dbo]

    GRANT INSERT ON [dbo].[V_MgrState] TO [DMSWebUser]
    GRANT SELECT ON [dbo].[V_MgrState] TO [DMSWebUser]
    GRANT UPDATE ON [dbo].[V_MgrState] TO [DMSWebUser]
    GRANT UPDATE ON [dbo].[T_ParamValue] ([Entered_By]) TO [DMSWebUser] AS [dbo]
    GRANT UPDATE ON [dbo].[T_ParamValue] ([Last_Affected]) TO [DMSWebUser] AS [dbo]

    Return 0


GO

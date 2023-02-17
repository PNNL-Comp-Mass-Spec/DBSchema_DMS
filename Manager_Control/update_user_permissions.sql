/****** Object:  StoredProcedure [dbo].[update_user_permissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_user_permissions]
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
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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


    GRANT EXECUTE ON [dbo].[ack_manager_update_required] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_managers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_manager] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_manager_param_defaults] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_manager_params] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_managerState] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_manager_type] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_mgr_type_control_params] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_param_by_manager_type] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_param_type] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[check_access_permission] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[check_for_param_changed]  TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[disable_analysis_managers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[disable_archive_dependent_managers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[disable_sequest_clusters] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[enable_archive_dependent_managers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[enable_disable_all_managers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[enable_disable_managers] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[local_error_handler] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[next_field] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[parse_manager_name_list] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[post_log_entry] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[report_manager_error_cleanup]  TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[SelectManagerControlParams] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[set_manager_error_cleanup_mode] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[set_manager_params] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[set_manager_update_required] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[set_param_for_manager_list] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_manager_control_params] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_single_mgr_control_param] TO [Mgr_Config_Admin] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_single_mgr_type_control_param] TO [Mgr_Config_Admin] AS [dbo]

    GRANT INSERT ON [dbo].[V_MgrState] TO [DMSWebUser]
    GRANT SELECT ON [dbo].[V_MgrState] TO [DMSWebUser]
    GRANT UPDATE ON [dbo].[V_MgrState] TO [DMSWebUser]
    GRANT UPDATE ON [dbo].[T_ParamValue] ([Entered_By]) TO [DMSWebUser] AS [dbo]
    GRANT UPDATE ON [dbo].[T_ParamValue] ([Last_Affected]) TO [DMSWebUser] AS [dbo]

    Return 0

GO

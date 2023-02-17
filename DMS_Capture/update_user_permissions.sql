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
**          11/01/2012 mem - Now updating enable_disable_archive_step_tools
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
    -- exec sp_addrolemember 'db_datawriter', 'DMSWebUser'
    exec sp_addrolemember 'DMS_SP_User', 'DMSWebUser'

    grant execute on enable_disable_archive_step_tools to DMSReader

    grant showplan to DMSReader
    grant showplan to DMSWebUser

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_user_permissions] TO [DDL_Viewer] AS [dbo]
GO

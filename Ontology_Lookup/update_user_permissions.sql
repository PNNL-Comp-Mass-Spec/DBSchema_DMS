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
**  Date:   03/15/2016 mem - Initial Version for Ontology_Lookup
**
*****************************************************/
AS
    Set NoCount On

    IF Not exists (SELECT * FROM sys.database_principals where name = 'DMS_SP_User')
        CREATE ROLE [DMS_SP_User]

    IF exists (select * from sys.schemas where name = 'DMSReader')
        drop schema DMSReader
    IF exists (select * from sys.sysusers where name = 'DMSReader')
        drop user DMSReader
    create user DMSReader for login DMSReader
    ALTER ROLE db_datareader ADD Member DMSReader

    IF exists (select * from sys.schemas where name = 'DMSWebUser')
        drop schema DMSWebUser
    IF exists (select * from sys.sysusers where name = 'DMSWebUser')
        drop user DMSWebUser
    create user DMSWebUser for login DMSWebUser
    ALTER ROLE db_datareader ADD Member DMSWebUser
    ALTER ROLE DMS_SP_User   ADD Member DMSWebUser

    grant showplan to DMSReader
    grant showplan to DMSWebUser

    GRANT EXECUTE ON [dbo].[GetTaxIDTaxonomyList] TO DMSReader
    GRANT SELECT ON [dbo].[GetTaxIDTaxonomyTable] TO DMSReader

    GRANT EXECUTE ON [dbo].[GetTaxIDTaxonomyList] TO DMS_SP_User
    GRANT SELECT ON [dbo].[GetTaxIDTaxonomyTable] TO DMS_SP_User

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUserPermissions] TO [DDL_Viewer] AS [dbo]
GO

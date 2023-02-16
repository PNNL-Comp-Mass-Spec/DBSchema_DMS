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
**          08/22/2012 mem - Now updating T_Log_Entries
**          03/16/2016 mem - Add Select and Update permissions for DMSWebUser on S_File_Attachment
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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


    if exists (select * from sys.schemas where name = 'DMSWebUser')
        drop schema DMSWebUser
    if exists (select * from sys.sysusers where name = 'DMSWebUser')
        drop user DMSWebUser
    create user DMSWebUser for login DMSWebUser

    ALTER Role db_datareader              Add Member [DMSWebUser]
    ALTER Role DMS_SP_User                Add Member [DMSWebUser]


    GRANT SELECT ON [dbo].[S_File_Attachment] to [DMSWebUser]
    GRANT UPDATE ON [dbo].[S_File_Attachment] to [DMSWebUser]
    GRANT UPDATE ON [dbo].[T_Log_Entries] ([Entered_By]) TO [DMS_SP_User] AS [dbo]

    grant showplan to DMSReader
    grant showplan to DMSWebUser

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_user_permissions] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[VerifySPAuthorized] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[VerifySPAuthorized]
/****************************************************
**
**  Desc:
**      Verifies that a user can execute the given stored procedure from the given remote host
**      Authorization is controlled via table T_SP_Authorization
**      The HostName column is either a specific host name, or * for any host
**
**  Returns:
**      1 if authorized, or 0 if not authorized
**
**      If authorized, @message is empty; otherwise it will be of the form:
**      'User PNL\Username cannot execute procedure ProcedureName from host HostName
**
**  Auth:   mem
**  Date:   06/16/2017 mem - Initial version
**          01/05/2018 mem - Include username and hostname in RAISERROR message
**
*****************************************************/
(
    @procedureName nvarchar(128),
    @raiseError tinyint = 0,
    @infoOnly tinyint = 0,
    @message varchar(255) = '' output
)
AS
    Set nocount on

    ---------------------------------------------------
    -- Validate inputs
    ---------------------------------------------------

    Set @procedureName = IsNull(@procedureName, '')
    Set @raiseError = IsNull(@raiseError, 0)
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Determine host name and login name
    ---------------------------------------------------

    DECLARE @clientHostName nvarchar(128)
    DECLARE @loginName nvarchar(128)

    SELECT @clientHostName = sess.host_name,
           @loginName = sess.login_name
    FROM sys.dm_exec_sessions sess
    WHERE sess.session_ID = @@SPID

    Declare @authorized tinyint = 0

    If Exists (
        SELECT *
        FROM T_SP_Authorization
        WHERE ProcedureName = @procedureName AND
              LoginName = @loginName AND
              (HostName = @clientHostName Or HostName = '*'))
    Begin
        Set @authorized = 1

        If @infoOnly > 0
        Begin
            SELECT 'Yes' AS Authorized, @procedureName AS StoredProcedure, @loginName AS LoginName, @clientHostName AS HostName
        End
    End
    Else
    Begin
        If Exists (
            SELECT *
            FROM T_SP_Authorization
            WHERE ProcedureName = '*' AND
                LoginName = @loginName AND
                (HostName = @clientHostName Or HostName = '*'))
        Begin
            Set @authorized = 1

            If @infoOnly > 0
            Begin
                SELECT 'Yes ' AS Authorized, @procedureName + ' (Global)' AS StoredProcedure, @loginName AS LoginName, @clientHostName AS HostName
            End
        End
    End

    If @authorized = 0
    Begin
        If @infoOnly > 0
        Begin
            SELECT 'No' AS Authorized, @procedureName AS StoredProcedure, @loginName AS LoginName, @clientHostName AS HostName
        End
        Else
        Begin
            If @raiseError > 0
            Begin
                Set @message = 'User ' + @loginName + ' cannot execute procedure ' + @procedureName + ' from host ' + @clientHostName
                Exec PostLogEntry 'Error', @message, 'VerifySPAuthorized'

                Declare @msg varchar(128) = 'Access denied for current user (' + @loginName + ' on host ' + @clientHostName + ')'
                RAISERROR (@msg, 11, 4)
            End
        End
    End

    -----------------------------------------------
    -- Exit
    -----------------------------------------------

    return @authorized

GO

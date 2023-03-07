/****** Object:  StoredProcedure [dbo].[set_update_required_for_running_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_update_required_for_running_managers]
/****************************************************
**
**  Desc:
**      Sets ManagerUpdateRequired to True in the Manager Control database
**      for currently running managers
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          04/17/2014 mem - Initial release
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/06/2023 bcg - Use a synonym to access the Manager_Control database
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'request_step_task_xml', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Get a list of the currently running managers
    ---------------------------------------------------
    --
    Declare @mgrList varchar(max)

    SELECT @mgrList = Coalesce(@mgrList + ',', '') + Processor
    FROM T_Job_Steps
    WHERE (State = 4)
    ORDER BY Processor
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    Declare @mgrCount int = @myRowCount

    If @infoOnly <> 0
    Begin
        Select @mgrList as ManagersNeedingUpdate
    End
    Else
    Begin
        Print 'Calling set_manager_update_required for ' + Convert(varchar(12), @mgrCount) + ' managers'
        Exec @myError = s_mc_set_manager_update_required @mgrList, @showTable=1
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_update_required_for_running_managers] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_update_required_for_running_managers] TO [DMS_SP_User] AS [dbo]
GO

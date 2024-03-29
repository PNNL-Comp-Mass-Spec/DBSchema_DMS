/****** Object:  StoredProcedure [dbo].[set_update_required_for_running_capture_task_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_update_required_for_running_capture_task_managers]
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
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/06/2023 bcg - Use a synonym to access the Manager_Control database
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    ---------------------------------------------------
    -- Get a list of the currently running managers
    ---------------------------------------------------
    --
    Declare @mgrList varchar(max)

    SELECT @mgrList = Coalesce(@mgrList + ',', '') + Processor
    FROM T_Task_Steps
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
GRANT VIEW DEFINITION ON [dbo].[set_update_required_for_running_capture_task_managers] TO [DDL_Viewer] AS [dbo]
GO

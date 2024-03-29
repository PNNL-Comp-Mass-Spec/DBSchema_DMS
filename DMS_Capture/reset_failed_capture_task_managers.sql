/****** Object:  StoredProcedure [dbo].[reset_failed_capture_task_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reset_failed_capture_task_managers]
/****************************************************
**
**  Desc:
**      Resets managers that report "flag file" in V_Processor_Status_Warnings_CTM
**
**  Auth:   mem
**          10/20/2016 mem - Ported from DMS_Pipeline
**          01/16/2023 mem - Use new view name
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/06/2023 bcg - Use a synonym to access the Manager_Control database
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @infoOnly tinyint = 0,                              -- 1 to preview the changes
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    -- Temp table for managers
    CREATE TABLE #Tmp_ManagersToReset (
        Processor_Name varchar(128) NOT NULL,
        Status_Date datetime
    )

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    Set @InfoOnly = IsNull(@InfoOnly, 0)
    Set @message = ''

    -----------------------------------------------------------
    -- Find managers reporting error "Flag file" within the last 6 hours
    -----------------------------------------------------------
    --

    INSERT INTO #Tmp_ManagersToReset (Processor_Name, Status_Date)
    SELECT Processor_Name,
           Status_Date
    FROM V_Processor_Status_Warnings_CTM
    WHERE (Most_Recent_Log_Message Like '%Flag file%') AND
          (Status_Date > DATEADD(hour, -6, GETDATE()))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    If Not Exists (SELECT * FROM #Tmp_ManagersToReset)
    Begin
        SELECT 'No failed managers were found' AS Message
    End
    Else
    Begin

        -----------------------------------------------------------
        -- Construct a comma-separated list of manager names
        -----------------------------------------------------------
        --
        Declare @ManagerList varchar(max) = null

        SELECT @ManagerList = Coalesce(@ManagerList + ',' + Processor_Name, Processor_Name)
        FROM #Tmp_ManagersToReset
        ORDER BY Processor_Name

        -----------------------------------------------------------
        -- Call the manager control database procedure
        -----------------------------------------------------------
        --
        exec @myError = s_mc_set_manager_error_cleanup_mode @ManagerList, @CleanupMode=1, @showTable=1, @infoOnly=@InfoOnly

    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[reset_failed_capture_task_managers] TO [DDL_Viewer] AS [dbo]
GO

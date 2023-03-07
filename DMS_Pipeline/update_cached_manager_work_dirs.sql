/****** Object:  StoredProcedure [dbo].[update_cached_manager_work_dirs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_manager_work_dirs]
/****************************************************
**
**  Desc:
**      Update the cached working directory for each manager
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/05/2016 mem - Initial release
**          02/17/2020 mem - Update the Mgr_Name column in S_Manager_Control_V_MgrWorkDir
**          01/30/2023 mem - Use new synonym name with renamed columns
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/06/2023 bcg - Rename the synonym used to access Manager_Control.V_Mgr_Work_Dir
**
*****************************************************/
(
    @infoOnly tinyint = 0
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int
    declare @myRowCount int

    set @myError = 0
    set @myRowCount = 0

    Set @infoOnly = IsNull(@infoOnly, 0)

    Declare @message varchar(512)

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    ---------------------------------------------------
    -- Create a temporary table to cache the data
    ---------------------------------------------------

    CREATE TABLE #Tmp_MgrWorkDirs (
        ID             int NOT NULL,
        Processor_Name varchar(128) NOT NULL,
        MgrWorkDir     varchar(255) NULL
    )

    CREATE CLUSTERED INDEX IX_Tmp_MgrWorkDirs ON #Tmp_MgrWorkDirs (ID)

    Begin Try

        ---------------------------------------------------
        -- Populate a temporary table with the new information
        -- Data in s_mc_v_mgr_work_dir will be of the form
        -- \\ServerName\C$\DMS_WorkDir1
        ---------------------------------------------------
        --
        INSERT INTO #Tmp_MgrWorkDirs (ID, Processor_Name, MgrWorkDir)
        SELECT ID,
               Processor_Name,
               Replace(MgrWorkDirs.Work_Dir_Admin_Share, '\\ServerName\', '\\' + Machine + '\') AS MgrWorkDir
        FROM s_mc_v_mgr_work_dir MgrWorkDirs
             INNER JOIN T_Local_Processors LP
               ON MgrWorkDirs.Mgr_Name = LP.Processor_Name
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly <> 0
        Begin
            SELECT Target.*, Src.MgrWorkDir AS MgrWorkDir_New
            FROM #Tmp_MgrWorkDirs Src
                 INNER JOIN T_Local_Processors Target
                   ON Src.Processor_Name = Target.Processor_Name
            WHERE Target.WorkDir_AdminShare <> Src.MgrWorkDir OR
                  Target.WorkDir_AdminShare IS NULL AND NOT Src.MgrWorkDir IS NULL

        End
        Else
        Begin
            UPDATE T_Local_Processors
            SET WorkDir_AdminShare = Src.MgrWorkDir
            FROM #Tmp_MgrWorkDirs Src
                 INNER JOIN T_Local_Processors Target
                   ON Src.Processor_Name = Target.Processor_Name
            WHERE Target.WorkDir_AdminShare <> Src.MgrWorkDir OR
                  Target.WorkDir_AdminShare IS NULL AND NOT Src.MgrWorkDir IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @message = 'Updated WorkDir_AdminShare for ' +
                               Cast(@myRowCount as Varchar(8)) + dbo.check_plural(@myRowCount, ' manager', ' managers') +
                               ' in T_Local_Processors'

                exec post_log_entry 'Normal', @message, 'update_cached_manager_work_dirs'
            End

        End

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_cached_manager_work_dirs')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output

    End Catch

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_cached_manager_work_dirs] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[ResetFailedManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ResetFailedManagers]
/****************************************************
**
**  Desc:   Resets managers that report "flag file" in V_Processor_Status_Warnings
**
**  Auth:   12/02/2014 mem - Initial version
**          03/29/2019 mem - Add parameter @resetAllWithError
**
*****************************************************/
(
    @infoOnly tinyint = 0,                  -- 1 to preview the changes
    @resetAllWithError Tinyint = 0,         -- When 0, the manager must have Most_Recent_Log_Message = 'Flag file'; when 1, also matches managers with Mgr_Status = 'Stopped Error'
    @message varchar(512) = '' output
)
As

    set nocount on

    Declare @myError int
    Declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    -- Temp table for managers
    CREATE TABLE #Tmp_ManagersToReset (
        Processor_Name varchar(128) NOT NULL,
        Status_Date datetime
    )

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @resetAllWithError = IsNull(@resetAllWithError, 0)
    Set @message = ''

    -----------------------------------------------------------
    -- Find managers reporting error "Flag file" within the last 6 hours
    -----------------------------------------------------------
    --

    INSERT INTO #Tmp_ManagersToReset (Processor_Name, Status_Date)
    SELECT Processor_Name,
           Status_Date
    FROM V_Processor_Status_Warnings
    WHERE (Most_Recent_Log_Message = 'Flag file' Or
           @resetAllWithError > 0 And Mgr_Status = 'Stopped Error') AND
          Status_Date > DATEADD(hour, -6, GETDATE())
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
        exec @myError = ProteinSeqs.Manager_Control.dbo.SetManagerErrorCleanupMode @ManagerList, @CleanupMode=1, @showTable=1, @infoOnly=@infoOnly

    End

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[ResetFailedManagers] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ResetFailedManagers] TO [DMS_SP_User] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[check_for_param_changed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[check_for_param_changed]
/****************************************************
**
**  Desc:
**    Checks whether or not the manager needs to
**    update its local copy of its parameters
**
**  Return values:
**     0: Parameters haven't changed
**    -1: Parameters have changed
**     n: Error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   06/05/2007
**          06/12/2007 dac - Modified numeric return values to remove duplicates
**          05/04/2009 mem - Added call to post_usage_log_entry to gauge the frequency that this stored procedure is called
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @managerName varchar(50),
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- Check param changed flag for manager
    ---------------------------------------------------
    declare @pvc tinyint
    set @pvc = 0
    --
    SELECT @pvc = M_ParmValueChanged
    FROM T_Mgrs
    WHERE (M_Name = @managerName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @myError = 52001
        set @message = 'Error checking param changed flag'
        goto DONE
    end
    --
    if @myRowCount <> 1
    begin
        set @myError = 52002
        set @message = 'Could not find entry for manager, name = ' + @managername
        goto DONE
    end

    ---------------------------------------------------
    -- No further action required if flag was not set
    ---------------------------------------------------
    --
    if @pvc = 0 goto DONE

    ---------------------------------------------------
    -- Flag was set: Clear flag and set return code
    ---------------------------------------------------
    --
    UPDATE T_Mgrs
    SET M_ParmValueChanged = 0
    WHERE (M_Name = @managerName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @myError = 52003
        set @message = 'Error resetting param changed flag'
        goto DONE
    end

    set @myError = -1

    ---------------------------------------------------
    --
    ---------------------------------------------------
Done:

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'Manager: ' + @managerName
    Exec post_usage_log_entry 'check_for_param_changed', @UsageMessage, @MinimumUpdateInterval=0

    return @myError

GO
GRANT EXECUTE ON [dbo].[check_for_param_changed] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[check_for_param_changed] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[check_for_param_changed] TO [svc-dms] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[set_step_task_tool_version] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_step_task_tool_version]
/****************************************************
**
**  Desc:
**      Record the tool version for the given job step
**      Looks up existing entry in T_Step_Tool_Versions; adds new entry if not defined
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/05/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**
*****************************************************/
(
    @job int,
    @step int,
    @toolVersionInfo varchar(900),
    @returnCode varchar(64) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @ToolVersionID int = 0

    Set @returnCode = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'set_step_task_tool_version', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @job = IsNull(@job, 0)
    Set @step = IsNull(@step, 0)
    Set @ToolVersionInfo = IsNull(@ToolVersionInfo, '')

    print @ToolVersionInfo

    If @ToolVersionInfo = ''
        Set @ToolVersionInfo = 'Unknown'

    ---------------------------------------------------
    -- Look for @ToolVersionInfo in T_Step_Tool_Versions
    ---------------------------------------------------
    --
    SELECT @ToolVersionID = Tool_Version_ID
    FROM T_Step_Tool_Versions
    WHERE Tool_Version = @ToolVersionInfo
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        ---------------------------------------------------
        -- Add a new entry to T_Step_Tool_Versions
        -- Use a Merge statement to avoid the use of an explicit transaction
        ---------------------------------------------------
        --
        MERGE T_Step_Tool_Versions AS target
        USING
            (SELECT @ToolVersionInfo AS Tool_Version
            ) AS Source ( Tool_Version)
        ON (target.Tool_Version = source.Tool_Version)
        WHEN Not Matched THEN
            INSERT (Tool_Version, Entered)
            VALUES (source.Tool_Version, GetDate());


        SELECT @ToolVersionID = Tool_Version_ID
        FROM T_Step_Tool_Versions
        WHERE Tool_Version = @ToolVersionInfo

    End

    If @ToolVersionID = 0
    Begin
        ---------------------------------------------------
        -- Something went wrong; @ToolVersionInfo wasn't found in T_Step_Tool_Versions
        -- and we were unable to add it with the Merge statement
        ---------------------------------------------------

        UPDATE T_Job_Steps
        SET Tool_Version_ID = 1
        WHERE Job = @job AND
              Step = @step AND
              Tool_Version_ID IS NULL
    End
    Else
    Begin

        If @Job > 0
        Begin
            UPDATE T_Job_Steps
            SET Tool_Version_ID = @ToolVersionID
            WHERE Job = @job AND
                  Step = @step

            UPDATE T_Step_Tool_Versions
            SET Most_Recent_Job = @Job,
                Last_Used = GetDate()
            WHERE Tool_Version_ID = @ToolVersionID
        End

    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
    Set @returnCode = Cast(@myError As varchar(64))
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_step_task_tool_version] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_step_task_tool_version] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_step_task_tool_version] TO [svc-dms] AS [dbo]
GO

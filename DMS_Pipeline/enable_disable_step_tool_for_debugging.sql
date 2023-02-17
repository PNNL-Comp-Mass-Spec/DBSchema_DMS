/****** Object:  StoredProcedure [dbo].[EnableDisableStepToolForDebugging] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[EnableDisableStepToolForDebugging]
/****************************************************
**
**  Desc:
**      Bulk enables or disables a step tool to allow for debugging
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/22/2013 mem - Initial version
**          11/11/2013 mem - Added parameter @groupName
**          11/22/2013 mem - Now validating @tool
**          09/01/2017 mem - Implement functionality of @infoOnly
**          08/26/2021 mem - Auto-change @groupName to the default value if an empty string
**
*****************************************************/
(
    @tool varchar(512)='',
    @debugMode tinyint = 0,        -- 1 to disable on pubs to allow for debugging; 0 to enable on pubs
    @groupName varchar(128) = 'Monroe Development Box',
    @infoOnly tinyint = 0
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @groupID int
    Declare @updatedRows int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @tool = IsNull(@tool, '')
    Set @debugMode = IsNull(@debugMode, 0)
    set @groupName = IsNull(@groupName, '')
    Set @infoOnly = IsNull(@infoOnly, 0)

    If @groupName = ''
    Begin
        Set @groupName = 'Monroe Development Box'
    End

    SELECT @groupID = Group_ID
    FROM T_Processor_Tool_Groups
    WHERE Group_Name = @groupName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Print 'Group not found: "' + @groupName + '"; cannot continue'
        Goto Done
    End

    If Not Exists (SELECT * FROM T_Processor_Tool_Group_Details WHERE Tool_Name = @tool)
    Begin
        Print 'Tool not found: "' + @tool + '"; cannot continue'
        Goto Done
    End

    If @debugMode = 0
    Begin -- <a1>
        -- Disable debugging

        If @infoOnly = 0
        Begin
            UPDATE T_Processor_Tool_Group_Details
            SET Enabled = 1
            WHERE (Tool_Name = @tool) and Enabled < 0 AND Group_ID <> @groupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @updatedRows = @updatedRows + @myRowCount

            UPDATE T_Processor_Tool_Group_Details
            SET Enabled = 0
            WHERE (Tool_Name = @tool) and Enabled <> 0 AND Group_ID = @groupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @updatedRows = @updatedRows + @myRowCount

            If @updatedRows = 0
            Begin
                Print 'Debug mode is already disabled for ' + @tool
            End
            Else
            Begin
                Print 'Debug mode disabled for ' + @tool + '; updated ' + Cast(@updatedRows as varchar(9)) + ' rows'
            End
        End
        Else
        Begin
            SELECT 'Set enabled to 1' as [Action], *
            FROM T_Processor_Tool_Group_Details
            WHERE (Tool_Name = @tool) and Enabled < 0 AND Group_ID <> @groupID
            UNION
            SELECT 'Set enabled to 0' as [Action], *
            FROM T_Processor_Tool_Group_Details
            WHERE (Tool_Name = @tool) and Enabled <> 0 AND Group_ID = @groupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                SELECT 'Debug mode is already disabled' AS Comment, *
                FROM T_Processor_Tool_Group_Details
                WHERE (Tool_Name = @tool) and Enabled > 0
            End
        End
    End -- </a1>
    Else
    Begin -- <a2>
        -- Enable debugging

        If @infoOnly = 0
        Begin
            UPDATE T_Processor_Tool_Group_Details
            SET Enabled = -1
            WHERE (Tool_Name = @tool) and Enabled > 0 AND Group_ID <> @groupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @updatedRows = @updatedRows + @myRowCount

            UPDATE T_Processor_Tool_Group_Details
            SET Enabled = 1
            WHERE (Tool_Name = @tool) and Enabled <> 1 AND Group_ID = @groupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @updatedRows = @updatedRows + @myRowCount

            If @updatedRows = 0
            Begin
                Print 'Debug mode is already enabled for ' + @tool
            End
            Else
            Begin
                Print 'Debug mode enabled for ' + @tool + '; updated ' + Cast(@updatedRows as varchar(9)) + ' rows'
            End
        End
        Else
        Begin
            SELECT 'Set enabled to -1' as [Action], *
            FROM T_Processor_Tool_Group_Details
            WHERE (Tool_Name = @tool) and Enabled > 0 AND Group_ID <> @groupID
            UNION
            SELECT 'Set enabled to 1' as [Action], *
            FROM T_Processor_Tool_Group_Details
            WHERE (Tool_Name = @tool) and Enabled <> 1 AND Group_ID = @groupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                SELECT 'Debug mode is already enabled' AS Comment, *
                FROM T_Processor_Tool_Group_Details
                WHERE (Tool_Name = @tool) and Enabled > 0
            End
        End
    End -- </a2>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[EnableDisableStepToolForDebugging] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[EnableDisableArchiveStepTools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.EnableDisableArchiveStepTools
/****************************************************
**
**  Desc:   Enables or disables archive and archive update step tools
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   05/06/2011 mem - Initial version
**          05/12/2011 mem - Added comment parameter
**          12/16/2013 mem - Added step tools 'ArchiveVerify' and 'ArchiveStatusCheck'
**          12/11/2015 mem - Clearing comments that start with 'Disabled' when @enable = 1
**          12/18/2017 mem - Avoid adding @disableComment to the comment field multiple times
**
*****************************************************/
(
    @enable int = 0,
    @disableComment varchar(128) = '',          -- Optional text to add/remove from the Comment field (added if @enable=0 and removed if @enable=1)
    @infoOnly tinyint = 0,
    @message varchar(255) = '' output
)
As
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @NewState int
    Declare @OldState int
    Declare @Task varchar(24)

    Set @message = ''

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    Set @enable = IsNull(@enable, 0)
    Set @disableComment = IsNull(@disableComment, '')
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    if @enable = 0
    Begin
        Set @NewState = -1
        Set @OldState = 1
        Set @Task = 'Disable'
    End
    Else
    Begin
        Set @NewState = 1
        Set @OldState = -1
        Set @Task = 'Enable'
    End

    -----------------------------------------------
    -- Create a temp table to track the tools to update
    -----------------------------------------------
    --
    CREATE TABLE #Tmp_ToolsToUpdate (
        Tool_Name varchar(64)
    )

    INSERT INTO #Tmp_ToolsToUpdate (Tool_Name)
    VALUES ('DatasetArchive'), ('ArchiveUpdate'), ('ArchiveVerify'), ('ArchiveStatusCheck')

    -----------------------------------------------
    -- Preview changes, or perform the work
    -----------------------------------------------
    --
    If @infoOnly <> 0
        SELECT @Task AS Task, *
        FROM T_Processor_Tool ProcTool
             INNER JOIN #Tmp_ToolsToUpdate FilterQ
               ON ProcTool.Tool_Name = FilterQ.Tool_Name
        WHERE Enabled = @OldState
    Else
    Begin
        -- Update the Enabled column
        --
        UPDATE T_Processor_Tool
        SET Enabled = @NewState
        FROM T_Processor_Tool ProcTool
             INNER JOIN #Tmp_ToolsToUpdate FilterQ
               ON ProcTool.Tool_Name = FilterQ.Tool_Name
        WHERE Enabled = @OldState
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @disableComment <> ''
        Begin
            -- Add or remove @disableComment from the Comment column
            --
            If @enable = 0
                UPDATE T_Processor_Tool
                SET [Comment] = CASE
                                    WHEN [Comment] = '' THEN @disableComment
                                    ELSE [Comment] + '; ' + @disableComment
                                END
                FROM T_Processor_Tool ProcTool
                     INNER JOIN #Tmp_ToolsToUpdate FilterQ
                       ON ProcTool.Tool_Name = FilterQ.Tool_Name
                WHERE Enabled = @NewState AND
                      NOT [Comment] LIKE '%' + @disableComment + '%'

            Else

                UPDATE T_Processor_Tool
                SET [Comment] = CASE
                                    WHEN [Comment] = @disableComment THEN ''
                                    ELSE Replace([Comment], '; ' + @disableComment, '')
                                END
                FROM T_Processor_Tool ProcTool
                     INNER JOIN #Tmp_ToolsToUpdate FilterQ
                       ON ProcTool.Tool_Name = FilterQ.Tool_Name
                WHERE (Enabled = @NewState)

        End

        If @disableComment = '' AND @NewState = 1
        Begin
            UPDATE T_Processor_Tool
            SET [Comment] = ''
            FROM T_Processor_Tool ProcTool
                 INNER JOIN #Tmp_ToolsToUpdate FilterQ
                   ON ProcTool.Tool_Name = FilterQ.Tool_Name
            WHERE Enabled = 1 AND
                  [Comment] LIKE 'Disabled%'

        End

    End

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[EnableDisableArchiveStepTools] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[EnableDisableArchiveStepTools] TO [DMSReader] AS [dbo]
GO

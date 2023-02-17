/****** Object:  StoredProcedure [dbo].[RequestFolderCreateTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestFolderCreateTask
/****************************************************
**
** Desc:
**  Returns first available entry in T_Data_Folder_Create_Queue
**
**  Return values: 0: success, otherwise, error code
**
**  Example XML parameters returned in @parameters:
        <root>
        <package>264</package>
        <Path_Local_Root>F:\DataPkgs</Path_Local_Root>
        <Path_Shared_Root>\\protoapps\DataPkgs\</Path_Shared_Root>
        <Path_Folder>2011\Public\264_PNWRCE_Dengue_iTRAQ</Path_Folder>
        <cmd>add</cmd>
        <Source_DB>DMS_Data_Package</Source_DB>
        <Source_Table>T_Data_Package</Source_Table>
        </root>
**
**  Auth:   mem
**          03/17/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @processorName varchar(128),                -- Name of the processor requesting a task
    @taskID int = 0 output,                     -- TaskID assigned; 0 if no task available
    @parameters varchar(4000) output,           -- task parameters (in XML)
    @message varchar(512)='' output,            -- Output message
    @infoOnly tinyint = 0,                      -- Set to 1 to preview the task that would be returned
    @taskCountToPreview int = 10                -- The number of tasks to preview when @infoOnly >= 1
)
As
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    declare @taskAssigned tinyint
    set @taskAssigned = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'RequestFolderCreateTask', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    Set @processorName = IsNull(@processorName, '')
    Set @taskID = 0
    Set @parameters = ''
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @taskCountToPreview = IsNull(@taskCountToPreview, 10)

    ---------------------------------------------------
    -- The analysis manager expects a non-zero
    -- return value if no tasks are available
    -- Code 53000 is used for this
    ---------------------------------------------------
    --
    declare @taskNotAvailableErrorCode int
    set @taskNotAvailableErrorCode = 53000



    ---------------------------------------------------
    -- set up transaction parameters
    ---------------------------------------------------
    --
    declare @transName varchar(32)
    set @transName = 'RequestStepTask'

    -- Start transaction
    begin transaction @transName

    ---------------------------------------------------
    -- Get first available task from T_Data_Folder_Create_Queue
    ---------------------------------------------------
    --

    SELECT TOP 1
           @taskID = Entry_ID
    FROM T_Data_Folder_Create_Queue
    WHERE State = 1
    ORDER BY Entry_ID

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error searching for task'
        goto Done
    end

    if @myRowCount > 0
        set @taskAssigned = 1

    ---------------------------------------------------
    -- If a task step was found (@taskID <> 0) and if @infoOnly = 0,
    --  then update the step state to Running
    ---------------------------------------------------
    --
    If @taskAssigned = 1 AND @infoOnly = 0
    begin
        UPDATE T_Data_Folder_Create_Queue
        SET
            State = 2,
            Processor = @ProcessorName,
            Start = GetDate(),
            Finish = Null
        WHERE Entry_ID = @taskID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Error updating task'
            goto Done
        end

    end

    -- update was successful
    commit transaction @transName

    if @taskAssigned = 1
    begin

        ---------------------------------------------------
        -- task was assigned; return parameters in XML format
        ---------------------------------------------------
        --
        Set @parameters = (
                SELECT Source_ID AS package,
                    Path_Local_Root,
                    Path_Shared_Root,
                    Path_Folder,
                    Command AS cmd,
                    Source_DB,
                    Source_Table
                FROM T_Data_Folder_Create_Queue AS [root]
                WHERE Entry_ID = @taskID
                FOR XML AUTO, ELEMENTS
            )

        if @infoOnly <> 0 And Len(@message) = 0
            Set @message = 'Task ' + Convert(varchar(12), @taskID) + ' would be assigned to ' + @processorName
    end
    else
    begin
        ---------------------------------------------------
        -- No task step found; update @myError and @message
        ---------------------------------------------------
        --
        set @myError = @taskNotAvailableErrorCode
        set @message = 'No available tasks'

    end

    ---------------------------------------------------
    -- dump candidate list if in infoOnly mode
    ---------------------------------------------------
    --
    If @infoOnly <> 0
    Begin
        -- Preview the next @taskCountToPreview available tasks

        SELECT  TOP ( @taskCountToPreview )
                Source_DB,
                Source_Table
                Entry_ID,
                Source_ID,
                Path_Local_Root,
                Path_Shared_Root,
                Path_Folder,
                Command
        FROM T_Data_Folder_Create_Queue
        WHERE State = 1
        ORDER BY Entry_ID
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RequestFolderCreateTask] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestFolderCreateTask] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestFolderCreateTask] TO [svc-dms] AS [dbo]
GO

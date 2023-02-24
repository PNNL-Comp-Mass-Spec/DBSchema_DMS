/****** Object:  StoredProcedure [dbo].[add_update_operations_tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_operations_tasks]
/****************************************************
**
**  Desc:
**      Adds new or edits existing item in T_Operations_Tasks
**
**  Auth:   grk
**  Date:   09/01/2012
**          11/19/2012 grk - Added work package and closed date
**          11/04/2013 grk - Added @hoursSpent
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/16/2022 mem - Rename parameters
**          05/10/2022 mem - Add parameters @taskType and @labName
**                         - Remove parameter @hoursSpent
**          05/16/2022 mem - Do not log data validation errors
**          11/18/2022 mem - Rename parameter to @task
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @id int output,
    @taskType varchar(50),
    @task varchar(64),
    @requester varchar(64),
    @requestedPersonnel varchar(256),
    @assignedPersonnel varchar(256),
    @description varchar(5132),
    @comments varchar(MAX),
    @labName varchar(64),
    @status varchar(32),
    @priority varchar(32),
    @workPackage varchar(32),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    SET @message = ''

    Declare @closed datetime = null
    Declare @taskTypeID Int
    Declare @labID Int
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_operations_tasks', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @taskType = IsNull(@taskType, 'Generic')

    Set @labName = IsNull(@labName, 'Undefined')

    If @status IN ('Completed', 'Not Implemented')
    Begin
        SET @closed = GETDATE()
    End

    ---------------------------------------------------
    -- Resolve task type name to task type ID
    ---------------------------------------------------

    SELECT @taskTypeID = Task_Type_ID
    FROM T_Operations_Task_Type
    WHERE Task_Type_Name = @taskType
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        RAISERROR ('Unrecognized task type name', 11, 16)
    End

    ---------------------------------------------------
    -- Resolve lab name to ID
    ---------------------------------------------------

    SELECT @labID = Lab_ID
    FROM T_Lab_Locations
    WHERE Lab_Name = @labName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        RAISERROR ('Unrecognized lab name', 11, 16)
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp int = 0
        Declare @curStatus varchar(32) = ''
        Declare @curClosed datetime = null
        --
        SELECT @tmp = ID,
               @curStatus = Status,
               @curClosed = Closed
        FROM T_Operations_Tasks
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @tmp = 0
            RAISERROR ('No entry could be found in database for update', 11, 16)

        If @curStatus IN ('Completed', 'Not Implemented')
        Begin
            SET @closed = @curClosed
        End

    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @mode = 'add'
    Begin

        INSERT INTO T_Operations_Tasks (
            Task_Type_ID,
            Task,
            Requester,
            Requested_Personnel,
            Assigned_Personnel,
            Description,
            Comments,
            Lab_ID,
            Status,
            Priority,
            Work_Package,
            Closed
        ) VALUES(
            @taskTypeID,
            @task,
            @requester,
            @requestedPersonnel,
            @assignedPersonnel,
            @description,
            @comments,
            @labID,
            @status,
            @priority,
            @workPackage,
            @closed
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed', 11, 7)

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

    End

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_Operations_Tasks
        SET Task_Type_ID = @taskTypeID,
            Task = @task,
            Requester = @requester,
            Requested_Personnel = @requestedPersonnel,
            Assigned_Personnel = @assignedPersonnel,
            Description = @description,
            Comments = @comments,
            Lab_ID = @labID,
            Status = @status,
            Priority = @priority,
            Work_Package = @workPackage,
            Closed = @closed
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @id)

    End

    ---------------------------------------------------
    ---------------------------------------------------
    End TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'add_update_operations_tasks'
        End
    End CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_operations_tasks] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_operations_tasks] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_operations_tasks] TO [DMS2_SP_User] AS [dbo]
GO

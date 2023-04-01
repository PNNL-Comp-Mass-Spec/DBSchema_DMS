/****** Object:  StoredProcedure [dbo].[update_multiple_capture_tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_multiple_capture_tasks]
/****************************************************
**
**  Desc:
**      Updates capture jobs in list
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   01/04/2010 grk - initial release
**          01/14/2010 grk - enabled all modes
**          01/28/2010 grk - added UpdateParameters action
**          10/25/2010 mem - Now raising an error if @mode is empty or invalid
**          04/28/2011 mem - Set defaults for @action and @mode
**          03/24/2016 mem - Switch to using parse_delimited_integer_list to parse the list of jobs
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @jobList varchar(6000),
    @action VARCHAR(32) = 'Retry',      -- Hold, Ignore, Release, Retry, UpdateParameters
    @mode varchar(12) = 'Update',       -- Update or Preview
    @message varchar(512)= '' output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    -- Required to avoid warnings when retry_selected_tasks is called
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_WARNINGS ON
    SET ANSI_PADDING ON

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_multiple_capture_tasks', @raiseError = 1;

    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    if IsNull(@JobList, '') = ''
    Begin;
        set @message = 'Job list is empty';
        THROW 51001, @message, 1;
    End;

    Set @Mode = IsNull(@mode, '')

    If Not @Mode IN ('Update', 'Preview')
    begin
        If @action = 'Retry'
            set @message = 'Mode should be Update when Action is Retry';
        Else
            set @message = 'Mode should be Update or Preview';

        THROW 51002, @message, 1;
    end

    ---------------------------------------------------
    --
    ---------------------------------------------------
    --
    declare @transName varchar(32)
    set @transName = 'update_multiple_capture_tasks'

    ---------------------------------------------------
    -- update parameters for jobs
    ---------------------------------------------------

    IF @action = 'UpdateParameters' AND @mode = 'update'
    BEGIN --<update params>
        begin transaction @transName
        EXEC @myError = update_parameters_for_task @jobList, @message  output, 0
        IF @myError <> 0
            rollback transaction @transName
        ELSE
            commit transaction @transName
        GOTO Done
    END --<update params>


    IF @action = 'UpdateParameters' AND @mode = 'preview'
    BEGIN --<update params>
        GOTO Done
    END --<update params>

    ---------------------------------------------------
    --  Create temporary table to hold list of jobs
    ---------------------------------------------------

    CREATE TABLE #SJL (
        Job INT,
        Dataset VARCHAR(256) NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to create temporary job table';
        THROW 51003, @message, 1;
    end

    ---------------------------------------------------
    -- Populate table from job list
    ---------------------------------------------------

    INSERT INTO #SJL (Job)
    SELECT Distinct Value
    FROM dbo.parse_delimited_integer_list(@jobList, ',')
    ORDER BY Value
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myError <> 0
    begin
        set @message = 'Error populating temporary job table';
        THROW 51004, @message, 1;
    end

    ---------------------------------------------------
    -- future: verify that jobs exist?
    ---------------------------------------------------
    --


    ---------------------------------------------------
    -- retry jobs
    ---------------------------------------------------

    IF @action = 'Retry' AND @mode = 'update'
    BEGIN --<retry>
        begin transaction @transName
        EXEC @myError = retry_selected_tasks @message output
        IF @myError <> 0
            rollback transaction @transName
        ELSE
            commit transaction @transName
        GOTO Done
    END --<retry>

    ---------------------------------------------------
    -- Hold
    ---------------------------------------------------
    IF @action = 'Hold' AND @mode = 'update'
    BEGIN --<hold>
        begin transaction @transName

        UPDATE
          T_Tasks
        SET
          State = 100
        WHERE
          Job IN ( SELECT
                    Job
                   FROM
                    #SJL )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        IF @myError <> 0
            rollback transaction @transName
        ELSE
            commit transaction @transName
        GOTO Done
    END --<hold>

    ---------------------------------------------------
    -- Ignore
    ---------------------------------------------------
    IF @action = 'Ignore' AND @mode = 'update'
    BEGIN --<Ignore>
        begin transaction @transName

        UPDATE
          T_Tasks
        SET
          State = 101
        WHERE
          Job IN ( SELECT
                    Job
                   FROM
                    #SJL )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        IF @myError <> 0
            rollback transaction @transName
        ELSE
            commit transaction @transName
        GOTO Done
    END --<Ignore>

    ---------------------------------------------------
    -- Release
    ---------------------------------------------------
    IF @action = 'Release' AND @mode = 'update'
    BEGIN --<Release>
        begin transaction @transName

        UPDATE
          T_Tasks
        SET
          State = 1
        WHERE
          Job IN ( SELECT
                    Job
                   FROM
                    #SJL )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        IF @myError <> 0
            rollback transaction @transName
        ELSE
            commit transaction @transName
        GOTO Done
    END --<Release>

    ---------------------------------------------------
    -- delete?
    ---------------------------------------------------

    -- remove_selected_tasks 0, @message output, 0

    ---------------------------------------------------
    -- if we reach this point, action was not implemented
    ---------------------------------------------------

    SET @message = 'The ACTION "' + @action + '" is not implemented.'
    SET @myError = 1

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_multiple_capture_tasks] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_multiple_capture_tasks] TO [DMS_SP_User] AS [dbo]
GO

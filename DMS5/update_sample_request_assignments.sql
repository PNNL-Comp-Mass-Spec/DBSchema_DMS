/****** Object:  StoredProcedure [dbo].[update_sample_request_assignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_sample_request_assignments]
/****************************************************
**
**  Desc:
**  Changes assignment properties to given new value
**  for given list of requested sample preps
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/14/2005
**          07/26/2005 grk - added 'req_assignment'
**          08/02/2005 grk - assignement also sets state to "open"
**          08/14/2005 grk - update state changed date
**          03/14/2006 grk - added stuff for estimated completion date
**          09/02/2011 mem - Now calling post_usage_log_entry
**          02/20/2012 mem - Now using a temporary table to track the requests to update
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          06/18/2014 mem - Now passing default to parse_delimited_integer_list
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/02/2022 mem - Fix bug that treated priority as an integer; instead, should be Normal or High
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @mode varchar(32),      -- 'priority', 'state', 'assignment', 'delete', 'req_assignment', 'est_completion'
    @newValue varchar(512),
    @reqIDList varchar(2048)
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @dt datetime

    Declare @done int = 0
    Declare @count int = 0
    Declare @id int = 0
    Declare @RequestIDNum varchar(12)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_sample_request_assignments', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Populate a temorary table with the requests to process
    ---------------------------------------------------

    Declare @tblRequestsToProcess Table
    (
        RequestID int
    )

    INSERT INTO @tblRequestsToProcess (RequestID)
    SELECT Value
    FROM dbo.parse_delimited_integer_list(@reqIDList, default)
    ORDER BY Value

    -- Process each request in @tblRequestsToProcess
    --
    while @done = 0
    begin
        SELECT TOP 1 @id = RequestID
        FROM @tblRequestsToProcess
        WHERE RequestID > @id
        ORDER BY RequestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @Done = 1
        Else
        Begin
            set @count = @count + 1
            Set @RequestIDNum = Convert(varchar(12), @id)

            -------------------------------------------------
            if @mode = 'est_completion'
            begin
                set @dt = CONVERT(datetime, @newValue)
                --
                UPDATE T_Sample_Prep_Request
                SET [Estimated_Completion] = @dt
                WHERE (ID = @id)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            end

            -------------------------------------------------
            if @mode = 'priority'
            begin
                -- Priority should be Normal or High
                --
                If Not @newValue In ('Normal', 'High')
                begin
                    RAISERROR ('Priority should be Normal or High; not updating request %s', 10, 1, @RequestIDNum)
                    return 51310
                end

                -- set priority
                --
                UPDATE T_Sample_Prep_Request
                SET [Priority] = @newValue
                WHERE (ID = @id)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            end

            -------------------------------------------------
            -- This mode is used for web page option "Assign selected requests to preparer(s)"
            if @mode = 'assignment'
            begin
                UPDATE T_Sample_Prep_Request
                SET Assigned_Personnel = @newValue,
                    StateChanged = getdate(),
                    [State] = 2 -- "open"
                WHERE (ID = @id)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            end


            -------------------------------------------------
            -- This mode is used for web page option "Assign selected requests to requested personnel"
            if @mode = 'req_assignment'
            begin
                UPDATE T_Sample_Prep_Request
                SET Assigned_Personnel = Requested_Personnel,
                    StateChanged = getdate(),
                    [State] = 2 -- "open"
                WHERE (ID = @id)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            end

            -------------------------------------------------
            if @mode = 'state'
            begin
                -- get state ID
                Declare @stID int
                set @stID = 0
                --
                SELECT @stID = State_ID
                FROM T_Sample_Prep_Request_State_Name
                WHERE (State_Name = @newValue)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                if @myError <> 0
                begin
                    RAISERROR ('Lookup state failed for state name "%s"', 10, 1, @newValue)
                    return 51311
                end
                --
                UPDATE T_Sample_Prep_Request
                SET [State] = @stID,
                    StateChanged = getdate()
                WHERE (ID = @id)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            end

            -------------------------------------------------
            if @mode = 'delete'
            begin
                -- Deletes are ignored by this procedure
                -- Use delete_sample_prep_request instead
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            end

            -------------------------------------------------
            if @myError <> 0
            begin
                RAISERROR ('Operation failed for for Request ID %s', 10, 1, @RequestIDNum)
                return 51312
            end
        end
    end

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512) = ''
    Set @UsageMessage = 'Updated ' + Convert(varchar(12), @count) + ' prep request'
    If @count <> 0
        Set @UsageMessage = @UsageMessage + 's'
    Exec post_usage_log_entry 'update_sample_request_assignments', @UsageMessage

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_sample_request_assignments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_sample_request_assignments] TO [DMS_Sample_Prep_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_sample_request_assignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_sample_request_assignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_sample_request_assignments] TO [Limited_Table_Write] AS [dbo]
GO

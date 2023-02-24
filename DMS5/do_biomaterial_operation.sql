/****** Object:  StoredProcedure [dbo].[do_biomaterial_operation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[do_biomaterial_operation]
/****************************************************
**
**  Desc:
**      Perform cell culture operation defined by 'mode'
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/17/2002
**          03/27/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user (Ticket #644)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/13/2022 mem - Fix misspelled words
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @biomaterial varchar(128),
    @mode varchar(12),           -- 'delete'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @result int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'do_biomaterial_operation', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- get cell culture ID
    ---------------------------------------------------

    declare @ccID int
    set @ccID = 0
    --
    SELECT
        @ccID = CC_ID
    FROM T_Cell_Culture
    WHERE (CC_Name = @biomaterial)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or @ccID = 0
    begin
        set @message = 'Could not get Id for cell culture "' + @biomaterial + '"'
        RAISERROR (@message, 10, 1)
        return 51140
    end

    ---------------------------------------------------
    -- Delete cell culture if it is in "new" state only
    ---------------------------------------------------

    if @mode = 'delete'
    begin
        ---------------------------------------------------
        -- verify that cell culture is not used by any experiments
        ---------------------------------------------------

        declare @exps int
        set @exps = 1
        --
        SELECT @exps = COUNT(*)
        FROM  T_Experiment_Cell_Cultures
        WHERE  (CC_ID = @ccID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to count experiment references'
            RAISERROR (@message, 10, 1)
            return 51141
        end
        --
        if @exps > 0
        begin
            set @message = 'Cannot delete cell culture that is referenced by any experiments'
            RAISERROR (@message, 10, 1)
            return 51141
        end

        ---------------------------------------------------
        -- delete the cell culture
        ---------------------------------------------------

        DELETE FROM T_Cell_Culture
        WHERE CC_ID = @ccID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            RAISERROR ('Could not delete cell culture "%s"',
                10, 1, @biomaterial)
            return 51142
        end

        -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Declare @stateID int
            Set @stateID = 0

            Exec alter_event_log_entry_user 2, @ccID, @stateID, @callingUser
        End

        return 0
    end -- mode 'delete'

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    set @message = 'Mode "' + @mode +  '" was unrecognized'
    RAISERROR (@message, 10, 1)
    return 51222

GO
GRANT VIEW DEFINITION ON [dbo].[do_biomaterial_operation] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[do_biomaterial_operation] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[add_update_instrument_usage_report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_instrument_usage_report]
/****************************************************
**
**  Desc:
**    Adds new or edits existing item in
**    T_EMSL_Instrument_Usage_Report
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/27/2012
**          09/11/2012 grk - changed type of @Start
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/11/2017 mem - Replace column Usage with Usage_Type
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/05/2018 mem - Assure that @comment does not contain LF or CR
**          04/17/2020 mem - Use Dataset_ID instead of ID
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @seq int,
    @emslInstID int,                    -- @EMSLInstID
    @instrument varchar(64),            -- Unused (not updatable)
    @type varchar(128),                 -- Unused (not updatable)
    @start varchar(32),                 -- Unused (not updatable)
    @minutes int,                       -- Unused (not updatable)
    @year int,                          -- Unused (not updatable)
    @month int,                         -- Unused (not updatable)
    @id int,                            -- Unused (not updatable)     -- Dataset_ID
    @proposal varchar(32),              -- Proposal for update
    @usage varchar(32),                 -- Usage name for update (ONSITE, REMOTE, MAINTENANCE, BROKEN, etc.); corresponds to T_EMSL_Instrument_Usage_Type
    @users varchar(1024),               -- Users for update
    @operator varchar(64),              -- Operator for update (should be an integer representing EUS Person ID; if an empty string, will store NULL for the operator ID)
    @comment varchar(4096),             -- Comment for update
    @mode varchar(12) = 'update',       -- The only supported mode is update
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_instrument_usage_report', @raiseError = 1
    If @authorized = 0
    BEGIN;
        THROW 51000, 'Access denied', 1;
    END;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @mode = IsNull(@mode, '')
    Set @Usage = IsNull(@Usage, '')

    Declare @usageTypeID tinyint = 0

    SELECT @usageTypeID = ID
    FROM T_EMSL_Instrument_Usage_Type
    WHERE ([Name] = @Usage)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 Or IsNull(@usageTypeID, 0) = 0
    Begin
        Declare @msg varchar(128) = 'Invalid usage ' + @Usage
        RAISERROR (@msg, 11, 16)
    End

    -- Assure that @Operator is either an integer or null
    Set @Operator = Try_Convert(int, @Operator)

    -- Assure that @comment does not contain LF or CR
    Set @Comment = Replace(Replace(@Comment, Char(10), ' '), Char(13), ' ')

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    if @mode = 'update'
    begin
        -- cannot update a non-existent entry
        --
        Declare @tmp int = 0
        --
        SELECT @tmp = Dataset_ID
        FROM  T_EMSL_Instrument_Usage_Report
        WHERE (Seq = @Seq)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 OR @tmp = 0
            RAISERROR ('No entry could be found in database for update', 11, 16)
    end

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------

    if @mode = 'add'
    begin
        RAISERROR ('"Add" mode not supported', 11, 7)
    end -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @mode = 'update'
    begin
        Set @myError = 0
        --
        UPDATE T_EMSL_Instrument_Usage_Report
        SET
            Proposal = @Proposal,
            Usage_Type = @usageTypeID,
            Users = @Users,
            Operator = @Operator,
            Comment = @Comment
        WHERE (Seq = @Seq)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
            RAISERROR ('Update operation failed: "%d"', 11, 4, @Seq)

    end -- update mode

    ---------------------------------------------------
    ---------------------------------------------------
    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'add_update_instrument_usage_report'
    END CATCH
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_instrument_usage_report] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_instrument_usage_report] TO [DMS2_SP_User] AS [dbo]
GO

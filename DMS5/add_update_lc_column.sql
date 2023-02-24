/****** Object:  StoredProcedure [dbo].[add_update_lc_column] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_lc_column]
/****************************************************
**
**  Desc: Adds a new entry to LC Column table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   12/09/2003
**          08/19/2010 grk - try-catch for error handling
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Fix error message entity name
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/19/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/30/2018 mem - Make @columnNumber an output parameter
**          03/21/2022 mem - Fix typo in comment and update capitalization of keywords
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @columnNumber varchar(128) output,        -- Input/output: Aka column name
    @packingMfg varchar(64),
    @packingType varchar(64),
    @particleSize varchar(64),
    @particleType varchar(64),
    @columnInnerDia varchar(64),
    @columnOuterDia varchar(64),
    @length varchar(64),
    @state  varchar(32),
    @operator_username varchar(50),
    @comment varchar(244),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @logErrors tinyint = 1

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_lc_column', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If LEN(IsNull(@columnNumber, '')) < 1
    Begin
        Set @myError = 51110
        RAISERROR ('Column name was blank', 11, 1)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @columnID int = -1
    --
    SELECT @columnID = ID
    FROM T_LC_Column
    WHERE (SC_Column_Number = @columnNumber)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error while trying to find existing entry in database'
        RAISERROR (@msg, 11, 2)
    End

    -- Cannot create an entry that already exists
    --
    If @columnID <> -1 and @mode = 'add'
    Begin
        Set @logErrors = 0
        Set @msg = 'Cannot add: Specified LC column already in database'
        RAISERROR (@msg, 11, 3)
    End

    -- Cannot update a non-existent entry
    --
    If @columnID = -1 and @mode = 'update'
    Begin
        Set @logErrors = 0
        Set @msg = 'Cannot update: Specified LC column is not in database'
        RAISERROR (@msg, 11, 5)
    End

    ---------------------------------------------------
    -- Resolve ID for state
    ---------------------------------------------------

    Declare @stateID int = -1
    --
    SELECT @stateID = LCS_ID
    FROM T_LC_Column_State_Name
    WHERE LCS_Name = @state
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error trying to look up state ID'
        RAISERROR (@msg, 11, 6)
    End

    If @stateID = -1
    Begin
        Set @logErrors = 0
        Set @msg = 'Invalid column state: ' + @state
        RAISERROR (@msg, 11, 7)
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If @Mode = 'add'
    Begin
        INSERT INTO T_LC_Column
        (
            SC_Column_Number,
            SC_Packing_Mfg,
            SC_Packing_Type,
            SC_Particle_size,
            SC_Particle_type,
            SC_Column_Inner_Dia,
            SC_Column_Outer_Dia,
            SC_Length,
            SC_State,
            SC_Operator_PRN,
            SC_Comment,
            SC_Created
        ) VALUES (
            @columnNumber,
            @packingMfg,
            @packingType,
            @particleSize,
            @particleType,
            @columnInnerDia,
            @columnOuterDia,
            @length,
            @stateID,
            @operator_username,
            @comment,
            GETDATE()
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Insert operation failed'
            RAISERROR (@msg, 11, 8)
        End
    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If @Mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_LC_Column
        Set
            SC_Column_Number = @columnNumber,
            SC_Packing_Mfg = @packingMfg,
            SC_Packing_Type = @packingType,
            SC_Particle_size = @particleSize,
            SC_Particle_type = @particleType,
            SC_Column_Inner_Dia = @columnInnerDia,
            SC_Column_Outer_Dia = @columnOuterDia,
            SC_Length = @length,
            SC_State = @stateID,
            SC_Operator_PRN = @operator_username,
            SC_Comment = @comment
        WHERE (ID = @columnID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Update operation failed'
            RAISERROR (@msg, 11, 9)
        End
    End -- update mode

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'add_update_lc_column'
        End
    END Catch

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_lc_column] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_lc_column] TO [DMS_LC_Column_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_lc_column] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_lc_column] TO [Limited_Table_Write] AS [dbo]
GO

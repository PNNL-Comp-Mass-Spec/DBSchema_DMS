/****** Object:  StoredProcedure [dbo].[do_material_container_operation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[do_material_container_operation]
/****************************************************
**
**  Desc: Do an operation on a container, using the container name
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          10/01/2009 mem - Expanded error message
**          08/19/2010 grk - try-catch for error handling
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Prevent updating containers of type 'na'
**          07/07/2022 mem - Include container name when logging error messages from update_material_containers
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
    @name varchar(128),                 -- Container name
    @mode varchar(32),                  -- 'move_container', 'retire_container', 'retire_container_and_contents', 'unretire_container'
    @message varchar(512) output,
    @callingUser varchar (128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512) = ''
    Declare @logErrors Tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'do_material_container_operation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @name = Ltrim(Rtrim(IsNull(@name, '')))
    Set @mode = Ltrim(Rtrim(IsNull(@mode, '')))

    If Len(@name) = 0
    Begin
        Set @msg = 'Container name cannot be empty'
        RAISERROR (@msg, 11, 1)
    End

    If Exists (Select * From V_Material_Containers_List_Report Where Container = @name And [Type] = 'na')
    Begin
        Set @msg = 'Container "' + @name + '" cannot be updated by the website; contact a DMS admin (see do_material_container_operation)'
        Set @logErrors = 1
        RAISERROR (@msg, 11, 1)
    End

    Declare @tmpID int = 0
    --
    SELECT @tmpID = ID
    FROM T_Material_Containers
    WHERE Tag = @name

    If @tmpID = 0
    Begin
        Set @msg = 'Could not find the container named "' + @name + '" (mode is ' + @mode + ')'
        RAISERROR (@msg, 11, 1)
    End
    Else
    Begin
        Declare @iMode varchar(32) = @mode
        Declare @containerList varchar(4096) = @tmpID
        Declare @newValue varchar(128) = ''
        Declare @comment varchar(512) = ''
        Set @logErrors = 1

        exec @myError = update_material_containers
                @iMode,
                @containerList,
                @newValue,
                @comment,
                @msg output,
                @callingUser

        If @myError <> 0
        Begin
            RAISERROR (@msg, 11, 2)
        End
    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            Rollback TRANSACTION;

        If @logErrors > 0
        Begin
            If CharIndex(@name, @message) > 0
                Set @msg = @message
            Else
                Set @msg = @message + ' (container ' + @name + ')'

            Exec post_log_entry 'Error', @msg, 'do_material_container_operation'
        End

    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[do_material_container_operation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_material_container_operation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[do_material_container_operation] TO [Limited_Table_Write] AS [dbo]
GO

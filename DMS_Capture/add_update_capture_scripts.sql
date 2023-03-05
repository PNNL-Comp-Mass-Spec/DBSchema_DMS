/****** Object:  StoredProcedure [dbo].[add_update_capture_scripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_capture_scripts]
/****************************************************
**
**  Desc:
**      Adds new or edits existing T_Scripts
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/23/2008 grk - Initial version
**          03/24/2009 mem - Now calling alter_entered_by_user when @callingUser is defined
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Rename procedure to differentiate from DMS_Pipeline
**
*****************************************************/
(
    @script varchar(64),
    @description varchar(512),
    @enabled char(1),
    @resultsTag varchar(8),
    @contents text,
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    declare @ID int

    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin Try

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_capture_scripts', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @Description = IsNull(@Description, '')
    Set @Enabled = IsNull(@Enabled, 'Y')
    Set @mode = IsNull(@mode, '')
    Set @message = ''
    Set @callingUser = IsNull(@callingUser, '')

    If @Description = ''
    begin
        set @message = 'Description cannot be blank'
        return 51005
    End

    If @Mode <> 'add' and @mode <> 'update'
    Begin
        set @message = 'Unknown Mode: ' + @mode
        return 51006
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------
    declare @tmp int = 0
    --
    SELECT @tmp = ID
    FROM  T_Scripts
    WHERE Script = @Script
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error searching for existing entry'
        return 51007
    end

    -- cannot update a non-existent entry
    --
    if @mode = 'update' and @tmp = 0
    begin
        set @message = 'Could not find "' + @Script + '" in database'
        return 51008
    end

    -- cannot add an existing entry
    --
    if @mode = 'add' and @tmp <> 0
    begin
        set @message = 'Script "' + @Script + '" already exists in database'
        return 51009
    end

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

        INSERT INTO T_Scripts (
            Script,
            Description,
            Enabled,
            Results_Tag,
            Contents
        ) VALUES (
            @Script,
            @Description,
            @Enabled,
            @ResultsTag,
            @Contents
        )
        /**/
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Insert operation failed'
            return 51010
        end

        -- If @callingUser is defined, then update Entered_By in T_Scripts_History
        If Len(@callingUser) > 0
        Begin
            Set @ID = Null
            SELECT @ID = ID
            FROM T_Scripts
            WHERE Script = @Script

            If Not @ID Is Null
                Exec alter_entered_by_user 'T_Scripts_History', 'ID', @ID, @CallingUser
        End

    end -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        set @myError = 0
        --

        UPDATE T_Scripts
        SET
          Description = @Description,
          Enabled = @Enabled,
          Results_Tag = @ResultsTag,
          Contents = @Contents
        WHERE (Script = @Script)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
          set @message = 'Update operation failed: "' + @Script + '"'
          return 51004
        end

        -- If @callingUser is defined, then update Entered_By in T_Organisms_Change_History
        If Len(@callingUser) > 0
        Begin
            Set @ID = Null
            SELECT @ID = ID
            FROM T_Scripts
            WHERE Script = @Script

            If Not @ID Is Null
                Exec alter_entered_by_user 'T_Scripts_History', 'ID', @ID, @CallingUser
        End

    end -- update mode

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'add_update_capture_scripts')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[add_update_capture_scripts] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_capture_scripts] TO [DMS_SP_User] AS [dbo]
GO

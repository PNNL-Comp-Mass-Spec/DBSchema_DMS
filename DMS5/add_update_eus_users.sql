/****** Object:  StoredProcedure [dbo].[add_update_eus_users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_eus_users]
/****************************************************
**
**  Desc: Adds new or updates existing EUS Users in database
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**      @EUSPersonID     EUS Proposal ID
**      @EUSNameFm       EUS Proposal State
**      @EUSSiteStatus   EUS Proposal Title
**      @HanfordID       Hanford ID
**
**  Auth:   jds
**  Date:   09/01/2006
**          03/19/2012 mem - Added @HanfordID
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**
*****************************************************/
(
    @eusPersonID varchar(32),
    @eusNameFm varchar(50),
    @eusSiteStatus varchar(32),
    @hanfordID varchar(50),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_eus_users', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    set @myError = 0
    if LEN(@EUSPersonID) < 1
    begin
        set @myError = 51000
        RAISERROR ('EUS Person ID must be specified', 10, 1)
    end
    --
    if LEN(@EUSNameFm) < 1
    begin
        set @myError = 51000
        RAISERROR ('EUS Persons Name must be specified', 10, 1)
    end
    --
    if @myError <> 0
        return @myError

    if LEN(@EUSSiteStatus) < 1
    begin
        set @myError = 51000
        RAISERROR ('EUS Site Status must be specified', 10, 1)
    end
    --
    if @myError <> 0
        return @myError

    If Len(IsNull(@HanfordID, '')) = 0
        Set @HanfordID = Null

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------
    declare @TempEUSPersonID varchar(10)
    set @TempEUSPersonID = '0'
    --
    execute @TempEUSPersonID = get_eus_user_id @EUSPersonID

    -- cannot create an entry that already exists
    --
    if @TempEUSPersonID <> '0' and @mode = 'add'
    begin
        set @msg = 'Cannot add: EUS Person ID "' + @EUSPersonID + '" is already in the database '
        RAISERROR (@msg, 10, 1)
        return 51004
    end

    -- cannot update a non-existent entry
    --
    if @TempEUSPersonID = '0' and @mode = 'update'
    begin
        set @msg = 'Cannot update: EUS Person ID "' + @EUSPersonID + '" is not in the database '
        RAISERROR (@msg, 10, 1)
        return 51004
    end

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

        INSERT INTO dbo.T_EUS_Users (
            PERSON_ID,
            NAME_FM,
            Site_Status,
            HID,
            Last_Affected
        ) VALUES (
            @EUSPersonID,
            @EUSNameFm,
            @EUSSiteStatus,
            @HanfordID,
            GetDate()
        )

        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Insert operation failed: "' + @EUSNameFm + '"'
            RAISERROR (@msg, 10, 1)
            return 51007
        end
    end -- add mode


    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        set @myError = 0
        --
        UPDATE  T_EUS_Users
        SET
            NAME_FM = @EUSNameFm,
            Site_Status =  @EUSSiteStatus,
            HID = @HanfordID,
            Last_Affected = GetDate()
        WHERE (PERSON_ID = @EUSPersonID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Update operation failed: "' + @EUSNameFm + '"'
            RAISERROR (@msg, 10, 1)
            return 51004
        end
    end -- update mode

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_eus_users] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_eus_users] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_eus_users] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_eus_users] TO [Limited_Table_Write] AS [dbo]
GO

/****** Object:  StoredProcedure [dbo].[update_instrument_group_allowed_dataset_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_instrument_group_allowed_dataset_type]
/****************************************************
**
**  Desc:
**      Adds, updates, or deletes allowed datset type for given instrument group
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   09/19/2009 grk - Initial release (Ticket #749, http://prismtrac.pnl.gov/trac/ticket/749)
**          02/12/2010 mem - Now making sure @DatasetType is properly capitalized
**          08/28/2010 mem - Updated to work with instrument groups
**          09/02/2011 mem - Now calling post_usage_log_entry
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**
*****************************************************/
(
    @instrumentGroup varchar(64),
    @datasetType varchar(50),
    @comment varchar(1024),
    @mode varchar(12) = 'add', -- or 'update' or 'delete'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    declare @msg varchar(256)
    declare @ValidMode tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_instrument_group_allowed_dataset_type', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    BEGIN TRY

    ---------------------------------------------------
    -- Validate InstrumentGroup and DatasetType
    ---------------------------------------------------
    --
    IF NOT EXISTS ( SELECT * FROM T_Instrument_Group WHERE IN_Group = @InstrumentGroup )
        RAISERROR ('Instrument group "%s" is not valid', 11, 12, @InstrumentGroup)

    IF NOT EXISTS ( SELECT * FROM T_Dataset_Type_Name WHERE DST_Name = @DatasetType )
        RAISERROR ('Dataset type "%s" is not valid', 11, 12, @DatasetType)

    ---------------------------------------------------
    -- Make sure @DatasetType is properly capitalized
    ---------------------------------------------------

    SELECT @DatasetType = DST_Name
    FROM T_Dataset_Type_Name
    WHERE DST_Name = @DatasetType

    ---------------------------------------------------
    -- Does an entry already exist?
    ---------------------------------------------------
    --
    DECLARE @exists VARCHAR(50)
    SET @exists = ''
    --
    SELECT @exists = IN_Group
    FROM T_Instrument_Group_Allowed_DS_Type
    WHERE IN_Group = @InstrumentGroup AND
          Dataset_Type = @DatasetType

    ---------------------------------------------------
    -- add mode
    ---------------------------------------------------
    --
    IF @mode = 'add'
    BEGIN --<add>
        IF @exists <> ''
        BEGIN
            SET @msg = 'Cannot add: Entry "' + @DatasetType + '" already exists for group ' + @InstrumentGroup
            RAISERROR (@msg, 11, 13)
        END

        INSERT INTO T_Instrument_Group_Allowed_DS_Type ( IN_Group,
                                                         Dataset_Type,
                                                         Comment)
        VALUES(@InstrumentGroup, @DatasetType, @Comment)

        Set @ValidMode = 1
    END --<add>


    ---------------------------------------------------
    -- update mode
    ---------------------------------------------------
    --
    IF @mode = 'update'
    BEGIN --<update>
        IF @exists = ''
        BEGIN
            SET @msg = 'Cannot Update: Entry "' + @DatasetType + '" does not exist for group ' + @InstrumentGroup
            RAISERROR (@msg, 11, 14)
        END

        UPDATE T_Instrument_Group_Allowed_DS_Type
        SET Comment = @Comment
        WHERE (IN_Group = @InstrumentGroup) AND
              (Dataset_Type = @DatasetType)

        Set @ValidMode = 1
    END --<update>

    ---------------------------------------------------
    -- delete mode
    ---------------------------------------------------
    --
    IF @mode = 'delete'
    BEGIN --<delete>
        IF @exists = ''
        BEGIN
            SET @msg = 'Cannot Delete: Entry "' + @DatasetType + '" does not exist for group ' + @InstrumentGroup
            RAISERROR (@msg, 11, 15)
        END

        DELETE FROM T_Instrument_Group_Allowed_DS_Type
        WHERE (IN_Group = @InstrumentGroup) AND
              (Dataset_Type = @DatasetType)

        Set @ValidMode = 1
    END --<delete>

    If @ValidMode = 0
    Begin
        ---------------------------------------------------
        -- unrecognized mode
        ---------------------------------------------------

        SET @msg = 'Unrecognized Mode:' + @mode
        RAISERROR (@msg, 11, 16)
    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_instrument_group_allowed_dataset_type'
    END CATCH

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'Instrument group: ' + @InstrumentGroup
    Exec post_usage_log_entry 'update_instrument_group_allowed_dataset_type', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_instrument_group_allowed_dataset_type] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_instrument_group_allowed_dataset_type] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_instrument_group_allowed_dataset_type] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_instrument_group_allowed_dataset_type] TO [Limited_Table_Write] AS [dbo]
GO

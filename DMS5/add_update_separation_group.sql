/****** Object:  StoredProcedure [dbo].[add_update_separation_group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_separation_group]
/****************************************************
**
**  Desc:   Adds new or edits existing item in T_Separation_Group
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/12/2017 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/15/2021 mem - Add @fractionCount
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          01/17/2024 mem - Verify that @separationGroup is not an empty string
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @separationGroup varchar(64),
    @comment varchar(512),
    @active tinyint,
    @samplePrepVisible tinyint,
    @fractionCount smallint,
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int =0

    Declare @datasetTypeID int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_separation_group', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @separationGroup = LTrim(RTrim(IsNull(@separationGroup, '')))
    Set @comment = IsNull(@comment, '')
    Set @active = IsNull(@active, 0)
    Set @samplePrepVisible = IsNull(@samplePrepVisible, 0)
    Set @fractionCount = IsNull(@fractionCount, 0)

    Set @message = ''

    If @separationGroup = ''
        RAISERROR ('Separation group name must be specified', 11, 16)

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp varchar(64) = ''
        --
        SELECT @tmp = Sep_Group
        FROM  T_Separation_Group
        WHERE (Sep_Group = @separationGroup)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @tmp = ''
            RAISERROR ('No entry could be found in database for update', 11, 16)
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @Mode = 'add'
    Begin

        INSERT INTO T_Separation_Group( Sep_Group,
                                        [Comment],
                                        Active,
                                        Sample_Prep_Visible,
                                        Fraction_Count)
        VALUES(@separationGroup, @comment, @active, @samplePrepVisible, @fractionCount)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed', 11, 7)

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @Mode = 'update'
    Begin
        set @myError = 0
        --
        UPDATE T_Separation_Group
        SET Comment = @comment,
            Active = @active,
            Sample_Prep_Visible = @samplePrepVisible,
            Fraction_Count = @fractionCount
        WHERE Sep_Group = @separationGroup
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @separationGroup)

    End -- update mode

    END TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'add_update_separation_group'
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_separation_group] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_separation_group] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_separation_group] TO [Limited_Table_Write] AS [dbo]
GO

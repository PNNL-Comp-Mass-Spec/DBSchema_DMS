/****** Object:  StoredProcedure [dbo].[delete_experiment_group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_experiment_group]
/****************************************************
**
**  Desc:
**  Remove an experiment group (but not the experiments)
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/13/2006
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @groupID int = 0,
    @message varchar(512)='' output
)
AS
    declare @delim char(1) = ','

    declare @done int
    declare @count int

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_experiment_group', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'delete_experiment_group'
    begin transaction @transName

    ---------------------------------------------------
    -- Delete the items
    ---------------------------------------------------

    DELETE FROM T_Experiment_Group_Members
    WHERE Group_ID = @groupID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Failed to delete experiment group member entries'
        --RAISERROR (@message, 10, 1)
        return 51093
    end

    DELETE FROM T_Experiment_Groups
    WHERE Group_ID = @groupID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Failed to delete experiment group entries'
        --RAISERROR (@message, 10, 1)
        return 51093
    end

    ---------------------------------------------------
    -- Finalize the changes
    ---------------------------------------------------

    commit transaction @transName
    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[delete_experiment_group] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_experiment_group] TO [Limited_Table_Write] AS [dbo]
GO

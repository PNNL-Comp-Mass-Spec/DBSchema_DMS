/****** Object:  StoredProcedure [dbo].[delete_sample_prep_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_sample_prep_request]
/****************************************************
**
**  Desc:
**      Delete sample prep request
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   11/10/2005
**          01/04/2006 grk - added delete for aux info
**          05/16/2008 mem - Added optional parameter @callingUser; if provided, then will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new aux info table and column names
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestID int,
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_sample_prep_request', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

       ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    declare @transName varchar(32)
    set @transName = 'delete_sample_prep_request'
    begin transaction @transName

    ---------------------------------------------------
    -- remove any references from experiments
    ---------------------------------------------------
    --
    declare @num int
    set @num = 1
    --
    UPDATE T_Experiments
    SET EX_sample_prep_request_ID = 0
    WHERE (EX_sample_prep_request_ID = @requestID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error removing experiment references to request'
        goto Done
    end

    ---------------------------------------------------
    -- Delete all entries from auxiliary value table
    -- for the sample prep request
    ---------------------------------------------------

    DELETE FROM T_Aux_Info_Value
    WHERE (Target_ID = @requestID) AND
    (
        Aux_Description_ID IN
        (
            SELECT Item_ID
            FROM V_Aux_Info_Definition_with_ID
            WHERE (Target = 'SamplePrepRequest')
        )
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error deleting aux info'
        goto Done
    end

    ---------------------------------------------------
    -- delete the sample prep request itself
    ---------------------------------------------------
    --
    DELETE FROM T_Sample_Prep_Request
    WHERE     (ID = @requestID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error deleting sample prep request'
        goto Done
    end

    ---------------------------------------------------
    -- if we got here, complete transaction
    ---------------------------------------------------
    commit transaction @transName


    -- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
    If Len(@callingUser) > 0
        Exec alter_entered_by_user 'T_Sample_Prep_Request_Updates', 'Request_ID', @requestID, @CallingUser,
                                @EntryDateColumnName='Date_of_Change', @EnteredByColumnName='System_Account'

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[delete_sample_prep_request] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_sample_prep_request] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_sample_prep_request] TO [Limited_Table_Write] AS [dbo]
GO

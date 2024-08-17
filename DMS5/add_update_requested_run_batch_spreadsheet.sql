/****** Object:  StoredProcedure [dbo].[add_update_requested_run_batch_spreadsheet] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_requested_run_batch_spreadsheet]
/****************************************************
**
**  Desc:
**      Add new or edit an existing requested run batch, including updating the requested runs that are in the batch
**
**      This procedure accepts a list of requested run names, which are converted to requested run IDs
**
**      The procedure appears to be unused, as of January 2024
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   05/18/2009
**          08/27/2010 mem - Expanded @RequestedCompletionDate to varchar(24) to support long dates of the form 'Jan 01 2010 12:00:00AM'
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 mem - Use new parameter name when calling add_update_requested_run_batch
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          01/22/2024 mem - Remove argument @requestedInstrument since we no longer associate instrument groups with requested run batches
**                         - Remove deprecated instrument group argument when calling add_update_requested_run_batch()
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @id int output,
    @name varchar(50),
    @description varchar(256),
    @requestNameList varchar(8000),
    @ownerUsername varchar(24),
    @requestedBatchPriority varchar(24),
    @requestedCompletionDate varchar(24),
    @justificationHighPriority varchar(512),
    -- Deprecated in January 2024
    -- @requestedInstrument varchar(24),                        -- Will typically contain an instrument group, not an instrument name
    @comment varchar(512),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_requested_run_batch_spreadsheet', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Get list of request ids based on Request name list
    ---------------------------------------------------
    --
    Declare @RequestedRunList varchar(4000)

    SELECT @RequestedRunList = COALESCE(@RequestedRunList + ', ', '') + cast(rr.ID as varchar(32))
    FROM make_table_from_list(@RequestNameList) r
        join T_Requested_Run rr on r.Item = rr.RDS_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Failed to populate temporary table for requests'
        RAISERROR (@message, 10, 1)
        return 51219
    End

    If @myRowCount = 0
    Begin
        Set @message = 'The requests submitted in the list do not exist in the database.  Check the requests and try again.'
        RAISERROR (@message, 10, 1)
        return 51220
    End

    -- Auto-create a batch for the new requests
    --
    exec add_update_requested_run_batch
                             @id = @id output
                            ,@name = @Name
                            ,@description = @Description
                            ,@requestedRunList = @requestedRunList
                            ,@ownerUsername = @ownerUsername
                            ,@requestedBatchPriority = @RequestedBatchPriority
                            ,@requestedCompletionDate = @RequestedCompletionDate
                            ,@justificationHighPriority = @JustificationHighPriority
                            -- Deprecated in January 2024
                            -- ,@requestedInstrumentGroup = @RequestedInstrument
                            ,@comment = @Comment
                            ,@mode = @mode
                            ,@message = @message output
                            ,@useRaiseError = 0

    -- Check for any errors from stored procedure
    If @message <> ''
    Begin
        RAISERROR (@message, 10, 1)
        return 51219
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_requested_run_batch_spreadsheet] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_requested_run_batch_spreadsheet] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_requested_run_batch_spreadsheet] TO [Limited_Table_Write] AS [dbo]
GO

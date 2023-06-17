/****** Object:  StoredProcedure [dbo].[validate_requested_run_batch_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_requested_run_batch_params]
/****************************************************
**
**  Desc: Validates values for creating/updating a requested run batch
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/29/2021 mem - Refactored code from add_update_requested_run_batch
**          05/31/2021 mem - Add support for @mode = 'PreviewAdd'
**          02/14/2023 mem - Rename username and requested instrument group parameters
**                         - Update error message
**          02/16/2023 mem - Add @batchGroupID and @batchGroupOrder
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/16/2023 mem - Validate instrument group name
**
*****************************************************/
(
    @batchID int,                               -- Only used when @mode is 'update'
    @name varchar(50),
    @description varchar(256),
    @ownerUsername varchar(64),
    @requestedBatchPriority varchar(24),
    @requestedCompletionDate varchar(32),
    @justificationHighPriority varchar(512),
    @requestedInstrumentGroup varchar(64),      -- Will typically contain an instrument group, not an instrument name
    @comment varchar(512),
    @batchGroupID int = Null output,
    @batchGroupOrder Int = Null output,
    @mode varchar(12) = 'add',                  -- 'add' or 'update' or 'PreviewAdd'
    @instrumentGroupToUse varchar(64) output,   -- Output: Actual instrument group
    @userID int output,                         -- Output: user_id for @ownerUsername
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    BEGIN TRY
        Set @name = LTrim(RTrim(IsNull(@name, '')))
        Set @description = IsNull(@description, '')

        If Len(@name) < 1
        Begin
            Set @message = 'Must define a batch name'
            Set @myError = 50000
            Return @myError
        End

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        If Len(IsNull(@requestedCompletionDate, '')) > 0
        Begin
            If (SELECT ISDATE(@requestedCompletionDate)) = 0
            Begin
                Set @message = 'Requested completion date is not a valid date: ' + @requestedCompletionDate
                Set @myError = 50001
                Return @myError
            End
        End

        ---------------------------------------------------
        -- Determine the Instrument Group
        ---------------------------------------------------

        Set @requestedInstrumentGroup = LTrim(RTrim(Coalesce(@requestedInstrumentGroup, '')))

        -- Set the instrument group to @requestedInstrumentGroup for now
        Set @instrumentGroupToUse = @requestedInstrumentGroup

        If NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @instrumentGroupToUse)
        Begin
            -- Try to update instrument group using T_Instrument_Name
            SELECT @instrumentGroupToUse = IN_Group
            FROM T_Instrument_Name
            WHERE IN_Name = @requestedInstrumentGroup
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            If @myRowCount = 0
            Begin
                Set @message = 'Invalid Instrument Group: ' + @requestedInstrumentGroup
                Set @myError = 50002
                Return @myError
            End
        End

        ---------------------------------------------------
        -- High priority requires justification
        ---------------------------------------------------
        --
        If @requestedBatchPriority = 'High' AND ISNULL(@justificationHighPriority, '') = ''
        Begin
            Set @message = 'Justification must be entered If high priority is being requested'
            Set @myError = 50003
            Return @myError
        End

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If @mode In ('add', 'PreviewAdd')
        Begin
            If Exists (SELECT * FROM T_Requested_Run_Batches WHERE Batch = @name)
            Begin
                Set @message = 'Cannot add batch: "' + @name + '" already exists in database'
                Set @myError = 50004
                Return @myError
            End
        End

        -- Cannot update a non-existent entry
        --
        If @mode = 'update'
        Begin
            If IsNull(@batchID, 0) = 0
            Begin
                Set @message = 'Cannot update batch; ID must non-zero'
                Set @myError = 50005
                Return @myError
            End

            Declare @locked varchar(12)
            --
            SELECT @locked = Locked
            FROM  T_Requested_Run_Batches
            WHERE  ID = @batchID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Error trying to find existing entry in T_Requested_Run_Batches'
                Set @myError = 50006
                Return @myError
            End

            If @myRowCount = 0
            Begin
                Set @message = 'Cannot update: batch ' + Cast(@batchID As Varchar(12)) + ' does not exist in database'
                Set @myError = 50007
                Return @myError
            End

            If @locked = 'yes'
            Begin
                Set @message = 'Cannot update: batch is locked'
                Set @myError = 50008
                Return @myError
            End
        End

        ---------------------------------------------------
        -- Resolve user ID for owner username
        ---------------------------------------------------

        execute @userID = get_user_id @ownerUsername

        If @userID > 0
        Begin
            -- SP get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that @ownerUsername contains simply the username
            --
            SELECT @ownerUsername = U_PRN
            FROM T_Users
            WHERE ID = @userID
        End
        Else
        Begin
            -- Could not find entry in database for username @ownerUsername
            -- Try to auto-resolve the name

            Declare @matchCount int
            Declare @newUsername varchar(64)

            exec auto_resolve_name_to_username @ownerUsername, @matchCount output, @newUsername output, @userID output

            If @matchCount = 1
            Begin
                -- Single match found; update @ownerUsername
                Set @ownerUsername = @newUsername
            End
            Else
            Begin
                Set @message = 'Could not find entry in database for username "' + @ownerUsername + '"'
                Set @myError = 50009
                Return @myError
            End
        End

        ---------------------------------------------------
        -- Verify @batchGroupID
        ---------------------------------------------------

        If Coalesce(@batchGroupID, 0) = 0
        Begin
            Set @batchGroupID = Null
            Set @batchGroupOrder = Null
        End

        If @batchGroupID > 0 And Not Exists (Select * From T_Requested_Run_Batch_Group Where Batch_Group_ID = @batchGroupID)
        Begin
            Set @message = 'Requested run batch group does not exist: ' + Cast(@batchGroupID As varchar(12))
            Set @myError = 50010
            Return @myError
        End

        If @batchGroupID > 0 And IsNull(@batchGroupOrder, 0) < 1
        Begin
            Set @batchGroupOrder = 1
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'validate_requested_run_batch_params'
    END CATCH

    Return @myError

GO

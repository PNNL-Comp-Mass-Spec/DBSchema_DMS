/****** Object:  StoredProcedure [dbo].[ValidateRequestedRunBatchParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateRequestedRunBatchParams]
/****************************************************
**
**  Desc: Validates values for creating/updating a requested run batch
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/29/2021 mem - Refactored code from AddUpdateRequestedRunBatch
**          05/31/2021 mem - Add support for @mode = 'PreviewAdd'
**          02/14/2023 mem - Rename username and requested instrument group parameters
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
    @requestedInstrumentGroup varchar(64),      -- Will typically contain an instrument group, not an instrument name; could also contain "(lookup)"
    @comment varchar(512),
    @mode varchar(12) = 'add',                  -- 'add' or 'update' or 'PreviewAdd'
    @instrumentGroupToUse varchar(64) output,   -- Output: Actual instrument group
    @userID int output,                         -- Output: user_id for @ownerUsername
    @message varchar(512) = '' output
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    BEGIN TRY
        Set @name = LTrim(RTrim(IsNull(@name, '')))
        Set @description = IsNull(@description, '')
        Set @message = ''

        If Len(@name) < 1
        Begin
            Set @message = 'Must define a batch name'
            Set @myError = 50000
            return @myError
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
                return @myError
            End
        End

        ---------------------------------------------------
        -- Determine the Instrument Group
        ---------------------------------------------------

        -- Set the instrument group to @requestedInstrument for now
        Set @instrumentGroupToUse = @requestedInstrumentGroup

        If NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @instrumentGroupToUse)
        Begin
            -- Try to update instrument group using T_Instrument_Name
            SELECT @instrumentGroupToUse = IN_Group
            FROM T_Instrument_Name
            WHERE IN_Name = @requestedInstrumentGroup
        End

        ---------------------------------------------------
        -- High priority requires justification
        ---------------------------------------------------
        --
        If @requestedBatchPriority = 'High' AND ISNULL(@justificationHighPriority, '') = ''
        Begin
            Set @message = 'Justification must be entered If high priority is being requested'
            Set @myError = 50002
            return @myError
        End

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If @mode In ('add', 'PreviewAdd')
        Begin
            If Exists (SELECT * FROM T_Requested_Run_Batches WHERE Batch = @name)
            Begin
                Set @message = 'Cannot add batch: "' + @name + '" already exists in database'
                Set @myError = 50003
                return @myError
            End
        End

        -- Cannot update a non-existent entry
        --
        If @mode = 'update'
        Begin
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
                Set @myError = 50004
                return @myError
            End

            If @myRowCount = 0
            Begin
                Set @message = 'Cannot update: entry does not exist in database'
                Set @myError = 50005
                return @myError
            End

            If @locked = 'yes'
            Begin
                Set @message = 'Cannot update: batch is locked'
                Set @myError = 50006
                return @myError
            End
        End

        ---------------------------------------------------
        -- Resolve user ID for owner PRN
        ---------------------------------------------------

        execute @userID = GetUserID @ownerUsername

        If @userID > 0
        Begin
            -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that @ownerPRN contains simply the username
            --
            SELECT @ownerUsername = U_PRN
            FROM T_Users
            WHERE ID = @userID
        End
        Else
        Begin
            -- Could not find entry in database for username @ownerPRN
            -- Try to auto-resolve the name

            Declare @matchCount int
            Declare @newPRN varchar(64)

            exec AutoResolveNameToPRN @ownerUsername, @matchCount output, @newPRN output, @userID output

            If @matchCount = 1
            Begin
                -- Single match found; update @ownerPRN
                Set @ownerUsername = @newPRN
            End
            Else
            Begin
                Set @message = 'Could not find entry in database for operator PRN "' + @ownerPRN + '"'
                Set @myError = 50007
                return @myError
            End
        End

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'ValidateRequestedRunBatchParams'
    END CATCH

    return @myError


GO

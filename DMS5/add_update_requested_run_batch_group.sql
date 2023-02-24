/****** Object:  StoredProcedure [dbo].[add_update_requested_run_batch_group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_requested_run_batch_group]
/****************************************************
**
**  Desc:   Adds new or edits existing requested run batch group
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   02/14/2023 - initial version
**
*****************************************************/
(
    @id int output,                         -- Batch Group ID to update if @mode is 'update'; otherwise, the ID of the newly created batch group
    @name varchar(50),                      -- Batch Group Name
    @description varchar(256),
    @requestedRunBatchList varchar(max),    -- Requested run batch IDs
    @ownerUsername varchar(64),
    @mode varchar(12) = 'add',              -- 'add', 'update', or 'PreviewAdd'
    @message varchar(512) Output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @logErrors tinyint = 0
    Declare @userID Int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'add_update_requested_run_batch_group', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @id = Coalesce(@id, 0)
    Set @name = Ltrim(Rtrim(Replace(Replace(@name, char(10), ' '), char(9), ' ')))
    Set @description = Coalesce(@description, '')
    Set @requestedRunBatchList = Coalesce(@requestedRunBatchList, '')
    Set @ownerUsername = Coalesce(@ownerUsername, '')
    Set @mode = Ltrim(Rtrim(Lower(Coalesce(@mode, ''))));

    If Len(@name) < 1
    Begin
        Set @message = 'Must define a batch group name'
        Set @myError = 50000
        RAISERROR (@message, 11, 1)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If @mode In ('add', 'PreviewAdd')
    Begin
        If Exists (SELECT * FROM T_Requested_Run_Batch_Group WHERE Batch_Group = @name)
        Begin
            Set @message = 'Cannot add batch group: "' + @name + '" already exists in database'
            Set @myError = 50003
            RAISERROR (@message, 11, 1)
        End
    End

    -- Cannot update a non-existent entry
    --
    If @mode = 'update'
    Begin
        If Not Exists (SELECT * FROM T_Requested_Run_Batch_Group WHERE Batch_Group_ID = @ID)
        Begin
            Set @message = 'Cannot update: entry does not exist in database'
            Set @myError = 50005
            RAISERROR (@message, 11, 1)
        End
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Resolve user ID for owner username
    ---------------------------------------------------

    execute @userID = GetUserID @ownerUsername

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @ownerUsername contains simply the username
        --
        SELECT @ownerUsername = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for @ownerUsername
        -- Try to auto-resolve the name

        Declare @matchCount int
        Declare @newPRN varchar(64)

        exec AutoResolveNameToPRN @ownerUsername, @matchCount output, @newPRN output, @userID output

        If @matchCount = 1
        Begin
            -- Single match found; update @ownerUsername
            Set @ownerUsername = @newPRN
        End
        Else
        Begin
            Set @logErrors = 0
            Set @message = 'Could not find entry in database for username "' + @ownerUsername + '"'
            Set @myError = 50007
            RAISERROR (@message, 11, 1)
        End
    End

    ---------------------------------------------------
    -- Create temporary table for batches in list
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_BatchIDs (
        EntryID Int Not Null,
        Batch_ID_Text varchar(128) Null,
        Batch_ID int Null,
        Batch_Group_Order Int Null
    )

    ---------------------------------------------------
    -- Populate temporary table from list
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_BatchIDs (EntryID, Batch_ID_Text)
    SELECT Min(EntryID), Value
    FROM dbo.udfParseDelimitedListOrdered(@requestedRunBatchList, ',', 0)
    GROUP BY Value
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to populate temporary table for batches'
        RAISERROR (@message, 11, 23)
    End

    ---------------------------------------------------
    -- Convert Batch IDs to integers
    ---------------------------------------------------
    --
    UPDATE #Tmp_BatchIDs
    SET Batch_ID = try_cast(Batch_ID_Text as int)

    If Exists (Select * FROM #Tmp_BatchIDs WHERE Batch_ID Is Null)
    Begin
        Declare @firstInvalid varchar(128)

        SELECT TOP 1 @firstInvalid = Batch_ID_Text
        FROM #Tmp_BatchIDs
        WHERE Batch_ID Is Null

        Set @logErrors = 0
        Set @message = 'Batch IDs must be integers, not names; first invalid item: ' + Coalesce(@firstInvalid, '')

        RAISERROR (@message, 11, 30)
    End

    ---------------------------------------------------
    -- Verify that batch IDs exist
    ---------------------------------------------------

    Declare @count Int = 0

    SELECT @count = count(*)
    FROM #Tmp_BatchIDs
    WHERE NOT (Batch_ID IN
    (
        SELECT ID
        FROM T_Requested_Run_Batches)
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed trying to check existence of batches in list'

        RAISERROR (@message, 11, 24)
    End

    If @count <> 0
    Begin

        Declare @invalidIDs varchar(64) = null

        SELECT @invalidIDs = Coalesce(@invalidIDs + ', ', '') + Batch_ID_Text
        FROM #Tmp_BatchIDs
        WHERE NOT (Batch_ID IN
        (
            SELECT ID
            FROM T_Requested_Run_Batches)
        )

        Set @logErrors = 0
        Set @message = 'Batch ID list contains batches that do not exist: ' + @invalidIDs

        RAISERROR (@message, 11, 25)
    End

    ---------------------------------------------------
    -- Update Batch_Group_Order in #Tmp_BatchIDs
    ---------------------------------------------------

    UPDATE #Tmp_BatchIDs
    SET Batch_Group_Order = RankQ.Batch_Group_Order
    FROM #Tmp_BatchIDs
         INNER JOIN ( SELECT Batch_ID,
                             Row_Number() OVER ( ORDER BY EntryID ) AS Batch_Group_Order
                      FROM #Tmp_BatchIDs ) RankQ
           ON #Tmp_BatchIDs.Batch_ID = RankQ.Batch_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @count = @myRowCount

    ---------------------------------------------------
    -- Action for preview mode
    ---------------------------------------------------
    --
    If @mode = 'PreviewAdd'
    Begin
        Set @message = 'Would create batch group "' + @name + '" with ' + Cast(@count As Varchar(12)) + ' batches'
        Return 0
    End

    -- Start transaction
    --
    Declare @transName varchar(32) = 'AddUpdateBatch'

    Begin transaction @transName

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin

        INSERT INTO T_Requested_Run_Batch_Group (
            Batch_Group,
            Description,
            Owner_User_ID
        ) VALUES (
            @name,
            @description,
            @userID
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed while adding new batch group'

            RAISERROR (@message, 11, 26)
        End

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

        -- As a precaution, query T_Requested_Run_Batch_Group using batch group name to make sure we have the correct batch group ID
        Declare @batchGroupIdConfirm int = 0

        SELECT @batchGroupIdConfirm = Batch_Group_ID
        FROM T_Requested_Run_Batch_Group
        WHERE Batch_Group = @name

        If @id <> Coalesce(@batchGroupIdConfirm, @id)
        Begin
            Declare @debugMsg varchar(512)
            Set @debugMsg = 'Warning: Inconsistent identity values when adding batch group ' + @name + ': Found ID ' +
                            Cast(@batchGroupIdConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' +
                            Cast(@id as varchar(12))

            exec PostLogEntry 'Error', @debugMsg, 'add_update_requested_run_batch_group'

            Set @id = @batchGroupIdConfirm
        End

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_Requested_Run_Batch_Group
        SET Batch_Group = @name,
            Description = @description,
            Owner_User_ID = @userID
        WHERE Batch_Group_ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed, Batch Group ID ' + Cast(@id As Varchar(12))
            RAISERROR (@message, 11, 27)
        End
    End -- update mode

    ---------------------------------------------------
    -- Update member batches
    ---------------------------------------------------

    If @mode In ('add', 'update')
    Begin
        If @id > 0
        Begin
            -- Remove any existing references to the batch group
            -- from requested run batches
            --
            UPDATE T_Requested_Run_Batches
            SET Batch_Group_ID = NULL
            WHERE Batch_Group_ID = @id AND
                  NOT T_Requested_Run_Batches.ID IN ( SELECT Batch_ID
                                                      FROM #Tmp_BatchIDs )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                Set @message = 'Failed trying to remove batch group reference from existing batches'
                RAISERROR (@message, 11, 28)
            End
        End

        -- Add a reference to this batch group to the batches in the list
        --
        UPDATE T_Requested_Run_Batches
        SET Batch_Group_ID = @id,
            Batch_Group_Order = Src.Batch_Group_Order
        FROM T_Requested_Run_Batches
             INNER JOIN #Tmp_BatchIDs Src
               ON T_Requested_Run_Batches.ID = Src.Batch_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Failed trying to add batch group reference to batches'
            RAISERROR (@message, 11, 29)
        End
    End

    commit transaction @transName

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
            Exec PostLogEntry 'Error', @message, 'add_update_requested_run_batch_group'
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_requested_run_batch_group] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_requested_run_batch_group] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_requested_run_batch_group] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_requested_run_batch_group] TO [Limited_Table_Write] AS [dbo]
GO

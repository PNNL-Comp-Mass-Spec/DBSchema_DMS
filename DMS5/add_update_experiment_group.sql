/****** Object:  StoredProcedure [dbo].[AddUpdateExperimentGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateExperimentGroup]
/****************************************************
**
**  Desc: Adds new or edits existing Experiment Group
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/11/2006
**          09/13/2011 grk - Added Researcher
**          11/10/2011 grk - Removed character size limit from experiment list
**          11/10/2011 grk - Added Tab field
**          02/20/2013 mem - Now reporting invalid experiment names
**          06/13/2017 mem - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/18/2017 mem - Disable logging certain messages to T_Log_Entries
**          12/06/2018 mem - Call UpdateExperimentGroupMemberCount to update T_Experiment_Groups
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          11/18/2022 mem - Rename parameter to @groupName
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @ID int output,
    @GroupType varchar(50),
    @groupName VARCHAR(128),                -- User-defined name for this experiment group (previously @tab)
    @Description varchar(512),
    @ExperimentList varchar(MAX),
    @ParentExp varchar(50),
    @Researcher VARCHAR(50),
    @mode varchar(12) = 'add',          -- 'add' or 'update'
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateExperimentGroup', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Resolve parent experiment name to ID
    ---------------------------------------------------

    Declare @ParentExpID Int = 0
    --
    If @ParentExp <> ''
    Begin

        SELECT @ParentExpID = Exp_ID
        FROM T_Experiments
        WHERE Experiment_Num = @ParentExp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @logErrors = 1
            Set @message = 'Error trying to find existing entry for Parent Exp_ID ' + Cast(@ParentExpID As Varchar(12))
            RAISERROR (@message, 10, 1)
            return 51004
        End
    End

    If @ParentExpID = 0
    Begin
        SELECT @ParentExpID = Exp_ID
        FROM T_Experiments
        Where Experiment_Num = 'Placeholder'

        If IsNull(@ParentExpID, 0) = 0
        Begin
            Set @logErrors = 1
            Set @message = 'Unable to determine the Exp_ID for the Placeholder experiment'
            RAISERROR (@message, 10, 1)
            return 51004
        End
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------
    Declare @tmp int

    If @mode = 'update'
    Begin
        -- Cannot update a non-existent entry
        --
        Set @tmp = 0
        --
        SELECT @tmp = Group_ID
        FROM  T_Experiment_Groups
        WHERE (Group_ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @logErrors = 1
            Set @message = 'Error trying to find existing entry for GroupID ' + Cast(@ID As Varchar(12))
            RAISERROR (@message, 10, 1)
            return 51004
        End

        If @tmp = 0
        Begin
            Set @message = 'Cannot update: GroupID does not exist in database: ' + Cast(@ID As Varchar(12))
            RAISERROR (@message, 10, 1)
            return 51004
        End
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Create temporary table for experiments in list
    ---------------------------------------------------
    --
    CREATE TABLE #XR (
        Experiment_Num varchar(50),
        Exp_ID         int
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to create temporary table #XR for experiments'
        RAISERROR (@message, 10, 1)
        return 51219
    End

    ---------------------------------------------------
    -- Populate temporary table from list
    ---------------------------------------------------
    --
    INSERT INTO #XR( Experiment_Num,
                     Exp_ID )
    SELECT cast(Item AS varchar(50)) AS Experiment_Num,
           0 AS Exp_ID
    FROM dbo.MakeTableFromList ( @ExperimentList )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to populate temporary table for experiments'
        RAISERROR (@message, 10, 1)
        return 51219
    End


    ---------------------------------------------------
    -- Resolve experiment name to ID in temp table
    ---------------------------------------------------

    UPDATE T
    SET T.Exp_ID = S.Exp_ID
    FROM #XR T
         INNER JOIN T_Experiments S
           ON T.Experiment_Num = S.Experiment_Num
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed trying to resolve experiment IDs'
        RAISERROR (@message, 10, 1)
        return 51219
    End

    ---------------------------------------------------
    -- Check status of prospective member experiments
    ---------------------------------------------------
    Declare @count int

    -- Do all experiments in list actually exist?
    --
    Set @count = 0
    --
    SELECT @count = count(*)
    FROM #XR
    WHERE Exp_ID = 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed trying to check existence of experiments in list'
        RAISERROR (@message, 10, 1)
        return 51219
    End

    If @count <> 0
    Begin
        Declare @InvalidExperiments varchar(256) = ''
        SELECT @InvalidExperiments = @InvalidExperiments + Experiment_Num + ','
        FROM #XR
        WHERE Exp_ID = 0

        -- Remove the trailing comma
        If @InvalidExperiments Like '%,'
            Set @InvalidExperiments = Substring(@InvalidExperiments, 1, Len(@InvalidExperiments)-1)

        Set @logErrors = 0
        Set @message = 'Experiment run list contains experiments that do not exist: ' + @InvalidExperiments
        RAISERROR (@message, 10, 1)
        return 51221
    End

    ---------------------------------------------------
    -- Resolve researcher PRN
    ---------------------------------------------------

    Declare @userID int
    execute @userID = GetUserID @researcher

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @researcher contains simply the username
        --
        SELECT @researcher = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for PRN @researcher
        -- Try to auto-resolve the name

        Declare @MatchCount int
        Declare @NewPRN varchar(64)

        exec AutoResolveNameToPRN @researcher, @MatchCount output, @NewPRN output, @userID output

        If @MatchCount = 1
        Begin
            -- Single match found; update @researcher
            Set @researcher = @NewPRN
        End
        Else
        Begin
            Set @logErrors = 0
            Set @message = 'Could not find entry in database for researcher PRN "' + @researcher + '"'
            RAISERROR (@message, 10, 1)
            return 51037
        End

    End

    ---------------------------------------------------
    -- Start transaction
    --
    Declare @transName varchar(32)
    Set @transName = 'AddUpdateExperimentGroup'
    Begin transaction @transName

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @Mode = 'add'
    Begin -- <add>

        INSERT INTO T_Experiment_Groups (
            EG_Group_Type,
            EG_Created,
            EG_Description,
            Parent_Exp_ID,
            Researcher,
            Group_Name
        ) VALUES (
            @GroupType,
            getdate(),
            @Description,
            @ParentExpID,
            @Researcher,
            @groupName
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            return 51007
        End

        -- Return ID of newly created entry
        --
        Set @ID = SCOPE_IDENTITY()

    End -- </add>

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @Mode = 'update'
    Begin -- <update>
        Set @myError = 0
        --

        UPDATE T_Experiment_Groups
        SET EG_Group_Type = @GroupType,
            EG_Description = @Description,
            Parent_Exp_ID = @ParentExpID,
            Researcher = @Researcher,
            Group_Name = @groupName
        WHERE (Group_ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Update operation failed: "' + @ID + '"'
            RAISERROR (@message, 10, 1)
            return 51004
        End
    End -- </update>

    ---------------------------------------------------
    -- Update member experiments
    ---------------------------------------------------

    If @mode = 'add' OR @mode = 'update'
    Begin -- <AddUpdateMembers>

        -- Remove any existing group members that are not in the temporary table
        --
        DELETE FROM T_Experiment_Group_Members
        WHERE (Group_ID = @ID) AND
              (Exp_ID NOT IN ( SELECT Exp_ID FROM #XR ))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Failed trying to remove members from group'
            RAISERROR (@message, 10, 1)
        return 51004
        End

        -- Add group members from temporary table that are not already members
        --
        INSERT INTO T_Experiment_Group_Members(
            Group_ID,
            Exp_ID
        )
        SELECT @ID,
               #XR.Exp_ID
        FROM #XR
        WHERE #XR.Exp_ID NOT IN ( SELECT Exp_ID
                                  FROM T_Experiment_Group_Members
                                  WHERE Group_ID = @ID )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Failed trying to add members to group'
            RAISERROR (@message, 10, 1)
            return 51004
        End

        -- Update MemberCount
        --
        Exec @myError = UpdateExperimentGroupMemberCount @groupID = @ID

        If @myError <> 0
        Begin
            rollback transaction @transName
            RAISERROR ('Failed trying to update MemberCount using UpdateExperimentGroupMemberCount', 10, 1)
            return 51005
        End

    End -- </AddUpdateMembers>

    commit transaction @transName

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentGroup] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentGroup] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentGroup] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentGroup] TO [Limited_Table_Write] AS [dbo]
GO

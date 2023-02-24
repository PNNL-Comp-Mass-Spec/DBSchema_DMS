/****** Object:  StoredProcedure [dbo].[delete_experiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_experiment]
/****************************************************
**
**  Desc:
**      Deletes given Experiment from the Experiment table
**      and all referencing tables.  Experiment may not
**      have any associated datasets or requested runs
**
**      Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/11/2004
**          06/16/2005 grk - added delete for experiment group members table
**          02/27/2006 grk - added delete for experiment group table
**          08/31/2006 jds - added check for requested runs (Ticket #199)
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user (Ticket #644)
**          02/26/2010 mem - Merged T_Requested_Run_History with T_Requested_Run
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2018 mem - Call update_experiment_group_member_count to update T_Experiment_Groups
**          09/10/2019 mem - Delete from T_Experiment_Plex_Members if mapped to Plex_Exp_ID
**                         - Prevent deletion if the experiment is a plex channel in T_Experiment_Plex_Members
**                         - Add @infoOnly
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @experimentName varchar(128),
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @experimentId int
    Declare @state int

    Declare @result int

    Set @experimentName = IsNull(@experimentName, '')
    Set @infoOnly = IsNull(@infoonly, 0)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_experiment', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Get ExperimentID and current state
    ---------------------------------------------------

    Set @experimentId = 0
    --
    SELECT @experimentId = Exp_ID
    FROM T_Experiments
    WHERE (Experiment_Num = @experimentName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0 or @experimentId = 0
    Begin
        set @message = 'Could not get Id for Experiment "' + @experimentName + '"'
        RAISERROR (@message, 10, 1)
        return 51140
    End

    ---------------------------------------------------
    -- Can't delete experiment that has any datasets
    ---------------------------------------------------
    --
    Declare @dsCount Int = 0
    --
    SELECT @dsCount = COUNT(*)
    FROM T_Dataset
    WHERE (Exp_ID = @experimentId)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Could not get dataset count for Experiment "' + @experimentName + '"'
        RAISERROR (@message, 10, 1)
        return 51141
    End
    --
    If @dsCount > 0
    Begin
        set @message = 'Cannot delete experiment that has associated datasets'
        RAISERROR (@message, 10, 1)
        return 51141
    End

    ---------------------------------------------------
    -- Can't delete experiment that has a requested run
    ---------------------------------------------------

    Declare @rrCount Int = 0
    --
    SELECT @rrCount = COUNT(*)
    FROM T_Requested_Run
    WHERE (Exp_ID = @experimentId)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Could not get requested run count for Experiment "' + @experimentName + '"'
        RAISERROR (@message, 10, 1)
        return 51142
    End
    --
    If @rrCount > 0
    Begin
        set @message = 'Cannot delete experiment that has associated requested runs'
        RAISERROR (@message, 10, 1)
        return 51142
    End

    ---------------------------------------------------
    -- Can't delete experiment that has requested run history
    ---------------------------------------------------

    Declare @rrhCount Int = 0
    --
    SELECT @rrhCount = COUNT(*)
    FROM T_Requested_Run
    WHERE (Exp_ID = @experimentId) AND NOT (DatasetID IS NULL)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Could not get requested run history count for Experiment "' + @experimentName + '"'
        RAISERROR (@message, 10, 1)
        return 51143
    End
    --
    If @rrhCount > 0
    Begin
        set @message = 'Cannot delete experiment that has associated requested run history'
        RAISERROR (@message, 10, 1)
        return 51143
    End

    ---------------------------------------------------
    -- Can't delete experiment that is mapped to a channel in a plex
    ---------------------------------------------------

    Declare @plexMemberCount Int = 0
    --
    SELECT @plexMemberCount = COUNT(*)
    FROM T_Experiment_Plex_Members
    WHERE (Exp_ID = @experimentId)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Could not get plex member count for Experiment "' + @experimentName + '"'
        RAISERROR (@message, 10, 1)
        return 51144
    End
    --
    If @plexMemberCount > 0
    Begin
        set @message = 'Cannot delete experiment that is mapped to a plex channel; see https://dms2.pnl.gov/experiment_plex_members_tsv/report/-/-/-/' + @experimentName + '/-/-/-'
        RAISERROR (@message, 10, 1)
        return 51144
    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'delete_experiment'

    Begin Transaction @transName

    ---------------------------------------------------
    -- Delete any entries for the Experiment from
    -- cell culture map table
    ---------------------------------------------------

    If @infoonly > 0
    Begin
        SELECT *
        FROM T_Experiment_Cell_Cultures
        WHERE Exp_ID = @experimentId
    End
    Else
    Begin
        DELETE FROM T_Experiment_Cell_Cultures
        WHERE Exp_ID = @experimentId
    End
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Delete from cell culture association table was unsuccessful',
            10, 1)
        return 51130
    End

    ---------------------------------------------------
    -- Delete any entries for the Experiment from
    -- experiment group map table
    ---------------------------------------------------

    Declare @groupID Int = 0

    SELECT @groupID = Group_ID
    FROM T_Experiment_Group_Members
    WHERE Exp_ID = @experimentId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @groupID > 0
    Begin
        If @infoonly > 0
        Begin
            SELECT *
            FROM T_Experiment_Group_Members
            WHERE Exp_ID = @experimentId
        End
        Else
        Begin
            DELETE FROM T_Experiment_Group_Members
            WHERE Exp_ID = @experimentId
        End
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            RAISERROR ('Delete from experiment group association table was unsuccessful',
                10, 1)
            return 51131
        End

        If @infoonly = 0
        Begin
            -- Update MemberCount
            --
            Exec @myError = update_experiment_group_member_count @groupID = @groupID

            If @myError <> 0
            Begin
                rollback transaction @transName
                RAISERROR ('Failed trying to update MemberCount', 10, 1)
                return 51132
            End
        End
    End

    ---------------------------------------------------
    -- Remove any reference to this experiment as a
    -- parent experiment in the experiment groups table
    ---------------------------------------------------

    If @infoonly > 0
    Begin
        SELECT *
        FROM T_Experiment_Groups
        WHERE Parent_Exp_ID = @experimentId
    End
    Else
    Begin
        UPDATE T_Experiment_Groups
        SET Parent_Exp_ID = 15
        WHERE Parent_Exp_ID = @experimentId
    End
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Resetting parent experiment from experiment group table was unsuccessful',
            10, 1)
        return 51134
    End

    ---------------------------------------------------
    -- Delete experiment plex info
    ---------------------------------------------------

    If @infoonly > 0
    Begin
        SELECT *
        FROM T_Experiment_Plex_Members
        WHERE Plex_Exp_ID = @experimentId
    End
    Else
    Begin
        DELETE FROM T_Experiment_Plex_Members
        WHERE Plex_Exp_ID = @experimentId
    End
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Delete from experiment plex members table was unsuccessful',
            10, 1)
        return 51135
    End

    If @infoonly > 0
    Begin
        Select 'exec delete_aux_info for ' + @experimentName
    End
    Else
    Begin
        ---------------------------------------------------
        -- Delete any auxiliary info associated with Experiment
        ---------------------------------------------------

        exec @result = delete_aux_info 'Experiment', @experimentName, @message output

        If @result <> 0
        Begin
            rollback transaction @transName
            set @message = 'Delete auxiliary information was unsuccessful for Experiment: ' + @message
            RAISERROR (@message, 10, 1)
            return 51136
        End
    End

    ---------------------------------------------------
    -- Delete experiment from experiment table
    ---------------------------------------------------

    If @infoonly > 0
    Begin
        SELECT *
        FROM T_Experiments
        WHERE Exp_ID = @experimentId
    End
    Else
    Begin
        DELETE FROM T_Experiments
        WHERE Exp_ID = @experimentId
    End
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Delete from Experiments table was unsuccessful',
            10, 1)
        return 51130
    End

    -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
    If @infoonly = 0 And Len(@callingUser) > 0
    Begin
        Declare @stateID Int = 0

        Exec alter_event_log_entry_user 3, @experimentId, @stateID, @callingUser
    End

    commit transaction @transName

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[delete_experiment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_experiment] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_experiment] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_experiment] TO [Limited_Table_Write] AS [dbo]
GO

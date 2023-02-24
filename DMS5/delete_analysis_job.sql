/****** Object:  StoredProcedure [dbo].[DeleteAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteAnalysisJob]
/****************************************************
**
**  Desc:   Deletes given analysis job from the analysis job table
**          and all referencing tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/06/2001
**          06/09/2004 grk - added delete for analysis job request reference
**          04/07/2006 grk - eliminated job to request map table
**          02/20/2007 grk - added code to remove any job-to-group associations
**          03/16/2007 mem - Fixed bug that required 1 or more rows be deleted from T_Analysis_Job_Processor_Group_Associations (Ticket #393)
**          02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**          12/31/2008 mem - Now calling DMS_Pipeline.dbo.DeleteJob
**          02/19/2008 grk - Modified not to call broker DB (Ticket #723)
**          05/28/2015 mem - No longer deleting processor group entries
**          03/08/2017 mem - Delete jobs in the DMS_Pipeline database if they are new, holding, or failed
**          04/21/2017 mem - Added parameter @previewMode
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/27/2018 mem - Rename @previewMode to @infoonly
**          08/18/2020 mem - Delete jobs from T_Reporter_Ion_Observation_Rates
**
*****************************************************/
(
    @jobNum varchar(32),
    @callingUser varchar(128) = '',
    @infoonly tinyint = 0
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @jobNum = IsNull(@jobNum, '')
    Set @infoonly = IsNull(@infoonly, 0)

    Declare @message varchar(512)
    Declare @msg varchar(128)

    Declare @jobID int = Try_Cast(@jobNum as int)

    If @jobID is null
    Begin
        Set @msg = 'Job number is not numeric: ' + @jobNum
        RAISERROR (@msg, 10, 1)
        return 54449
    End

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'DeleteAnalysisJob', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -------------------------------------------------------
    -- Validate that the job exists
    -------------------------------------------------------
    --
    If Not Exists (SELECT * FROM T_Analysis_Job WHERE AJ_jobID = @jobID)
    Begin
        Set @msg = 'Job not found; nothing to delete: ' + @jobNum
        If @infoonly > 0
            Print @msg
        Else
        Begin
            RAISERROR (@msg, 10, 1)
            return 54450
        End
    End

    If @infoonly > 0
    Begin
        SELECT 'To be deleted' as Action, *
        FROM T_Analysis_Job
        WHERE (AJ_jobID = @jobID)
    End
    Else
    Begin
        -------------------------------------------------------
        -- Start transaction
        -------------------------------------------------------
        --
        Declare @transName varchar(32) = 'DeleteAnalysisJob'
        Begin transaction @transName


        -------------------------------------------------------
        -- Delete the job from T_Reporter_Ion_Observation_Rates (if it exists)
        -------------------------------------------------------
        --
        DELETE FROM T_Reporter_Ion_Observation_Rates
        WHERE Job = @jobID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -------------------------------------------------------
        -- Delete the job from T_Analysis_Job
        -------------------------------------------------------
        --
        DELETE FROM T_Analysis_Job
        WHERE (AJ_jobID = @jobID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 or @myRowCount = 0
        Begin
            rollback transaction @transName
            RAISERROR ('Delete job operation failed', 10, 1)
            return 54451
        End

        Print 'Deleted analysis job ' + Cast(@jobID As varchar(12)) + ' from T_Analysis_Job in DMS5'

        -------------------------------------------------------
        -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        -------------------------------------------------------
        --
        If Len(@callingUser) > 0
        Begin
            Declare @stateID int
            Set @stateID = 0

            Exec AlterEventLogEntryUser 5, @jobID, @stateID, @callingUser
        End

        commit transaction @transName
    End

    -------------------------------------------------------
    -- Also delete from the DMS_Pipeline database if the state is New, Failed, or Holding
    -- Ignore any jobs with running job steps (though if the step started over 48 hours ago, ignore that job step)
    -------------------------------------------------------
    --
    exec S_DeleteJobIfNewOrFailed @jobID, @callingUser, @message output, @infoonly

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisJob] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJob] TO [Limited_Table_Write] AS [dbo]
GO

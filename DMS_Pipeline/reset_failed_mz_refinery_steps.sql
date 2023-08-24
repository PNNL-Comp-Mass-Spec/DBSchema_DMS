/****** Object:  StoredProcedure [dbo].[reset_failed_mz_refinery_steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reset_failed_mz_refinery_steps]
/****************************************************
**
**  Desc:
**      Resets Mz_Refinery in-progress job steps if a manager reports "flag file exists" in T_Log_Entries (in DMS5)
**
**      This procedure runs on a regular basis to look for cases where the Analysis Manager crashed while running Mz_Refinery (using Java)
**      In addition to a "flag file" message, there must be an in-progress Mz_Refinery job step reporting a Job Progress of 0 %
**
**  Auth:   mem
**          08/23/2023 mem - Initial version
**          08/24/2023 mem - Remove unused column from temp table and log a warning if no rows are updated
**
*****************************************************/
(
    @infoOnly tinyint = 1,                              -- 1 to preview the changes
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @continue tinyint
    Declare @entryID int
    Declare @job int
    Declare @step int
    Declare @processor varchar(128)
    Declare @entryIdMin int
    Declare @baseMsg varchar(256)

    BEGIN TRY

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    -----------------------------------------------------------
    -- Create a temporary table for the query results
    -----------------------------------------------------------

    CREATE TABLE #Tmp_Managers (
        Entry_ID int Identity(1,1),
        Manager_Description varchar(256) Not Null,
        Manager_Name varchar(128) Null,
        Entry_ID_Min int
    )

    -----------------------------------------------------------
    -- Find managers that have recently reported 'flag file exists'
    -- (for example: Pub-15: Flag file exists in directory AnalysisToolManager5)
    -----------------------------------------------------------

    INSERT INTO #Tmp_Managers (Manager_Description, Manager_Name, Entry_ID_Min)
    SELECT posted_by, Null, MIN(Entry_ID) As Entry_ID_Min
    FROM S_DMS_T_Log_Entries
    WHERE Entered >= DateAdd(hour, -48, GETDATE()) AND
          type = 'Error' AND
          posted_by LIKE 'Analysis Tool Manager%' AND
          message LIKE '%flag file exists%'
    GROUP BY posted_by
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Did not find any flag file errors in T_Log_Entries in DMS5; nothing to reset'

        If @infoOnly > 0
        Begin
            SELECT @message As Message
        End

        RETURN
    End

    -----------------------------------------------------------
    -- Determine the manager name
    -----------------------------------------------------------

    UPDATE #Tmp_Managers
    SET Manager_Name = LTrim(RTrim(SUBSTRING(Manager_Description, CHARINDEX(':', Manager_Description) + 1, 128)))
    WHERE CHARINDEX(':', Manager_Description) > 0

    If Exists (SELECT * FROM #Tmp_Managers WHERE Manager_Name Is Null)
    Begin
        Set @message = 'Warning: one or more log entries did not have a colon in the manager description; they will be ignored'
        SELECT @message As Message
    End

    -----------------------------------------------------------
    -- Look for job steps to reset
    -----------------------------------------------------------

    CREATE TABLE #Tmp_Job_Steps_to_Reset (
        Entry_ID int Identity(1,1),
        Job int,
        Step int,
        Processor varchar(128),
        Entry_ID_Min int
    )

    INSERT INTO #Tmp_Job_Steps_to_Reset (Job, Step, Processor, Entry_ID_Min)
    SELECT JS.Job,
           JS.Step,
           JS.Processor,
           M.Entry_ID_Min
    FROM T_Job_Steps JS
         INNER JOIN #Tmp_Managers M
           ON JS.Processor = M.Manager_Name
         INNER JOIN T_Processor_Status Status
           ON M.Manager_Name = Status.Processor_Name
    WHERE JS.State = 4 AND
          JS.Tool = 'Mz_Refinery' AND
          JS.Start < DATEADD(minute, -15, GetDate()) AND
          Status.Progress < 0.1
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        -- Did not find any job steps to reset

        If @infoOnly > 0
        Begin
            Set @message = 'T_Log_Entries in DMS5 has flag file error messages, but there are no corresponding running Mz_Refinery job steps'
            SELECT @message As Message

            SELECT *
            FROM #Tmp_Managers
            ORDER BY Manager_Description
        End

        RETURN
    End

    -----------------------------------------------------------
    -- Process each entry in #Tmp_Job_Steps_To_Reset
    -----------------------------------------------------------

    Set @continue = 1
    Set @entryID = 0

    While @continue = 1
    Begin
        SELECT TOP 1 @entryID = Entry_ID,
                     @job = Job,
                     @step = Step,
                     @processor = Processor,
                     @entryIdMin = Entry_ID_Min
        FROM #Tmp_Job_Steps_to_Reset
        WHERE Entry_ID > @entryID
        ORDER BY Entry_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin
            Set @baseMsg = 'Mz_Refinery for Job ' + Cast(@job As varchar(9)) + ', step ' + Cast(@step As varchar(9)) + ', since processor ' + @processor + ' crashed'

            If @infoOnly > 0
            Begin
                Set @message = 'Would reset ' + @baseMsg
                SELECT @message As Message
            End
            Else
            Begin
                -----------------------------------------------------------
                -- Reset the step state back to 2 (enabled)
                -----------------------------------------------------------

                UPDATE T_Job_Steps
                SET State = 2
                WHERE Job = @job AND Step = @step AND State = 4
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    Set @message = 'Attempted to reset ' + @baseMsg + ', but no rows were updated; this is unexpected'
                    Exec post_log_entry 'Warning', @message, 'reset_failed_mz_refinery_steps'
                End
                Else
                Begin
                    Set @message = 'Reset ' + @baseMsg
                    Exec post_log_entry 'Warning', @message, 'reset_failed_mz_refinery_steps'

                    -----------------------------------------------------------
                    -- Set the manager's cleanup mode to 1
                    -----------------------------------------------------------

                    exec @myError = s_mc_set_manager_error_cleanup_mode @processor, @CleanupMode=1, @showTable=1, @infoOnly=0

                    -----------------------------------------------------------
                    -- Update T_Log_Entries to change the log type from 'Error' to 'ErrorAutoFixed'
                    -----------------------------------------------------------

                    UPDATE S_DMS_T_Log_Entries
                    SET type = 'ErrorAutoFixed'
                    WHERE type = 'Error' And Entry_ID = @entryIdMin

                    UPDATE S_DMS_T_Log_Entries
                    SET type = 'ErrorIgnore'
                    WHERE Entered >= DateAdd(hour, -48, GETDATE()) AND
                          type = 'Error' AND
                          posted_by = 'Analysis Tool Manager: ' + @processor AND
                          message LIKE '%flag file exists%'

                End
            End
        End
    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'reset_failed_mz_refinery_steps'
    END CATCH

    Return @myError

GO

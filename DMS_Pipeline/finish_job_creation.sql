/****** Object:  StoredProcedure [dbo].[finish_job_creation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[finish_job_creation]
/****************************************************
**
**  Desc:
**      Perform a mixed bag of operations on the jobs
**      in the temporary tables to finalize them before
**      copying to the main database tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/31/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/06/2009 grk - added code for: Special="Job_Results"
**          07/31/2009 mem - Now filtering by job in the subquery that looks for job steps with flag Special="Job_Results" (necessary when #Job_Steps contains more than one job)
**          03/21/2011 mem - Added support for Special="ExtractSourceJobFromComment"
**          03/22/2011 mem - Now calling add_update_job_parameter_temp_table
**          04/04/2011 mem - Removed SourceJob code since needs to occur after T_Job_Parameters has been updated for this job
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/13/2023 mem - Update Special="Job_Results" comment to mention ProMex
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in temporary tables
**
*****************************************************/
(
    @job int,
    @message varchar(512) output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Update step dependency count
    ---------------------------------------------------
    --
    UPDATE #Job_Steps
    SET Dependencies = T.dependencies
    FROM #Job_Steps
         INNER JOIN ( SELECT Step,
                             COUNT(*) AS dependencies
                      FROM #Job_Step_Dependencies
                      WHERE (Job = @job)
                      GROUP BY Step
                    ) AS T
           ON T.Step = #Job_Steps.Step
    WHERE #Job_Steps.Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        set @message = 'Error updating job step dependency count'
        goto Done
    End

    ---------------------------------------------------
    -- Initialize the input folder to an empty string
    -- for steps that have no dependencies
    ---------------------------------------------------
    --
    UPDATE #Job_Steps
    SET Input_Folder_Name = ''
    FROM #Job_Steps
    WHERE Job = @job AND
          Dependencies = 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        set @message = 'Error setting default input folder names'
        goto Done
    End

    ---------------------------------------------------
    -- Set results folder name for the job to be that of
    --  the output folder for any step designated as
    --  Special="Job_Results"
    --
    -- This will only affect jobs that have a step with
    --  the Special_Instructions = 'Job_Results' attribute
    --
    -- Scripts MSXML_Gen, DTA_Gen, and ProMex use this since they
    --   produce a shared results folder, yet we also want
    --   the results folder for the job to show the shared results folder name
    ---------------------------------------------------
    --
    UPDATE #Jobs
    SET Results_Folder_Name = TZ.Output_Folder_Name
    FROM #Jobs INNER JOIN
        (
            SELECT TOP 1 Job, Output_Folder_Name
            FROM #Job_Steps
            WHERE Job = @job AND
                  Special_Instructions = 'Job_Results'
            ORDER BY Step
        ) TZ ON #Jobs.Job = TZ.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Set job to initialized state ("New")
    ---------------------------------------------------
    --
    UPDATE #Jobs
    SET State = 1
    WHERE Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        set @message = 'Error updating job state'
        goto Done
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[finish_job_creation] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[finish_job_creation] TO [Limited_Table_Write] AS [dbo]
GO

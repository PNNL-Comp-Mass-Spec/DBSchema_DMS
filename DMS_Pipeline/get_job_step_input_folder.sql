/****** Object:  StoredProcedure [dbo].[get_job_step_input_folder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_job_step_input_folder]
/****************************************************
**
**  Desc:   Returns the input folder for a given job and optionally job step
**          Useful for determining the input folder for MSGF+ or MzRefinery
**          Use @jobStep and/or @stepToolFilter to specify which job step to target
**
**          If @jobStep is 0 (or null) and @stepToolFilter is '' (or null) preferentially returns
**          the input folder for the primary step tool used by a job (e.g. MSGFPlus)
**
**          First looks for completed job steps in T_Job_Steps
**          If no match, looks in T_Job_Steps_History
**
**  Auth:   mem
**  Date:   02/02/2017 mem - Initial release
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**
*****************************************************/
(
    @job int,                                   -- Job to search
    @jobStep int = null,                        -- Optional job step; 0 or null to use the folder associated with the highest job step
    @stepToolFilter varchar(64) = null,         -- Optional filter, like Mz_Refinery or MSGFPlus
    @inputFolderName varchar(128) = '' output,      -- Matched InputFolder, or '' if no match
    @stepToolMatch varchar(64) = '' output
)
AS
    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @message varchar(512)
    set @message  = ''

    Set @job = IsNull(@job, 0)
    Set @jobStep = IsNull(@jobStep, 0)
    Set @stepToolFilter = IsNull(@stepToolFilter, '')
    Set @inputFolderName = ''
    Set @stepToolMatch = ''

    ---------------------------------------------------
    -- First look in T_Job_Steps
    ---------------------------------------------------
    --
    SELECT TOP 1 @inputFolderName = Input_Folder_Name,
                 @stepToolMatch = Tool
    FROM T_Job_Steps JS
         INNER JOIN T_Step_Tools Tools
           ON JS.Tool = Tools.Name
    WHERE NOT Tool IN ('Results_Transfer') AND
          Job = @job AND
          (@jobStep <= 0 OR
           Step = @jobStep) AND
          (@stepToolFilter = '' OR
           Tool = @stepToolFilter)
    ORDER BY Tools.Primary_Step_Tool DESC, Step DESC
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        -- No match; try T_Job_Steps_History
        SELECT TOP 1 @inputFolderName = Input_Folder_Name,
                     @stepToolMatch = Tool
        FROM T_Job_Steps_History JS
             INNER JOIN T_Step_Tools Tools
               ON JS.Tool = Tools.Name
        WHERE NOT Tool IN ('Results_Transfer') AND
              Job = @job AND
              (@jobStep <= 0 OR
               Step = @jobStep) AND
              (@stepToolFilter = '' OR
               Tool = @stepToolFilter)
        ORDER BY Tools.Primary_Step_Tool DESC, Step DESC
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End

    RETURN

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_step_input_folder] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_job_step_input_folder] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_job_step_input_folder] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_job_step_input_folder] TO [svc-dms] AS [dbo]
GO

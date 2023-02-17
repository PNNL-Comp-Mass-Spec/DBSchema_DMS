/****** Object:  StoredProcedure [dbo].[update_job_parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_job_parameters]
/****************************************************
**
**  Desc:
**      Updates the parameters in T_Job_Parameters for the specified job
**
**
**  Note:   The job parameters come from the DMS5 database (via create_parameters_for_job
**          and then get_job_param_table), and not from the T_Job_Parameters table local to this DB
**
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   01/24/2009
**          02/08/2009 grk - Modified to call create_parameters_for_job
**          01/05/2010 mem - Added parameter @SettingsFileOverride
**          03/21/2011 mem - Now calling UpdateInputFolderUsingSourceJobComment
**          04/04/2011 mem - Now calling update_input_folder_using_special_processing_param
**          01/11/2012 mem - Updated to support @pXML being null, which will be the case for a job created directly in the pipeline database
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @infoOnly tinyint = 0,
    @settingsFileOverride varchar(256) = '',    -- When defined, then will use this settings file name instead of the one obtained with V_DMS_PipelineJobParameters (in get_job_param_table)
    @message varchar(128) = '' Output
)
AS
    Set NoCount On

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    ----------------------------------------------
    -- Validate the inputs
    ----------------------------------------------
    If @job Is Null
    Begin
        Set @message = '@job cannot be null'
        Set @myError = 50001
        Goto done
    End

    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @SettingsFileOverride = IsNull(@SettingsFileOverride, '')
    Set @message = ''

    -- Make sure @job exists in T_Jobs
    If Not Exists (SELECT * FROM T_Jobs WHERE Job = @job)
    Begin
        Set @message = 'Job ' + Convert(varchar(12), @job) + ' not found in T_Jobs'
        Set @myError = 50002
        Goto done
    End

    ----------------------------------------------
    -- Get the job parameters as XML
    ----------------------------------------------

    CREATE TABLE #Job_Parameters (
        [Job] int NOT NULL,
        [Parameters] xml NULL
    )

    declare @pXML xml
    declare @DebugMode tinyint
    set @DebugMode = @infoOnly

    exec @myError = create_parameters_for_job
                            @job,
                            @pXML output,
                            @message output,
                            @SettingsFileOverride = @SettingsFileOverride,
                            @DebugMode = @DebugMode

    If @infoOnly <> 0
    Begin
        SELECT NewParams.Job,
               IsNull(NewParams.Parameters, CurrentParams.Parameters) AS Parameters
        FROM #Job_Parameters NewParams
             LEFT OUTER JOIN T_Job_Parameters CurrentParams
               ON NewParams.Job = CurrentParams.Job
    End
    Else
    Begin
        -- Update T_Job_Parameters (or insert a new row if the job isn't present)
        --
        If Exists (SELECT * FROM T_Job_Parameters WHERE Job = @Job)
            UPDATE T_Job_Parameters
            SET Parameters = IsNull(@pXML, Parameters)
            WHERE Job = @Job
        Else
            INSERT INTO T_Job_Parameters (Job,Parameters)
            VALUES (@Job, @pXML)
        --
        SELECT @myError = @@error, @myRowCount = @@RowCount

        If @myError <> 0
        Begin
            Set @message = 'Error updating parameter table'
            Goto Done
        End
    End

    ----------------------------------------------
    -- Possibly update the input folder using the
    -- Special_Processing param in the job parameters
    ----------------------------------------------

    Declare @ShowResults int
    If @infoOnly > 0
        Set @ShowResults = 1
    Else
        Set @ShowResults = 0

    exec dbo.update_input_folder_using_special_processing_param @JobList = @Job, @infoOnly=@infoOnly, @ShowResults=@ShowResults

Done:
    If @myError <> 0 AND @infoOnly <> 0
        SELECT @message as Message

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_job_parameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_job_parameters] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_job_parameters] TO [Limited_Table_Write] AS [dbo]
GO

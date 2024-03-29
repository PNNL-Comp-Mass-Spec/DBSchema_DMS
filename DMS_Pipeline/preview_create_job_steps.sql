/****** Object:  StoredProcedure [dbo].[preview_create_job_steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[preview_create_job_steps]
/****************************************************
**
**  Desc:
**    Previews the job steps that would be created
**      If @JobToPreview = 0, then previews the steps for any jobs with state = 0 in T_Jobs
**          Generally, there won't be any jobs with a state of 0, since SP update_context runs once per minute,
**          and it calls create_job_steps to create steps for any jobs with state = 0, after which the job state is changed to 1
**
**      If @JobToPreview is non-zero, then previews the steps for the given job in T_Jobs (regardless of its state)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          02/08/2009 mem - Initial version
**          03/11/2009 mem - Updated call to create_job_steps (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          03/21/2011 mem - Now passing @InfoOnly=1 to create_job_steps
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobToPreview int = 0,
    @message varchar(512) ='' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @StepCount int
    declare @StepCountNew int
    set @StepCount= 0
    set @StepCountNew = 0

    Set @message = ''
    Set @JobToPreview = IsNull(@JobToPreview, 0)

    exec create_job_steps @message = @message output, @existingJob=@JobToPreview, @InfoOnly=1, @DebugMode=1

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[preview_create_job_steps] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[preview_create_job_steps] TO [Limited_Table_Write] AS [dbo]
GO

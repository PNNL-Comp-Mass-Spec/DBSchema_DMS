/****** Object:  StoredProcedure [dbo].[UnholdRepoPkgJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UnholdRepoPkgJobs]
/****************************************************
**
**  Desc:
**  Add a MAC job from job template
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   mem
**  Date:   04/10/2013 mem - Initial version
**
*****************************************************/
(
    @maxRunningRepoJobs int = 3,
    @message VARCHAR(512)='' output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Look for running RepoPkgr jobs
    ---------------------------------------------------

    declare @jobs int
    SELECT @Jobs= COUNT(*)
    FROM V_Job_Steps
    WHERE (Tool = 'RepoPkgr') AND (State = 4)

    If @jobs < @maxRunningRepoJobs
    Begin
        ---------------------------------------------------
        -- Look for a job to unpause
        ---------------------------------------------------

        declare @JobToUnpause int = 0

        SELECT top 1 @JobToUnpause = Job
        FROM V_Job_Steps
        WHERE (Tool = 'RepoPkgr') AND (State = 7)
        ORDER BY Job

        If ISNULL(@JobToUnpause, 0) > 0
        Begin
            Set @message = 'Un-holding job ' + CONVERT(varchar(12), @JobToUnpause)

            UPDATE V_Job_Steps
            SET State = 2
            WHERE State = 7 And Job = @JobToUnpause

        End
    End


GO
GRANT VIEW DEFINITION ON [dbo].[UnholdRepoPkgJobs] TO [DDL_Viewer] AS [dbo]
GO

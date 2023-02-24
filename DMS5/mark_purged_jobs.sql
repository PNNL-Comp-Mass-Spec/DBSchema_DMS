/****** Object:  StoredProcedure [dbo].[mark_purged_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[mark_purged_jobs]
/****************************************************
**
**  Desc:   Updates AJ_Purged to be 1 for the jobs in @JobList
**          This procedure is called by the SpaceManager
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/13/2012
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobList varchar(4000),
    @infoOnly tinyint = 1
)
AS
    Set nocount on

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    ---------------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------------
    --

    Set @JobList = IsNull(@JobList, '')
    Set @InfoOnly = IsNull(@InfoOnly, 0)

    ---------------------------------------------------------
    -- Populate a temporary table with the jobs in @JobList
    ---------------------------------------------------------
    --
    CREATE TABLE #Tmp_JobList (
        Job int
    )

    INSERT INTO #Tmp_JobList (Job)
    SELECT Value
    FROM dbo.parse_delimited_integer_list(@JobList, ',')

    If @InfoOnly <> 0
    Begin
        -- Preview the jobs
        --
        SELECT J.AJ_JobID AS Job, J.AJ_Purged as Job_Purged
        FROM T_Analysis_Job J INNER JOIN
             #Tmp_JobList L ON J.AJ_JobID = L.Job
        ORDER BY AJ_JobID
    End
    Else
    Begin
        -- Update AJ_Purged
        --
        UPDATE T_Analysis_Job
        SET AJ_Purged = 1
        FROM T_Analysis_Job J INNER JOIN
             #Tmp_JobList L ON J.AJ_JobID = L.Job
        WHERE J.AJ_Purged = 0

    End

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[mark_purged_jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[mark_purged_jobs] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[mark_purged_jobs] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[mark_purged_jobs] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[mark_purged_jobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[mark_purged_jobs] TO [svc-dms] AS [dbo]
GO

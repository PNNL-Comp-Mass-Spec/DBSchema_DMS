/****** Object:  StoredProcedure [dbo].[find_existing_jobs_for_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[find_existing_jobs_for_request]
/****************************************************
**
**  Desc:  Check how many existing jobs already exist that match the settings for the given job request
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   12/05/2005 grk - Initial version
**          04/07/2006 grk - Eliminated job to request map table
**          09/10/2007 mem - Now returning columns Processor and Dataset
**          04/09/2008 mem - Now returning associated processor group, if applicable
**          09/03/2008 mem - Fixed bug that returned Entered_By from T_Analysis_Job_Processor_Group instead of from T_Analysis_Job_Processor_Group_Associations
**          05/28/2015 mem - Removed reference to T_Analysis_Job_Processor_Group
**          07/30/2019 mem - After obtaining the actual matching jobs using GetRunRequestExistingJobListTab, compare to the cached values in T_Analysis_Job_Request_Existing_Jobs; call update_cached_job_request_existing_jobs if a mismatch
**          07/31/2019 mem - Use new function name, get_existing_jobs_matching_job_request
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/25/2023 bcg - Update output table column names to lower-case
**
*****************************************************/
(
    @requestID int,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @cachedCount int = 0
    Declare @misMatchCount Int = 0

    Set @message = ''

    Create Table #Tmp_ExistingJobs (
        Job Int Not null
    )

    INSERT INTO #Tmp_ExistingJobs( Job )
    SELECT Job
    FROM dbo.get_existing_jobs_matching_job_request ( @requestID )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -- See if T_Analysis_Job_Request_Existing_Jobs needs to be updated
    SELECT @cachedCount = Count(*)
    FROM T_Analysis_Job_Request_Existing_Jobs
    WHERE Request_ID = @requestID

    If @cachedCount <> @myRowCount
    Begin
        Print 'Calling update_cached_job_request_existing_jobs due to differing count'
        Exec update_cached_job_request_existing_jobs @processingMode = 0, @requestId = @requestId, @infoOnly = 0
    End
    Else
    Begin
        SELECT @misMatchCount = Count(*)
        FROM #Tmp_ExistingJobs J
        Left Outer Join T_Analysis_Job_Request_Existing_Jobs AJR
               ON AJR.Job = J.Job And AJR.Request_ID = @requestID
        WHERE AJR.Job Is null

        If @misMatchCount > 0
        Begin
            Print 'Calling update_cached_job_request_existing_jobs due to differing jobs'
            Exec update_cached_job_request_existing_jobs @processingMode = 0, @requestId = @requestId, @infoOnly = 0
        End
    End

    SELECT AJ.AJ_jobID AS job,
           ASN.AJS_name AS state,
           AJ.AJ_priority AS priority,
           AJ.AJ_requestID AS request,
           AJ.AJ_created AS created,
           AJ.AJ_start AS start,
           AJ.AJ_finish AS finish,
           AJ.AJ_assignedProcessorName AS processor,
           DS.Dataset_Num AS dataset
    FROM T_Analysis_Job_Request_Existing_Jobs AJR
         INNER JOIN dbo.T_Analysis_Job AJ
           ON AJR.Job = AJ.AJ_jobID
         INNER JOIN dbo.T_Analysis_State_Name ASN
           ON AJ.AJ_StateID = ASN.AJS_stateID
         INNER JOIN dbo.T_Dataset DS
           ON AJ.AJ_datasetID = DS.Dataset_ID
    WHERE AJR.Request_ID = @requestID
    ORDER BY AJ.AJ_jobID DESC

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[find_existing_jobs_for_request] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_existing_jobs_for_request] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_existing_jobs_for_request] TO [DMSReader] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_existing_jobs_for_request] TO [Limited_Table_Write] AS [dbo]
GO

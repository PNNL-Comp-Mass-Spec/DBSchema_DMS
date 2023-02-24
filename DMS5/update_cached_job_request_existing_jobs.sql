/****** Object:  StoredProcedure [dbo].[update_cached_job_request_existing_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_job_request_existing_jobs]
/****************************************************
**
**  Desc:   Updates T_Analysis_Job_Request_Existing_Jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/30/2019 mem - Initial version
**          07/31/2019 mem - Add option to find existing job requests that match jobs created within the last @jobSearchHours
**          06/25/2021 mem - Fix bug comparing legacy organism DB name in T_Analysis_Job to T_Analysis_Job_Request_Datasets
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @processingMode tinyint = 0,    -- 0 to only add new job requests, 1 to add new job requests and update existing information; ignored if @requestId or @jobSearchHours is non-zero
    @requestId int = 0,             -- When non-zero, a single request ID to add / update
    @jobSearchHours int = 0,        -- When non-zero, compare jobs created within this many hours to existing job requests
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @currentRequestId int = 0
    Declare @continue tinyint = 1
    Declare @jobRequestsAdded int = 0
    Declare @jobRequestsUpdated int = 0

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @processingMode = Coalesce(@processingMode, 0)
    Set @requestId = Coalesce(@requestId, 0)
    Set @jobSearchHours = Coalesce(@jobSearchHours, 0)
    Set @infoOnly = Coalesce(@infoOnly, 0)
    Set @message = ''

    If @requestId = 1
    Begin
        Select '@requestId 1 is a special placeholder request; table T_Analysis_Job_Request_Existing_Jobs does not track jobs for @requestId 1' As Warning
        Goto Done
    End

    If @requestId > 0
    Begin -- <a1>
        If @infoOnly > 0
        Begin
            SELECT DISTINCT AJR.AJR_requestID AS Request_ID,
              CASE
                  WHEN CachedJobs.Request_ID IS NULL
                  THEN 'Analysis job request to add to T_Analysis_Job_Request_Existing_Jobs'
                  ELSE 'Existing Analysis job request to validate against T_Analysis_Job_Request_Existing_Jobs'
              END AS Status
            FROM T_Analysis_Job_Request AJR
                 LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs CachedJobs
                   ON AJR.AJR_requestID = CachedJobs.Request_ID
            WHERE AJR.AJR_requestID = @requestId
            ORDER BY AJR.AJR_requestID
        End
        Else
        Begin
            MERGE T_Analysis_Job_Request_Existing_Jobs AS t
            USING (SELECT DISTINCT @requestId As Request_ID, Job
                   FROM get_existing_jobs_matching_job_request(@requestId)) as s
            ON (t.Request_ID = s.Request_ID AND t.Job = s.Job)
            -- Note: all of the columns in table T_Analysis_Job_Request_Existing_Jobs are primary keys or identity columns; there are no updatable columns
            WHEN NOT MATCHED BY TARGET THEN
                INSERT(Request_ID, Job)
                VALUES(s.Request_ID, s.Job)
            WHEN NOT MATCHED BY SOURCE AND t.Request_ID = @requestId THEN DELETE;
        End
        Goto Done
    End -- </a1>

    If @jobSearchHours > 0
    Begin -- <a2>
        ------------------------------------------------
        -- Find jobs created in the last @jobSearchHours that match one or more job requests
        ------------------------------------------------
        --
        CREATE TABLE #TmpRequestsAndExistingJobs (
            Request_ID int NOT NULL,
            Job        int NOT NULL
        )

        CREATE CLUSTERED INDEX #IX_TmpRequestsAndExistingJobs ON #TmpRequestsAndExistingJobs ( Request_ID, Job )

        INSERT INTO #TmpRequestsAndExistingJobs( Request_ID, Job )
        SELECT AJR.AJR_requestID,
               AJ.AJ_jobID
        FROM T_Analysis_Job AJ
             INNER JOIN T_Analysis_Tool AJT
               ON AJ.AJ_analysisToolID = AJT.AJT_toolID
             INNER JOIN T_Analysis_Job_Request AJR
               ON AJT.AJT_toolName = AJR.AJR_analysisToolName AND
                  AJ.AJ_parmFileName = AJR.AJR_parmFileName AND
                  AJ.AJ_settingsFileName = AJR.AJR_settingsFileName AND
                  Coalesce(AJ.AJ_specialProcessing, '') = Coalesce(AJR.AJR_specialProcessing, '')
             INNER JOIN T_Analysis_Job_Request_Datasets AJRD
               ON AJR.AJR_requestID = AJRD.Request_ID AND
                  AJRD.Dataset_ID = AJ.aj_datasetid
        WHERE AJR.AJR_requestID > 1 AND
              AJ.AJ_created >= DateAdd(HOUR, -@jobSearchHours, GetDate()) AND
              (AJT.AJT_resultType NOT LIKE '%Peptide_Hit%' OR
               AJT.AJT_resultType LIKE '%Peptide_Hit%' AND
               ((AJ.AJ_proteinCollectionList <> 'na' AND
                 AJ.AJ_proteinCollectionList = AJR.AJR_proteinCollectionList AND
                 AJ.AJ_proteinOptionsList = AJR.AJR_proteinOptionsList
                ) OR
                (AJ.AJ_proteinCollectionList = 'na' AND
                 AJ.AJ_proteinCollectionList = AJR.AJR_proteinCollectionList AND
                 AJ.AJ_organismDBName = AJR.AJR_organismDBName AND
                 AJ.AJ_organismID = AJR.AJR_organism_ID
                )
               )
              )
        GROUP BY AJR.AJR_requestID, AJ.AJ_jobID
        ORDER BY AJR.AJR_requestID, AJ.AJ_jobID

        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the update of cached info
            ------------------------------------------------
            --
            SELECT DISTINCT RJ.Request_ID AS Request_ID,
              CASE
                  WHEN CachedJobs.Request_ID IS NULL
                  THEN 'Analysis job request to add to T_Analysis_Job_Request_Existing_Jobs'
                  ELSE 'Existing Analysis job request to validate against T_Analysis_Job_Request_Existing_Jobs'
              END AS Status
            FROM #TmpRequestsAndExistingJobs RJ
                 LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs CachedJobs
                   ON RJ.Request_ID = CachedJobs.Request_ID
            ORDER BY RJ.Request_ID

            If @infoOnly > 1
            Begin
                SELECT *
                FROM #TmpRequestsAndExistingJobs
                ORDER BY Request_ID, Job
            End
        End
        Else
        Begin -- <b>

            ------------------------------------------------
            -- Count the new number of job requests that are not yet in #TmpRequestsAndExistingJobs
            ------------------------------------------------
            --
            SELECT @jobRequestsAdded = Count(DISTINCT Src.Request_ID)
            FROM #TmpRequestsAndExistingJobs Src
                 LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs AJRJ
                   ON Src.Request_ID = AJRJ.Request_ID
            WHERE AJRJ.Request_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            ------------------------------------------------
            -- Use a merge statement to add/remove rows from T_Analysis_Job_Request_Existing_Jobs
            --
            -- We must process each Request_ID separately since the
            -- Delete operation in the Merge statement does not support
            -- WHEN NOT MATCHED BY Source And t.Request_ID = s.Request_ID THEN DELETE
            ------------------------------------------------
            --
            While @continue > 0
            Begin -- <c>
                SELECT TOP 1 @currentRequestId = Request_ID
                FROM #TmpRequestsAndExistingJobs
                WHERE Request_ID > @currentRequestId
                ORDER BY Request_ID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    Set @continue= 0
                End
                Else
                Begin -- <d>
                    MERGE T_Analysis_Job_Request_Existing_Jobs AS t
                    USING (SELECT DISTINCT @currentRequestId As Request_ID, Job
                           FROM get_existing_jobs_matching_job_request(@currentRequestId)) as s
                    ON (t.Request_ID = s.Request_ID AND t.Job = s.Job)
                    WHEN NOT MATCHED BY TARGET THEN
                        INSERT(Request_ID, Job)
                        VALUES(s.Request_ID, s.Job)
                    WHEN NOT MATCHED BY Source And t.Request_ID = @currentRequestId THEN DELETE;
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                    Begin
                        Set @jobRequestsUpdated = @jobRequestsUpdated + 1
                    End
                End -- </d>
            End -- </c>

            If @jobRequestsAdded > 0
            Begin
                Set @message = Convert(varchar(12), @jobRequestsAdded) +
                               dbo.check_plural(@jobRequestsAdded, ' job request was added', ' job requests were added')
            End

            If @jobRequestsUpdated > 0
            Begin
                Set @message = dbo.append_to_text(@message, Convert(varchar(12), @jobRequestsUpdated) +
                                                dbo.check_plural(@jobRequestsUpdated, ' job request was updated', ' job requests were updated') + ' via a merge',
                                                0, '; ', 512)
            End
        End -- </b>

        Goto Done
    End -- </a2>

    If @processingMode = 0
    Begin -- <a3>
        ------------------------------------------------
        -- Add new analysis job requests to T_Analysis_Job_Request_Existing_Jobs
        ------------------------------------------------
        --
        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the addition of new analysis job requests
            ------------------------------------------------

            SELECT AJR.AJR_requestID AS Request_ID,
                   'Analysis job request to add to T_Analysis_Job_Request_Existing_Jobs' AS Status
            FROM T_Analysis_Job_Request AJR
                 LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs CachedJobs
                   ON AJR.AJR_requestID = CachedJobs.Request_ID
            WHERE AJR.AJR_requestID > 1 AND
                  CachedJobs.Request_ID IS NULL
            ORDER BY AJR.AJR_requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Select 'No analysis job requests need to be added to T_Analysis_Job_Request_Existing_Jobs' As Status
            End
        End
        Else
        Begin
            ------------------------------------------------
            -- Add missing analysis job requests
            --
            -- There are a large number of existing job requests that were never used to create jobs
            -- Therefore, this query only examines job requests from the last 30 days
            ------------------------------------------------
            --
            INSERT INTO T_Analysis_Job_Request_Existing_Jobs( Request_ID, Job )
            SELECT DISTINCT LookupQ.Request_ID,
                            get_existing_jobs_matching_job_request.Job
            FROM ( SELECT AJR.AJR_requestID AS Request_ID
                   FROM T_Analysis_Job_Request AJR
                        LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs CachedJobs
                          ON AJR.AJR_requestID = CachedJobs.Request_ID
                   WHERE AJR.AJR_requestID > 1 AND
                         AJR.AJR_created > DateAdd(Day, -30, GetDate()) AND
                         CachedJobs.Request_ID IS NULL
                 ) LookupQ
                 CROSS APPLY get_existing_jobs_matching_job_request ( LookupQ.Request_ID )
            ORDER BY LookupQ.Request_ID, Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new analysis job ' + dbo.check_plural(@myRowCount, 'request', 'requests')
            End
        End

    End -- </a3>
    Else
    Begin -- <a4>
        ------------------------------------------------
        -- Update T_Analysis_Job_Request_Existing_Jobs using all existing analysis job requests
        ------------------------------------------------
        --
        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the update of cached info
            ------------------------------------------------
            --
            SELECT DISTINCT AJR.AJR_requestID AS Request_ID,
              CASE
                  WHEN CachedJobs.Request_ID IS NULL
                  THEN 'Analysis job request to add to T_Analysis_Job_Request_Existing_Jobs'
                  ELSE 'Existing Analysis job request to validate against T_Analysis_Job_Request_Existing_Jobs'
              END AS Status
            FROM T_Analysis_Job_Request AJR
                 LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs CachedJobs
                   ON AJR.AJR_requestID = CachedJobs.Request_ID
            ORDER BY AJR.AJR_requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Select 'No data in T_Analysis_Job_Request_Existing_Jobs needs to be updated' As Status

        End
        Else
        Begin
            ------------------------------------------------
            -- Update cached info for all job requests
            -- This will take at least 30 seconds to complete
            ------------------------------------------------
            --
            MERGE T_Analysis_Job_Request_Existing_Jobs AS t
            USING (SELECT DISTINCT AJR.AJR_requestID As Request_ID, MatchingJobs.Job
                    FROM T_Analysis_Job_Request AJR CROSS APPLY get_existing_jobs_matching_job_request(AJR.AJR_requestID) MatchingJobs
                    WHERE AJR.AJR_requestID > 1) as s
            ON (t.Request_ID = s.Request_ID AND t.Job = s.Job)
            WHEN NOT MATCHED BY TARGET THEN
                INSERT(Request_ID, Job)
                VALUES(s.Request_ID, s.Job)
            WHEN NOT MATCHED BY Source THEN DELETE;
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @message = Convert(varchar(12), @myRowCount) +
                               dbo.check_plural(@myRowCount, ' job request was updated', ' job requests were updated') + ' via a merge'
            End
        End

    End -- </a4>

Done:
    -- Exec post_log_entry 'Debug', @message, 'update_cached_job_request_existing_jobs'
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_cached_job_request_existing_jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cached_job_request_existing_jobs] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cached_job_request_existing_jobs] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cached_job_request_existing_jobs] TO [DMS2_SP_User] AS [dbo]
GO

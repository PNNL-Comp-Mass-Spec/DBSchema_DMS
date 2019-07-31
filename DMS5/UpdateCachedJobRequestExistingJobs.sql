/****** Object:  StoredProcedure [dbo].[UpdateCachedJobRequestExistingJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCachedJobRequestExistingJobs]
/****************************************************
**
**  Desc:   Updates T_Analysis_Job_Request_Existing_Jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/30/2019 mem - Initial version
**    
*****************************************************/
(
    @processingMode tinyint = 0,            -- 0 to only add new job requests; 1 to add new job requests and update existing information
    @requestId int = 0,                     -- When non-zero, a single request ID to add / update
    @jobNumber Int = 0,                     -- When non-zero, a analysis job to compare against all existing job requests
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output    
)
As
    Set nocount on
    
    Declare @myRowCount int = 0
    Declare @myError int = 0

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @processingMode = IsNull(@processingMode, 0)
    Set @requestId = IsNull(@requestId, 0)
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @jobNumber = IsNull(@jobNumber, 0)
    Set @message = ''
    
    If @requestId = 1
    Begin
        Select '@requestId 1 is a special placeholder request; table T_Analysis_Job_Request_Existing_Jobs does not track jobs for @requestId 1' As Warning
        Goto Done
    End

    If @requestId > 0
    Begin
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
            MERGE [dbo].T_Analysis_Job_Request_Existing_Jobs AS t
            USING (SELECT Distinct @requestId As Request_ID, Job
                   FROM    GetRunRequestExistingJobListTab(@requestId)) as s
            ON (t.Request_ID = s.Request_ID And t.Job = s.Job)
            -- Note: all of the columns in table T_Analysis_Job_Request_Datasets are primary keys or identity columns; there are no updatable columns
            WHEN NOT MATCHED BY TARGET THEN
                INSERT(Request_ID, Job)
                VALUES(s.Request_ID, s.Job)
            WHEN NOT MATCHED BY SOURCE And t.Request_ID = @requestId THEN DELETE; 
        End
        Goto Done
    End

    ------------------------------------------------
    -- Add new datasets to T_Analysis_Job_Request_Existing_Jobs
    ------------------------------------------------
    --
    If @processingMode = 0 Or @infoOnly > 0
    Begin
    
        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the addition of new analysis job requests
            ------------------------------------------------

            SELECT AJR.AJR_requestID As Request_ID,
                   'Analysis job request to add to T_Analysis_Job_Request_Existing_Jobs' As Status
            FROM T_Analysis_Job_Request AJR
                 LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs CachedJobs
                   ON AJR.AJR_requestID = CachedJobs.Request_ID
            WHERE AJR.AJR_requestID > 1 AND 
                  CachedJobs.Request_ID IS Null
            ORDER BY AJR.AJR_requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Select 'No analysis job requests need to be added to T_Analysis_Job_Request_Existing_Jobs' As Status
        End    
        Else
        Begin
            ------------------------------------------------
            -- Add new analysis job requests
            ------------------------------------------------

            INSERT INTO T_Analysis_Job_Request_Existing_Jobs( Request_ID, Job )
            SELECT Distinct AJR.AJR_requestID, GetRunRequestExistingJobListTab.Job
            FROM  T_Analysis_Job_Request AJR Cross apply GetRunRequestExistingJobListTab(AJR.AJR_requestID)
                  LEFT OUTER JOIN T_Analysis_Job_Request_Existing_Jobs CachedJobs
                   ON AJR.AJR_requestID = CachedJobs.Request_ID
            WHERE AJR.AJR_requestID > 1 AND 
                  CachedJobs.Request_ID IS Null
            ORDER BY AJR.AJR_requestID, Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
                Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new analysis job ' + dbo.CheckPlural(@myRowCount, 'request', 'requests')
        End

    End
    
    If @processingMode > 0
    Begin

        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the update of cached info
            ------------------------------------------------

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
            -- Update cached info
            ------------------------------------------------

            MERGE [dbo].[T_Analysis_Job_Request_Existing_Jobs] AS t
            USING (SELECT Distinct AJR.AJR_requestID As Request_ID, GetRunRequestExistingJobListTab.Job
                    FROM T_Analysis_Job_Request AJR Cross apply GetRunRequestExistingJobListTab(AJR.AJR_requestID)
                    WHERE AJR.AJR_requestID > 1) as s
            ON (t.Request_ID = s.Request_ID And t.Job = s.Job)
            WHEN NOT MATCHED BY TARGET THEN
                INSERT(Request_ID, Job)
                VALUES(s.Request_ID, s.Job)
            WHEN NOT MATCHED BY Source THEN DELETE;
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @message = dbo.AppendToText(@message, 
                                                Convert(varchar(12), @myRowCount) + dbo.CheckPlural(@myRowCount, ' job request was updated', ' job requests were updated') + ' via a merge', 
                                                0, '; ', 512)
            End
        End

    End

Done:
    -- Exec PostLogEntry 'Debug', @message, 'UpdateCachedJobRequestExistingJobs'
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedJobRequestExistingJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateCachedJobRequestExistingJobs] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateCachedJobRequestExistingJobs] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateCachedJobRequestExistingJobs] TO [DMS2_SP_User] AS [dbo]
GO

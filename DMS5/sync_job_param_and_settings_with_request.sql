/****** Object:  StoredProcedure [dbo].[sync_job_param_and_settings_with_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sync_job_param_and_settings_with_request]
/****************************************************
**
**  Desc:
**      Updates the settings file name and parameter file name
**      for analysis job requests based on the settings file name
**      and parameter file name actually used
**
**      This helps keep the request and jobs in sync for bookkeeping purposes
**      Only updates job requests if all of the jobs associated with the
**      request used the same parameter file and settings file
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/17/2014 mem - Initial version
**          07/29/2022 mem - No longer filter out null parameter file or settings file names since neither column allows null values
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestMinimum int = 0,                    -- Minimum request ID to examine (ignored if @recentRequestDays is positive)
    @recentRequestDays int = 14,                -- Process requests created within the most recent x days; 0 to use @requestMinimum
    @infoOnly tinyint = 0,
    @message varchar(255) = '' output
)
AS
    set nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @requestMinimum = Coalesce(@requestMinimum, 0)
    Set @recentRequestDays = Coalesce(@recentRequestDays, 14)
    Set @infoOnly = Coalesce(@infoOnly, 0)
    Set @message = ''

    If @requestMinimum < 1 And @recentRequestDays < 1
        Set @recentRequestDays = 14

    If @recentRequestDays > 0
    Begin
        SELECT @requestMinimum = Min(AJR_requestID)
        FROM T_Analysis_Job_Request
        WHERE AJR_created >= DATEADD(day, -@recentRequestDays, GETDATE()) AND
              AJR_requestID > 1

        Set @requestMinimum = Coalesce(@requestMinimum, 2)
    End

    -- Make sure @requestMinimum is not 1=Default Request
    If @requestMinimum < 2
        Set @requestMinimum = 2

    If @infoOnly <> 0
        Select @requestMinimum as MinimumRequestID

    -----------------------------------------------------------
    -- Create a temp table
    -----------------------------------------------------------

    CREATE TABLE #Tmp_RequestIDs (
        RequestID int NOT NULL)

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_RequestIDs ON #Tmp_RequestIDs(RequestID)


    CREATE TABLE #Tmp_Request_Params (
        RequestID int NOT NULL,
        ParamFileName varchar(255) not null,
        SettingsFileName varchar(255) not null)

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Request_Params ON #Tmp_Request_Params(RequestID)

    -----------------------------------------------------------
    -- Find analysis jobs that came from a job request
    --   and for which all of the jobs used the same parameter file and settings file
    -- This is accomplished in two steps, with two temporary tables,
    --   since a single-step query was found to not scale well
    -----------------------------------------------------------
    --
    INSERT INTO #Tmp_RequestIDs (RequestID)
    SELECT A.AJ_requestID
    FROM ( SELECT AJ_requestID,
                AJ_settingsFileName,
                AJ_parmFileName,
                COUNT(*) AS Jobs
            FROM T_Analysis_Job AJ
            WHERE AJ_requestID >= @requestMinimum
            GROUP BY AJ_requestID, AJ_settingsFileName, AJ_parmFileName
        ) A
        INNER JOIN
        ( SELECT AJ_requestID,
                COUNT(*) AS Jobs
            FROM T_Analysis_Job AJ
            WHERE AJ_requestID >= @requestMinimum
            GROUP BY AJ_requestID
        ) B
            ON A.AJ_requestID = B.AJ_requestID
    WHERE A.Jobs = B.Jobs
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    -----------------------------------------------------------
    -- Cache the param file and settings file for the requests
    -----------------------------------------------------------
    --
    INSERT INTO #Tmp_Request_Params (RequestID, ParamFileName, SettingsFileName)
    SELECT J.AJ_requestID,
           J.AJ_parmFileName,
           J.AJ_settingsFileName
    FROM T_Analysis_Job J
         INNER JOIN #Tmp_RequestIDs FilterQ
           ON J.AJ_requestID = FilterQ.RequestID
    GROUP BY J.AJ_requestID, J.AJ_parmFileName, J.AJ_settingsFileName
    ORDER BY J.AJ_requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    If @infoOnly <> 0
    Begin

        -----------------------------------------------------------
        -- Preview the requests that would be updated
        -----------------------------------------------------------
        --
        SELECT Target.AJR_requestID AS RequestID,
               Target.AJR_parmFileName AS ParamFileName,
               Case When Target.AJR_parmFileName <> R.ParamFileName Then R.ParamFileName Else '' End as ParamFileNameNew,
               Target.AJR_settingsFileName AS SettingsFileName,
               Case When Target.AJR_settingsFileName <> R.SettingsFileName Then R.SettingsFileName Else '' End as SettingsFileNameNew
        FROM T_Analysis_Job_Request Target
             INNER JOIN #Tmp_Request_Params R
               ON Target.AJR_RequestID = R.RequestID
        WHERE Target.AJR_State > 1 AND
              (Target.AJR_parmFileName <> R.ParamFileName OR
               Target.AJR_settingsFileName <> R.SettingsFileName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @message = 'All requests are up-to-date'
        Else
            Set @message = 'Need to update the parameter file name and/or settings file name for ' + Convert(varchar(12), @myRowCount) + ' job requests, based on the actual jobs'

        SELECT @message as Message
    End
    Else
    Begin

        -----------------------------------------------------------
        -- Update the requests
        -----------------------------------------------------------
        --
        UPDATE T_Analysis_Job_Request
        SET AJR_parmFileName = R.ParamFileName,
            AJR_settingsFileName = R.SettingsFileName
        FROM T_Analysis_Job_Request Target
             INNER JOIN #Tmp_Request_Params R
               ON Target.AJR_RequestID = R.RequestID
        WHERE Target.AJR_State > 1 AND
              (Target.AJR_parmFileName <> R.ParamFileName OR
               Target.AJR_settingsFileName <> R.SettingsFileName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'All requests are up-to-date'
        End
        Else
        Begin
            Set @message = 'Updated the parameter file name and/or settings file name for ' + Convert(varchar(12), @myRowCount) + ' job requests to match the actual jobs'

            Exec post_log_entry 'Normal', @message, 'sync_job_param_and_settings_with_request'
        End

    End

Done:

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[sync_job_param_and_settings_with_request] TO [DDL_Viewer] AS [dbo]
GO

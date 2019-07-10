/****** Object:  StoredProcedure [dbo].[FindStaleMyEMSLUploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FindStaleMyEMSLUploads]
/****************************************************
**
**  Desc: 
**      Looks for unverified entries added to T_MyEMSL_Uploads over 45 ago (customize with @staleUploadDays)
**      For any that are found, sets the ErrorCode to 101 and posts an entry to T_Log_Entries
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/20/2019 mem - Initial version
**          07/01/2019 mem - Log details of entries over 1 year old that will have ErrorCode set to 101
**          07/08/2019 mem - Fix bug updating RetrySucceeded
**                         - Pass @logMessage to PostLogEntry
**    
*****************************************************/
(
    @staleUploadDays int = 45,
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output 
)
As
    Set XACT_ABORT, nocount on
    
    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Declare @foundRetrySuccessTasks tinyint = 0

    Declare @entryID Int
    Declare @job Int

    Declare @entryIDList varchar(500)
    Declare @jobList varchar(500)
    
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    
    Set @staleUploadDays = IsNull(@staleUploadDays, 45);
    Set @infoOnly = IsNull(@infoOnly, 0);
    Set @message = ''

    If @staleUploadDays < 20
    Begin
        -- Require @staleUploadDays to be at least 20
        Set @staleUploadDays = 14
    End    
    
    ---------------------------------------------------
    -- Find and process stale uploads
    ---------------------------------------------------
    
    Create Table #Tmp_StaleUploads (
        Entry_ID Int Not Null,
        Job Int Not Null,
        Dataset_ID Int Not Null,
        Subdirectory varchar(255) Not Null,
        Entered Datetime,
        RetrySucceeded tinyint
    )

    INSERT INTO #Tmp_StaleUploads( Entry_ID,
                                   Job,
                                   Dataset_ID,
                                   Subdirectory,
                                   Entered,
                                   RetrySucceeded)
    SELECT Entry_ID,
           Job,
           Dataset_ID,
           Subfolder,
           Entered,
           0
    FROM T_MyEMSL_Uploads
    WHERE ErrorCode = 0 AND
          Verified = 0 AND
          Entered < DateAdd(DAY, - @staleUploadDays, GetDate())
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Not Exists (SELECT * FROM #Tmp_StaleUploads)
    Begin
        Set @message = 'Nothing to do'
        If @infoOnly > 0
        Begin
            Select 'No stale uploads were found' As Message
        End
        Goto Done
    End

    ---------------------------------------------------
    -- Look for uploads that were retried and the retry succeeded
    ---------------------------------------------------
         
    UPDATE #Tmp_StaleUploads
    SET RetrySucceeded = 1
    WHERE Entry_ID IN ( SELECT Stale.Entry_ID
                        FROM #Tmp_StaleUploads Stale
                             INNER JOIN T_MyEMSL_Uploads Uploads
                               ON Stale.Dataset_ID = Uploads.Dataset_ID AND
                                  Stale.Subdirectory = Uploads.Subfolder AND
                                  Uploads.Verified > 0 )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        Set @foundRetrySuccessTasks = 1
    End
    
    If @infoOnly > 0
    Begin
    
        ---------------------------------------------------
        -- Preview tasks to update
        ---------------------------------------------------

        SELECT 'Stale: ' + Cast(DateDiff(Day, Stale.Entered, GetDate()) As varchar(12)) + ' days old' As Message,
               Stale.RetrySucceeded As [Retry Succeeded],
               Uploads.*
        FROM V_MyEMSL_Uploads Uploads
             INNER JOIN #Tmp_StaleUploads Stale
               ON Uploads.Entry_ID = Stale.Entry_ID
        ORDER BY RetrySucceeded Desc, Entry_ID
    End
    Else
    Begin
    
        ---------------------------------------------------
        -- Perform the update
        ---------------------------------------------------

        Begin Tran

        If @foundRetrySuccessTasks > 0
        Begin
            -- Silently update any where the retry succeeded
            --
            UPDATE T_MyEMSL_Uploads
            SET ErrorCode = 101
            FROM T_MyEMSL_Uploads Uploads
                 INNER JOIN #Tmp_StaleUploads Stale
                   ON Uploads.Entry_ID = Stale.Entry_ID
            WHERE Stale.RetrySucceeded = 1
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            DELETE FROM #Tmp_StaleUploads
            WHERE RetrySucceeded = 1
        End

        -- We keep seeing really old uploads that should already have a non-zero error code
        -- getting inserted into #Tmp_StaleUploads and then being logged into T_Log_Entries
        -- There should not be any records that are old, unverified, and have an ErrorCode of zero

        -- Log details of the first five uploads that were entered over 1 year ago and yet are in #Tmp_StaleUploads

        Declare @iteration Int = 0
        Declare @entryCountToLog Int = 5

        Declare @subFolder varchar(255)
        Declare @fileCountNew Int
        Declare @fileCountUpdated Int 
        Declare @bytes bigint
        Declare @verifed int
        Declare @ingestStepsCompleted int
        Declare @errorCode int
        Declare @entered Datetime
        Declare @logMessage varchar(500)

        Set @entryID = 0
        While @iteration < @entryCountToLog
        Begin -- <a>
            Select Top 1 @entryID = Entry_ID
            From #Tmp_StaleUploads
            Where Entry_ID > @entryID And Entered < DateAdd(Day, -365, GetDate())
            Order By Entry_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @iteration = @entryCountToLog + 1
            End
            Else
            Begin -- <b>
                SELECT @job = Job,
                       @subFolder = Subfolder,
                       @fileCountNew = FileCountNew,
                       @fileCountUpdated = FileCountUpdated,
                       @bytes = Bytes,
                       @verifed = Verified,
                       @ingestStepsCompleted = Ingest_Steps_Completed,
                       @errorCode = ErrorCode,
                       @entered = Entered
                FROM T_MyEMSL_Uploads
                WHERE Entry_ID = @entryID

                Set @logMessage = 
                        'Details of an old MyEMSL upload entry to be marked stale; ' + 
                        'Entry ID: ' + Cast(@entryID As varchar(12)) + 
                        ', Job: ' +  Cast(@job As varchar(12)) +
                        ', Subfolder: ' + Coalesce(@subFolder, 'Null') +
                        ', FileCountNew: ' +  Cast(@fileCountNew As varchar(12)) +
                        ', FileCountUpdated: ' +  Cast(@fileCountUpdated As varchar(12)) +
                        ', Bytes: ' +  Cast(@bytes As varchar(12)) +
                        ', Verified: ' +  Cast(@verifed As varchar(12)) +
                        ', IngestStepsCompleted: ' + Coalesce(Cast(@ingestStepsCompleted As varchar(12)), 'Null') +
                        ', ErrorCode: ' +  Cast(@errorCode As varchar(12)) +
                        ', Entered: ' +  Convert(varchar(32), @entered, 120)

                Exec PostLogEntry 'Error', @logMessage, 'FindStaleMyEMSLUploads'

                Set @iteration = @iteration + 1
            End -- </b>    
        End -- </a>

        -- Update uploads where a successful retry does not exist
        --
        UPDATE T_MyEMSL_Uploads
        SET ErrorCode = 101
        FROM T_MyEMSL_Uploads Uploads
             INNER JOIN #Tmp_StaleUploads Stale
               ON Uploads.Entry_ID = Stale.Entry_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 1
        Begin
            SELECT @entryID = Entry_ID,
                   @job = Job
            FROM #Tmp_StaleUploads

            -- MyEMSL upload task 1625978 for job 3773650 has been unverified for over 45 days; ErrorCode set to 101
            Set @message = 'MyEMSL upload task ' + Cast(@entryID As varchar(12)) + 
                           ' for job '  + Cast(@job As varchar(12)) + ' has been'
        End
        
        If @myRowCount > 1
        Begin
            Set @entryIDList = ''
            Set @jobList = ''

            SELECT TOP 20 @entryIDList = @entryIDList + Cast(Entry_ID AS varchar(12)) + ',',
                          @jobList = @jobList + Cast(Job AS varchar(12)) + ','
            FROM #Tmp_StaleUploads
            ORDER BY Entry_ID

            -- MyEMSL upload tasks 1633334,1633470,1633694 for jobs 3789097,3789252,3789798 have been unverified for over 45 days; ErrorCode set to 101
            Set @message = 'MyEMSL upload tasks ' + Substring(@entryIDList, 1, Len(@entryIDList) - 1) + 
                           ' for jobs '  + Substring(@jobList, 1, Len(@jobList) - 1) + ' have been'
        End

        If @myRowCount > 0
        Begin
            Set @message = @message + ' unverified for over ' + Cast(@staleUploadDays As varchar(12)) + ' days; ErrorCode set to 101' 
            Exec PostLogEntry 'Error', @message, 'FindStaleMyEMSLUploads'
        End

        Commit

        Print @message

    End
    
Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in FindStaleMyEMSLUploads'
        
        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
        
        Exec PostLogEntry 'Error', @message, 'FindStaleMyEMSLUploads'
    End    

    Return @myError


GO

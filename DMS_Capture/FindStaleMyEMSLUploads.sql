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
        Subdirectory Varchar(255) Not Null,
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
                                  Uploads.Job > Stale.Job AND
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

        SELECT 'Stale: ' + Cast(DateDiff(Day, Stale.Entered, GetDate()) As Varchar(12)) + ' days old' As Message,
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
            Set @message = 'MyEMSL upload task ' + Cast(@entryID As Varchar(12)) + 
                           ' for job '  + Cast(@job As Varchar(12)) + ' has been'
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
            Set @message = @message + ' unverified for over ' + Cast(@staleUploadDays As Varchar(12)) + ' days; ErrorCode set to 101' 
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

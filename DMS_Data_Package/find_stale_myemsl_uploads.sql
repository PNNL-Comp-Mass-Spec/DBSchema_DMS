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

    Declare @entryID Int
    Declare @dataPackageID Int

    Declare @entryIDList varchar(500)
    Declare @dataPackageList varchar(500)
            
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
        Data_Package_ID Int Not Null,
        Entered Datetime
    )

    INSERT INTO #Tmp_StaleUploads( Entry_ID,
                                   Data_Package_ID,
                                   Entered)
    SELECT Entry_ID,
           Data_Package_ID,
           Entered
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
    -- Perform the update
    ---------------------------------------------------
    
    If @infoOnly > 0
    Begin
        SELECT 'Stale: ' + Cast(DateDiff(Day, Stale.Entered, GetDate()) As Varchar(12)) + ' days old' As Message,
               Uploads.*
        FROM V_MyEMSL_Uploads Uploads
             INNER JOIN #Tmp_StaleUploads Stale
               ON Uploads.Entry_ID = Stale.Entry_ID
        ORDER BY Entry_ID
    End
    Else
    Begin
        Begin Tran

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
                   @dataPackageID = Data_Package_ID
            FROM #Tmp_StaleUploads

            -- MyEMSL upload task 3944 for data package 2967 has been unverified for over 45 days; ErrorCode set to 101
            Set @message = 'MyEMSL upload task ' + Cast(@entryID As Varchar(12)) + 
                           ' for data package '  + Cast(@dataPackageID As Varchar(12)) + ' has been'
        End
        Else
        Begin
            Set @entryIDList = ''
            Set @dataPackageList = ''

            SELECT @entryIDList = @entryIDList + Cast(Entry_ID As Varchar(12)) + ',',
                   @dataPackageList = @dataPackageList + Cast(Data_Package_ID As Varchar(12)) + ','
            FROM #Tmp_StaleUploads

            -- MyEMSL upload tasks 3944,4119,4120 for data packages 2967,2895,2896 have been unverified for over 45 days; ErrorCode set to 101
            Set @message = 'MyEMSL upload tasks ' + Substring(@entryIDList, 1, Len(@entryIDList) - 1) + 
                           ' for data packages '  + Substring(@dataPackageList, 1, Len(@dataPackageList) - 1) + ' have been'
        End

        Set @message = @message + ' unverified for over ' + Cast(@staleUploadDays As Varchar(12)) + ' days; ErrorCode set to 101' 

        Exec PostLogEntry 'Error', @message, 'FindStaleMyEMSLUploads'

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

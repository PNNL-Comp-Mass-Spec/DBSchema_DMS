/****** Object:  StoredProcedure [dbo].[SetMyEMSLUploadStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetMyEMSLUploadStatus]
/****************************************************
**
**  Desc: 
**      Updates the status for an entry in T_MyEMSL_Uploads
**
**      Updates column Available if Step 5 is "completed"
**      Updates column Verified  if Step 6 is "verified"
**
**      For example, see https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/2271574/xml
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/25/2013 mem - Initial version
**          05/20/2019 mem - Add Set XACT_ABORT
**    
*****************************************************/
(
    @EntryID int,
    @DataPackageID int,                        -- Used as a safety check to confirm that we're updating a valid entry
    @Available tinyint,
    @Verified tinyint,
    @message varchar(512)='' output
)
As
    Set XACT_ABORT, nocount on
    
    Declare @myError Int = 0
    Declare @myRowCount int = 0
        
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    
    Set @EntryID = IsNull(@EntryID, 0);
    Set @DataPackageID = IsNull(@DataPackageID, 0);
    Set @Available = IsNull(@Available, 0);
    Set @Verified = IsNull(@Verified, 0);

    Set @message = ''
    
    If @EntryID <= 0
    Begin
        Set @message = '@EntryID must be positive; unable to continue'
        Set @myError = 60000
        Goto Done
    End
    
    If @DataPackageID <= 0
    Begin
        Set @message = '@DataPackageID must be positive; unable to continue'
        Set @myError = 60001
        Goto Done
    End
    
    ---------------------------------------------------
    -- Make sure this is a valid entry
    ---------------------------------------------------
    
    If Not Exists (SELECT * FROM T_MyEMSL_Uploads WHERE Entry_ID = @EntryID AND Data_Package_ID = @DataPackageID)
    Begin
        Set @message = 'Entry ' + Convert(varchar(12), @EntryID) + ' does not correspond to data package ' + Convert(varchar(12), @DataPackageID)
        Set @myError = 60002
        Goto Done
    End
         
    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------
    
    UPDATE T_MyEMSL_Uploads
    SET Available = @Available,
        Verified = @Verified
    WHERE Entry_ID = @EntryID AND
          (Available <> @Available OR
           Verified <> @Verified)
    
Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in SetMyEMSLUploadStatus'
        
        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
        
        Exec PostLogEntry 'Error', @message, 'SetMyEMSLUploadStatus'
    End    

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[SetMyEMSLUploadStatus] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetMyEMSLUploadStatus] TO [DMS_SP_User] AS [dbo]
GO

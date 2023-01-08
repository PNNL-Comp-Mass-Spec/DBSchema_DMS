/****** Object:  StoredProcedure [dbo].[SetMyEMSLUploadVerified] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetMyEMSLUploadVerified]
/****************************************************
**
**  Desc: 
**      Marks one or more MyEMSL upload tasks as verified by the MyEMSL ingest process
**      This procedure should only be called after the MyEMSL Status page shows "verified" and "SUCCESS" for step 6
**      For example, see https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1309016
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/20/2013 mem - Initial version
**          12/19/2014 mem - Added parameter @ingestStepsCompleted
**          05/31/2017 mem - Add logging
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          07/13/2017 mem - Add parameter @statusURIList (required to avoid conflicts between StatusNums from the old MyEMSL backend vs. transaction IDs from the new backend)
**          08/01/2017 mem - Use THROW if not authorized
**          01/07/2023 mem - Use new column names in view
**    
*****************************************************/
(
    @datasetID int,
    @StatusNumList varchar(1024),           -- Comma separated list of status numbers; these must all match the specified DatasetID and they must match the Status entries that the @statusURIList values match
    @statusURIList varchar(4000),           -- Comma separated list of status URIs; these must all match the specified DatasetID using V_MyEMSL_Uploads (this is a safety check)
    @ingestStepsCompleted tinyint,          -- Number of ingest steps that were completed for these status nums (assumes that all the status nums completed the same steps)
    @message varchar(512)='' output
)
As
    set nocount on
    
    declare @myError int = 0
    declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'SetMyEMSLUploadVerified', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;
        
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    
    Set @datasetID = IsNull(@datasetID, 0)
    Set @StatusNumList = IsNull(@StatusNumList, '')
    Set @statusURIList = IsNull(@statusURIList, '')
    Set @ingestStepsCompleted = IsNull(@ingestStepsCompleted, 0)
    
    Set @message = ''
    
    If @datasetID <= 0
    Begin
        Set @message = '@datasetID must be positive; unable to continue'
        Set @myError = 60000
        Goto Done
    End
    
    If Len(@StatusNumList) = 0
    Begin
        Set @message = '@StatusNumList was empty; unable to continue'
        Set @myError = 60001
        Goto Done
    End
    
    If Len(@statusURIList) = 0
    Begin
        Set @message = '@statusURIList was empty; unable to continue'
        Set @myError = 60001
        Goto Done
    End
    
    Declare @StatusNumListTable AS Table(Status_Num int NOT NULL)
    
    Declare @StatusURIListTable AS Table(Status_URI varchar(255) NOT NULL)
    
    Declare @StatusEntryIDsTable AS Table(Entry_ID int NOT NULL, Dataset_ID int NOT NULL)
    
    ---------------------------------------------------
    -- Split StatusNumList and StatusURIList on commas
    ---------------------------------------------------
    
    INSERT INTO @StatusNumListTable (Status_Num)
    SELECT DISTINCT Value
    FROM dbo.udfParseDelimitedIntegerList(@StatusNumList, ',')
    ORDER BY Value

    Declare @StatusNumCount int = 0

    SELECT @StatusNumCount = COUNT(*) FROM @StatusNumListTable
    
    If IsNull(@StatusNumCount, 0) = 0
    Begin
        Set @message = 'No status nums were found in @StatusNumList; unable to continue'
        Set @myError = 60002
        Goto Done
    End
    
    INSERT INTO @StatusURIListTable (Status_URI)
    SELECT DISTINCT Value
    FROM dbo.udfParseDelimitedList(@statusURIList, ',')
    ORDER BY Value

    Declare @StatusURICount int = 0

    SELECT @StatusURICount = COUNT(*) FROM @StatusURIListTable
    
    If IsNull(@StatusURICount, 0) = 0
    Begin
        Set @message = 'No status URIs were found in @statusURIList; unable to continue'
        Set @myError = 60002
        Goto Done
    End

    If @StatusNumCount <> @StatusURICount
    Begin
        Set @message = 'Differing number of Status Nums and Status URIs; unable to continue'
        Set @myError = 60009
        Goto Done
    End
    
    ---------------------------------------------------
    -- Make sure the transaction IDs in @StatusNumListTable exist in T_MyEMSL_Uploads
    ---------------------------------------------------
    
    If Exists (SELECT * FROM @StatusNumListTable SL LEFT OUTER JOIN T_MyEMSL_Uploads MU ON MU.StatusNum = SL.Status_Num WHERE MU.Entry_ID IS NULL)
    Begin
        Set @message = 'One or more Status Nums in @StatusNumList were not found in T_MyEMSL_Uploads: ' + @StatusNumList
        Set @myError = 60003
        Goto Done
    End

    ---------------------------------------------------
    -- Find the Entry_ID values of the status entries to examine
    ---------------------------------------------------
    
    INSERT INTO @StatusEntryIDsTable (Entry_ID, Dataset_ID)
    SELECT Entry_ID, Dataset_ID
    FROM V_MyEMSL_Uploads
    WHERE Status_Num  IN (Select Status_Num From @StatusNumListTable) AND
          Status_URI IN (Select Status_URI From @StatusURIListTable)

    Declare @EntryIDCount int
    SELECT @EntryIDCount = COUNT(*) FROM @StatusEntryIDsTable

    If @EntryIDCount < @StatusURICount
    Begin
        Set @message = 'One or more Status URIs do not correspond to a given Status Num in V_MyEMSL_Uploads; ' + 
                       'see ' + @StatusNumList + ' and ' + @StatusURIList
        Set @myError = 60010
        Goto Done
    End
    
    ---------------------------------------------------
    -- Make sure the Dataset_ID is correct
    ---------------------------------------------------
    
    If Exists (Select * FROM @StatusEntryIDsTable WHERE Dataset_ID <> @DatasetID)
    Begin
        Set @message = 'One or more Status Nums in @StatusNumList do not have Dataset_ID ' + Convert(varchar(12), @DatasetID) + ' in V_MyEMSL_Uploads; ' + 
                       'see ' + @StatusNumList + ' and ' + @StatusURIList
        Set @myError = 60004
        Goto Done
    End
        

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    -- First update Ingest_Steps_Completed for steps that have already been verified
    --
    UPDATE T_MyEMSL_Uploads
    SET Ingest_Steps_Completed = @ingestStepsCompleted
    WHERE Verified = 1 AND
          Entry_ID IN ( SELECT Entry_ID FROM @StatusEntryIDsTable ) AND
          (Ingest_Steps_Completed Is Null Or Ingest_Steps_Completed < @ingestStepsCompleted)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError > 0
    Begin
        Set @message = 'Error updating Ingest_Steps_Completed for entries with Verified = 1 in StatusURIs ' + 
                       'for StatusURI: ' + @statusURIList + ', dataset ID ' + Cast(@datasetID AS varchar(12))
        Set @myError = 60006
        Goto Done
    End
    
    -- Now update newly verified steps
    --
    UPDATE T_MyEMSL_Uploads
    SET Verified = 1,
        Ingest_Steps_Completed = @ingestStepsCompleted
    WHERE Verified = 0 AND
          Entry_ID IN ( SELECT Entry_ID FROM @StatusEntryIDsTable )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError > 0
    Begin
        Set @message = 'Error updating Ingest_Steps_Completed for entries with Verified = 0 in T_MyEMSL_Uploads ' + 
                       'for StatusURI: ' + @statusURIList + ', dataset ID ' + Cast(@datasetID AS varchar(12))
        Set @myError = 60007
        Goto Done
    End
              
Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in SetMyEMSLUploadVerified'
        
        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
        
        Exec PostLogEntry 'Error', @message, 'SetMyEMSLUploadVerified'
    End    

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[SetMyEMSLUploadVerified] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetMyEMSLUploadVerified] TO [DMS_SP_User] AS [dbo]
GO

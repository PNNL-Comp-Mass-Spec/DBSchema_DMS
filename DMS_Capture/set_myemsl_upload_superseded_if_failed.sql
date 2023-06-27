/****** Object:  StoredProcedure [dbo].[set_myemsl_upload_superseded_if_failed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_myemsl_upload_superseded_if_failed]
/****************************************************
**
**  Desc:
**      Marks one or more failed MyEMSL upload tasks as superseded,
**      meaning a subsequent upload task successfully uploaded the dataset files
**
**      This procedure is called by the ArchiveStatusCheckPlugin if it finds that two
**      tasks uploaded the same files, the first task failed, but the second task succeeded
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/16/2014 mem - Initial version
**          12/18/2014 mem - Added parameter @IngestStepsCompleted
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/27/2023 mem - Update dataset_id validation to support multiple rows in T_MyEMSL_Uploads having the same status_num but different dataset IDs
**                         - Store @ingestStepsCompleted in T_MyEMSL_Uploads if it is larger than the existing value
**
*****************************************************/
(
    @datasetID int,
    @statusNumList varchar(1024),           -- The status numbers in this list must match the specified DatasetID (this is a safety check)
    @ingestStepsCompleted tinyint,          -- Number of ingest steps that were completed for these status nums (assumes that all the status nums completed the same steps)
    @message varchar(512)='' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'set_myemsl_upload_superseded_if_failed', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @DatasetID = IsNull(@DatasetID, 0)
    Set @StatusNumList = IsNull(@StatusNumList, '')
    Set @IngestStepsCompleted = IsNull(@IngestStepsCompleted, 0)

    Set @message = ''

    If @DatasetID <= 0
    Begin
        Set @message = '@DatasetID must be positive; unable to continue'
        Set @myError = 60000
        Goto Done
    End

    If Len(@StatusNumList) = 0
    Begin
        Set @message = '@StatusNumList was empty; unable to continue'
        Set @myError = 60001
        Goto Done
    End

    Declare @StatusNumListTable as Table(StatusNum int NOT NULL, Dataset_ID_Validated tinyint NOT NULL)

    ---------------------------------------------------
    -- Split the StatusNumList on commas
    ---------------------------------------------------

    INSERT INTO @StatusNumListTable (StatusNum, Dataset_ID_Validated)
    SELECT DISTINCT Value, 0
    FROM dbo.parse_delimited_integer_list(@StatusNumList, ',')
    ORDER BY Value

    Declare @StatusNumCount int = 0

    SELECT @StatusNumCount = COUNT(*) FROM @StatusNumListTable

    If IsNull(@StatusNumCount, 0) = 0
    Begin
        Set @message = 'No status nums were found in @StatusNumList; unable to continue'
        Set @myError = 60002
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure the StatusNums in @StatusNumListTable exist in T_MyEMSL_Uploads
    ---------------------------------------------------

    If Exists (SELECT * FROM @StatusNumListTable SL LEFT OUTER JOIN T_MyEMSL_Uploads MU ON MU.StatusNum = SL.StatusNum WHERE MU.Entry_ID IS NULL)
    Begin
        Set @message = 'One or more StatusNums in @StatusNumList were not found in T_MyEMSL_Uploads: ' + @StatusNumList
        Set @myError = 60003
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure the Dataset_ID is correct
    ---------------------------------------------------

    UPDATE @StatusNumListTable
    SET Dataset_ID_Validated = 1
    FROM @StatusNumListTable Target INNER JOIN 
         T_MyEMSL_Uploads MU
           ON Target.StatusNum = MU.StatusNum
    WHERE MU.dataset_id = @datasetID
          
    If Exists (SELECT * FROM @StatusNumListTable WHERE Dataset_ID_Validated = 0)
    Begin
        Set @message = 'One or more StatusNums in @StatusNumList do not have Dataset_ID ' + Convert(varchar(12), @DatasetID) + ' in T_MyEMSL_Uploads: ' + @StatusNumList
        Set @myError = 60004
        Goto Done
    End

    ---------------------------------------------------
    -- Perform the update
    -- Skipping any entries that do not have 0 for ErrorCode or Verified
    ---------------------------------------------------

    UPDATE T_MyEMSL_Uploads
    SET ErrorCode = 101,
        Ingest_Steps_Completed = CASE WHEN @ingestStepsCompleted > Coalesce(Ingest_Steps_Completed, 0)
                                      THEN @ingestStepsCompleted
                                      ELSE Ingest_Steps_Completed
                                 END
    WHERE ErrorCode = 0 AND
          Verified = 0 AND
          Dataset_ID = @datasetID AND
          StatusNum IN ( SELECT StatusNum FROM @StatusNumListTable )

Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in set_myemsl_upload_superseded_if_failed'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        Exec post_log_entry 'Error', @message, 'set_myemsl_upload_superseded_if_failed'
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_myemsl_upload_superseded_if_failed] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_myemsl_upload_superseded_if_failed] TO [DMS_SP_User] AS [dbo]
GO

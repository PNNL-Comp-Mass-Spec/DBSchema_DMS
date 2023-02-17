/****** Object:  StoredProcedure [dbo].[SetMyEMSLUploadSupersededIfFailed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetMyEMSLUploadSupersededIfFailed
/****************************************************
**
**	Desc: 
**		Marks one or more failed MyEMSL upload tasks as superseded,
**		meaning a subsequent upload task successfully uploaded the dataset files
**
**		This procedure is called by the ArchiveStatusCheckPlugin if it finds that two
**		tasks uploaded the same files, the first task failed, but the second task succeeded
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	12/16/2014 mem - Initial version
**			12/18/2014 mem - Added parameter @IngestStepsCompleted
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@DatasetID int,
	@StatusNumList varchar(1024),			-- The status numbers in this list must match the specified DatasetID (this is a safety check)
	@IngestStepsCompleted tinyint,			-- Number of ingest steps that were completed for these status nums (assumes that all the status nums completed the same steps)
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
	Exec @authorized = VerifySPAuthorized 'SetMyEMSLUploadSupersededIfFailed', @raiseError = 1;
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End
		
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
	
	Declare @StatusNumListTable as Table(StatusNum int NOT NULL)
	
	---------------------------------------------------
	-- Split the StatusNumList on commas
	---------------------------------------------------
	
	INSERT INTO @StatusNumListTable (StatusNum)
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
	
	If Exists (Select * FROM T_MyEMSL_Uploads WHERE StatusNum IN (Select StatusNum From @StatusNumListTable) And Dataset_ID <> @DatasetID)
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
	SET ErrorCode = 101
	WHERE ErrorCode = 0 AND
	      Verified = 0 AND
	      StatusNum IN ( SELECT StatusNum FROM @StatusNumListTable )
	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in UpdateSupersededURIs'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		Exec PostLogEntry 'Error', @message, 'UpdateSupersededURIs'
	End	

	Return @myError




GO
GRANT VIEW DEFINITION ON [dbo].[SetMyEMSLUploadSupersededIfFailed] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetMyEMSLUploadSupersededIfFailed] TO [DMS_SP_User] AS [dbo]
GO

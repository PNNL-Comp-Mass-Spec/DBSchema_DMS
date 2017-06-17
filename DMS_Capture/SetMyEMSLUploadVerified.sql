/****** Object:  StoredProcedure [dbo].[SetMyEMSLUploadVerified] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetMyEMSLUploadVerified
/****************************************************
**
**	Desc: 
**		Marks one or more MyEMSL upload tasks as verified by the MyEMSL ingest process
**		This procedure should only be called after the MyEMSL Status page shows "verified" and "SUCCESS" for step 6
**		For example, see https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/2271574/xml
**		              or https://ingest.my.emsl.pnl.gov/myemsl/cgi-bin/status/3268638/xml
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	09/20/2013 mem - Initial version
**			12/19/2014 mem - Added parameter @ingestStepsCompleted
**			05/31/2017 mem - Add logging
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**    
*****************************************************/
(
	@datasetID int,
	@statusNumList varchar(1024),			-- The status numbers in this list must match the specified DatasetID (this is a safety check)
	@ingestStepsCompleted tinyint,			-- Number of ingest steps that were completed for these status nums (assumes that all the status nums completed the same steps)
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
	Exec @authorized = VerifySPAuthorized 'SetMyEMSLUploadVerified', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @datasetID = IsNull(@datasetID, 0)
	Set @statusNumList = IsNull(@statusNumList, '')
	Set @ingestStepsCompleted = IsNull(@ingestStepsCompleted, 0)
	
	Set @message = ''
	
	If @datasetID <= 0
	Begin
		Set @message = '@datasetID must be positive; unable to continue'
		Set @myError = 60000
		Goto Done
	End
	
	If Len(@statusNumList) = 0
	Begin
		Set @message = '@statusNumList was empty; unable to continue'
		Set @myError = 60001
		Goto Done
	End
	
	Declare @StatusNumListTable as Table(StatusNum int NOT NULL)
	
	---------------------------------------------------
	-- Split the StatusNumList on commas
	---------------------------------------------------
	
	INSERT INTO @StatusNumListTable (StatusNum)
	SELECT DISTINCT Value
	FROM dbo.udfParseDelimitedIntegerList(@statusNumList, ',')
	ORDER BY Value

	Declare @StatusNumCount int = 0

	SELECT @StatusNumCount = COUNT(*) FROM @StatusNumListTable
	
	If IsNull(@StatusNumCount, 0) = 0
	Begin
		Set @message = 'No status nums were found in @statusNumList; unable to continue'
		Set @myError = 60002
		Goto Done
	End

	---------------------------------------------------
	-- Make sure the StatusNums in @StatusNumListTable exist in T_MyEMSL_Uploads
	---------------------------------------------------
	
	If Exists (SELECT * FROM @StatusNumListTable SL LEFT OUTER JOIN T_MyEMSL_Uploads MU ON MU.StatusNum = SL.StatusNum WHERE MU.Entry_ID IS NULL)
	Begin
		Set @message = 'One or more StatusNums in @statusNumList were not found in T_MyEMSL_Uploads: ' + @statusNumList
		Set @myError = 60003
		Goto Done
	End
	
	---------------------------------------------------
	-- Make sure the Dataset_ID is correct
	---------------------------------------------------
	
	If Exists (Select * FROM T_MyEMSL_Uploads WHERE StatusNum IN (Select StatusNum From @StatusNumListTable) And Dataset_ID <> @datasetID)
	Begin
		Set @message = 'One or more StatusNums in @statusNumList do not have Dataset_ID ' + Convert(varchar(12), @datasetID) + ' in T_MyEMSL_Uploads: ' + @statusNumList
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
	      StatusNum IN ( SELECT StatusNum FROM @StatusNumListTable ) AND
	      (Ingest_Steps_Completed Is Null Or Ingest_Steps_Completed < @ingestStepsCompleted)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myError > 0
	Begin
		Set @message = 'Error updating Ingest_Steps_Completed for entries with Verified = 1 in T_MyEMSL_Uploads ' + 
		               'for StatusNum: ' + @statusNumList + ', dataset ID ' + Convert(varchar(12), @datasetID)
		Set @myError = 60006
		Goto Done
	End
	
	-- Now update newly verified steps
	--
	UPDATE T_MyEMSL_Uploads
	SET Verified = 1,
	    Ingest_Steps_Completed = @ingestStepsCompleted
	WHERE Verified = 0 AND
	      StatusNum IN ( SELECT StatusNum FROM @StatusNumListTable )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myError > 0
	Begin
		Set @message = 'Error updating Ingest_Steps_Completed for entries with Verified = 0 in T_MyEMSL_Uploads ' + 
		               'for StatusNum: ' + @statusNumList + ', dataset ID ' + Convert(varchar(12), @datasetID)
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

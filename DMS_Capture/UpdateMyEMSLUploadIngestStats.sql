/****** Object:  StoredProcedure [dbo].[UpdateMyEMSLUploadIngestStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateMyEMSLUploadIngestStats
/****************************************************
**
**	Desc: 
**		Updates column Ingest_Steps_Completed for the given MyEMS ingest task
**
**		This procedure is called by the ArchiveStatusCheckPlugin in the DMS Capture Manager
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	12/18/2014 mem - Initial version
**			06/23/2016 mem - Add parameter @fatalError
**			05/31/2017 mem - Update TransactionID in T_MyEMSL_Uploads using @transactionId
**    
*****************************************************/
(
	@datasetID int,
	@statusNum int,							-- The status number must match the specified DatasetID (this is a safety check)
	@ingestStepsCompleted tinyint,			-- Number of ingest steps that were completed for this entry
	@fatalError tinyint = 0,				-- Set to 1 if the ingest failed and the ErrorCode column needs to be set to -1 (if currently 0 or null)
	@transactionId int = 0,					-- Transaction ID (null or 0 if unknown)
	@message varchar(512)='' output
)
As
	set nocount on
	
	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0
	
	Declare @errorCode int = 0
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @datasetID = IsNull(@datasetID, 0)
	Set @statusNum = IsNull(@statusNum, 0)
	Set @ingestStepsCompleted = IsNull(@ingestStepsCompleted, 0)
	Set @fatalError = IsNull(@fatalError, 0)
	Set @transactionId = IsNull(@transactionId, 0)
	
	Set @message = ''
	
	If @datasetID <= 0
	Begin
		Set @message = '@datasetID must be positive; unable to continue'
		Set @myError = 60000
		Goto Done
	End

	---------------------------------------------------
	-- Make sure the @statusNum exists in T_MyEMSL_Uploads
	---------------------------------------------------
	
	If Not Exists (SELECT * FROM T_MyEMSL_Uploads MU WHERE StatusNum = @statusNum)
	Begin
		Set @message = 'StatusNum ' + Cast(@statusNum as varchar(12)) + ' not found in T_MyEMSL_Uploads'
		Set @myError = 60003
		Goto Done
	End
	
	---------------------------------------------------
	-- Make sure the Dataset_ID is correct
	-- Also lookup the current ErrorCode for this upload task
	---------------------------------------------------
	
	SELECT @errorCode = ErrorCode
	FROM T_MyEMSL_Uploads
	WHERE StatusNum = @statusNum AND
	      Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0
	Begin
		Set @message = 'The DatasetID for StatusNum ' + Cast(@statusNum as varchar(12)) + ' is not ' + Cast(@datasetID as varchar(12)) + '; will not update Ingest_Steps_Completed'
		Set @myError = 60004
		Goto Done
	End
	
	---------------------------------------------------
	-- Possibly update the error code
	---------------------------------------------------
	
	If @fatalError > 0 And IsNull(@errorCode, 0) = 0
	Begin
		Set @errorCode = -1
	End
	
	---------------------------------------------------
	-- Perform the update
	---------------------------------------------------
	
	UPDATE T_MyEMSL_Uploads
	SET Ingest_Steps_Completed = @ingestStepsCompleted,
	    ErrorCode = @errorCode,
	    TransactionID = CASE WHEN @transactionId = 0 THEN TransactionID ELSE @transactionId END
	WHERE StatusNum = @statusNum AND
	      (IsNull(Ingest_Steps_Completed, 0) <> @ingestStepsCompleted OR
	       IsNull(ErrorCode, 0) <> IsNull(@errorCode, 0))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myError > 0
	Begin
		Set @message = 'Error updating T_MyEMSL_Uploads for StatusNum ' + Cast(@statusNum as varchar(12))
		Set @myError = 60006
		Goto Done
	End
	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in UpdateMyEMSLUploadIngestStats'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		Exec PostLogEntry 'Error', @message, 'UpdateMyEMSLUploadIngestStats'
	End	

	Return @myError




GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMyEMSLUploadIngestStats] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMyEMSLUploadIngestStats] TO [DMS_SP_User] AS [dbo]
GO

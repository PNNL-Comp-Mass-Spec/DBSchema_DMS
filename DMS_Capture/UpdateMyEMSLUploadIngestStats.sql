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
**    
*****************************************************/
(
	@DatasetID int,
	@StatusNum int,							-- The status number must match the specified DatasetID (this is a safety check)
	@IngestStepsCompleted tinyint,			-- Number of ingest steps that were completed for this entry
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @DatasetID = IsNull(@DatasetID, 0)
	Set @StatusNum = IsNull(@StatusNum, 0)
	Set @IngestStepsCompleted = IsNull(@IngestStepsCompleted, 0)
	
	Set @message = ''
	
	If @DatasetID <= 0
	Begin
		Set @message = '@DatasetID must be positive; unable to continue'
		Set @myError = 60000
		Goto Done
	End

	---------------------------------------------------
	-- Make sure the @StatusNum exists in T_MyEMSL_Uploads
	---------------------------------------------------
	
	If Not Exists (SELECT * FROM T_MyEMSL_Uploads MU WHERE StatusNum = @StatusNum)
	Begin
		Set @message = 'StatusNum ' + Cast(@StatusNum as varchar(12)) + ' not found in T_MyEMSL_Uploads'
		Set @myError = 60003
		Goto Done
	End
	
	---------------------------------------------------
	-- Make sure the Dataset_ID is correct
	---------------------------------------------------
	
	If Not Exists (Select * FROM T_MyEMSL_Uploads WHERE StatusNum = @StatusNum And Dataset_ID = @DatasetID)
	Begin
		Set @message = 'The DatasetID for StatusNum ' + Cast(@StatusNum as varchar(12)) + ' is not ' + Cast(@DatasetID as varchar(12)) + '; will not update Ingest_Steps_Completed'
		Set @myError = 60004
		Goto Done
	End
	 
	---------------------------------------------------
	-- Perform the update
	---------------------------------------------------
	
	UPDATE T_MyEMSL_Uploads
	SET Ingest_Steps_Completed = @IngestStepsCompleted
	WHERE StatusNum = @StatusNum AND
	      IsNull(Ingest_Steps_Completed, 0) <> @IngestStepsCompleted
	
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
GRANT EXECUTE ON [dbo].[UpdateMyEMSLUploadIngestStats] TO [svc-dms] AS [dbo]
GO

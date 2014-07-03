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
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	09/20/2013 mem - Initial version
**    
*****************************************************/
(
	@DatasetID int,
	@StatusNumList varchar(1024),			-- The status numbers in this list must match the specified DatasetID (this is a safety check)
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
	Set @StatusNumList = IsNull(@StatusNumList, '')
	
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
	---------------------------------------------------
	
	UPDATE T_MyEMSL_Uploads
	SET Verified = 1	
	WHERE Verified = 0 AND StatusNum In (SELECT StatusNum FROM @StatusNumListTable)
	
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
GRANT EXECUTE ON [dbo].[SetMyEMSLUploadVerified] TO [svc-dms] AS [dbo]
GO

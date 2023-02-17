/****** Object:  StoredProcedure [dbo].[CheckForMyEMSLErrors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.CheckForMyEMSLErrors
/****************************************************
** 
**	Desc: Looks for anomalies in T_MyEMSL_Uploads
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	12/10/2013 mem - Initial version
**			08/13/2017 mem - Increase the error rate threshold from 1% to 3% since we're now auto-retrying uploads
**    
*****************************************************/
(
	@MostRecentDays int = 2,
	@StartDate datetime = null,		-- Only used if @MostRecentDays is 0 or negative
	@EndDate datetime = null,		-- Only used if @MostRecentDays is 0 or negative
	@LogErrors tinyint = 1,
	@message varchar(255) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Set @message = ''

	-----------------------------------------------
	-- Validate the inputs
	-----------------------------------------------
	--
	Set @MostRecentDays = IsNull(@MostRecentDays, 0)
	Set @StartDate = IsNull(@StartDate, DateAdd(day, -2, GetDate()))

	Set @EndDate = IsNull(@EndDate, GetDate())
	Set @LogErrors = IsNull(@LogErrors, 1)
	
	If @MostRecentDays > 0
	Begin
		Set @EndDate = GetDate()
		Set @StartDate = DateAdd(day, -Abs(@MostRecentDays), @EndDate)		
	End

	-----------------------------------------------
	-- Query the upload stats
	-----------------------------------------------
	--
	
	Declare @UploadAttempts int
	Declare @UploadErrors int
	Declare @UploadErrorRate float = 0
	
	Declare @DatasetFolderUploads int
	Declare @DuplicateUploads int
	Declare @DuplicateRate float = 0
	
	SELECT @UploadErrors = COUNT(*)
	FROM T_MyEMSL_Uploads
	WHERE Entered BETWEEN @StartDate AND @EndDate AND
	      Bytes > 0 AND
	      ErrorCode <> 0
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	
	SELECT @UploadAttempts = COUNT(*)
	FROM T_MyEMSL_Uploads
	WHERE Entered BETWEEN @StartDate AND @EndDate
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	SELECT @DatasetFolderUploads = COUNT(*),
	       @DuplicateUploads = Sum(CASE
	                                   WHEN UploadAttempts > 1 THEN 1
	                                   ELSE 0
	                               END)
	FROM ( SELECT Dataset_ID,
	              Subfolder,
	              COUNT(*) AS UploadAttempts
	       FROM T_MyEMSL_Uploads
	       WHERE Entered BETWEEN @StartDate AND @EndDate
	       GROUP BY Dataset_ID, Subfolder 
	     ) UploadsByDatasetAndFolder


	If @UploadAttempts > 0
		Set @UploadErrorRate = @UploadErrors / CONVERT(float, @UploadAttempts)

	If @DatasetFolderUploads > 0
		Set @DuplicateRate = @DuplicateUploads / CONVERT(float, @DatasetFolderUploads)

	If @UploadErrorRate > 0.03
	Begin
		-- 
		Set @message = 'More than 3% of the uploads to MyEMSL had an error; error rate: ' + Convert(varchar(12), Convert(decimal(9,1), @UploadErrorRate*100)) + '% for ' + Convert(varchar(12), @UploadAttempts) + ' upload attempts'
		
		If @LogErrors <> 0
			Exec PostLogEntry 'Error', @message, 'CheckForMyEMSLErrors'
		Else
			Print @message
			
	End


	If @DuplicateRate > 0.05
	Begin
		-- 
		Set @message = 'More than 5% of the uploads to MyEMSL involved uploading the same dataset and subfolder 2 or more times; duplicate rate: ' + Convert(varchar(12), Convert(int, @DuplicateRate*100)) + '% for ' + Convert(varchar(12), @DatasetFolderUploads) + ' dataset/folder combos'
		
		If @LogErrors <> 0
			Exec PostLogEntry 'Error', @message, 'CheckForMyEMSLErrors'
		Else
			Print @message
			
	End
	
Done:
	
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[CheckForMyEMSLErrors] TO [DDL_Viewer] AS [dbo]
GO

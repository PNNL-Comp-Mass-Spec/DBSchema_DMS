/****** Object:  StoredProcedure [dbo].[HandleDatasetCaptureValidationFailure] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.HandleDatasetCaptureValidationFailure
/****************************************************
**
**	Desc:	This procedure can be used with datasets that
**			are successfully captured but fail the dataset integrity check
**			(.Raw file too small, expected files missing, etc).
**
**			The procedure changes the capture job state to 101
**			then calls HandleDatasetCaptureValidationFailure in DMS5
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	04/28/2011
**			09/13/2011 mem - Updated to support script 'IMSDatasetCapture' in addition to 'DatasetCapture'
**			11/05/2012 mem - Added additional Print statement
**
*****************************************************/
(
	@DatasetNameOrID varchar(255),
	@Comment varchar(255) = 'Bad .raw file',
	@InfoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @DatasetID int
	Declare @DatasetName varchar(255)
	
	Set @DatasetName = ''
	Set @DatasetID = 0

	----------------------------------------
	-- Validate the inputs
	----------------------------------------

	Set @DatasetNameOrID = IsNull(@DatasetNameOrID, '')
	Set @Comment = IsNull(@Comment, '')
	Set @message = ''
	
	If @Comment = ''
		Set @Comment = 'Bad dataset'
		
	If IsNumeric(@DatasetNameOrID) <> 0
	Begin
		----------------------------------------
		-- Lookup the Dataset Name
		----------------------------------------
		
		Set @DatasetID = Convert(int, @DatasetNameOrID)
		
		SELECT @DatasetName = Dataset
		FROM T_Jobs
		WHERE Dataset_ID = @DatasetID AND 
			  Script IN ('DatasetCapture', 'IMSDatasetCapture')
		
		If @DatasetName = ''
		Begin
			set @message = 'Dataset ID not found: ' + @DatasetNameOrID
			Set @myError = 50000
			Print @message
		End

	End
	Else
	Begin	
		----------------------------------------
		-- Lookup the dataset ID
		----------------------------------------
	
		Set @DatasetName = @DatasetNameOrID
				
		SELECT @DatasetID = Dataset_ID
		FROM T_Jobs
		WHERE Dataset = @DatasetName AND 
			  Script IN ('DatasetCapture', 'IMSDatasetCapture')
		
		If @DatasetName = ''
		Begin
			set @message = 'Dataset not found: ' + @DatasetName
			Set @myError = 50001
			Print @message
		End
	End
	
	If @myError = 0
	Begin	
		-- Make sure the DatasetCapture job has failed
		IF NOT EXISTS (SELECT * FROM T_Jobs WHERE Dataset_ID = @DatasetID AND Script IN ('DatasetCapture', 'IMSDatasetCapture') AND State = 5)
		Begin
			Set @message = 'DatasetCapture job for dataset ' + @DatasetName + ' is not in State 5; unable to continue'
			Set @myError = 50002
			Print @message
		End
	End
	
	If @myError = 0
	Begin
		If @infoOnly <> 0
		Begin
			SELECT 'Mark dataset as bad: ' + @comment as Message, *
			FROM T_Jobs
			WHERE Dataset_ID = @DatasetID AND 
			      Script IN ('DatasetCapture', 'IMSDatasetCapture') AND 
			      State = 5
    
		End
		Else
		Begin
	
			UPDATE T_Jobs
			SET State = 101
			WHERE Dataset_ID = @DatasetID AND 
			      Script IN ('DatasetCapture', 'IMSDatasetCapture') AND 
			      State = 5
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
			Begin
				Set @message = 'Unable to update dataset in T_Jobs: ' + @DatasetName
				Set @myError = 50003
				Print @message
			End
			Else
			Begin
				-- Mark the dataset as bad in DMS5
				Exec DMS5.dbo.HandleDatasetCaptureValidationFailure @DatasetID, @Comment, @InfoOnly, ''
				
				Set @message = 'Marked dataset as bad: ' + @DatasetName
				Print @message
				
			End
		End
	
	End

	return @myError

GO

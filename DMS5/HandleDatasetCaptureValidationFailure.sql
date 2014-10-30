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
**			The procedure marks the dataset state as Inactive, 
**			changes the rating to -1 = No Data (Blank/bad),
**			and makes sure a dataset archive entry exists
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	04/28/2011 mem - Initial version
**			10/29/2014 mem - Now alling @Comment to contain a single punctuation mark, which means the comment should not be updated
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
	
	-- Treat the following characters as meaning "do not update the comment"
	If @Comment in (' ', '.', ';', ',', '!', '^')
		Set @Comment = ''
	
	If IsNumeric(@DatasetNameOrID) <> 0
	Begin
		----------------------------------------
		-- Lookup the Dataset Name
		----------------------------------------
		
		Set @DatasetID = Convert(int, @DatasetNameOrID)
		
		SELECT @DatasetName = Dataset_Num
		FROM T_Dataset
		WHERE (Dataset_ID = @DatasetID)
		
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
		FROM T_Dataset
		WHERE (Dataset_Num = @DatasetName)
		
		If @DatasetName = ''
		Begin
			set @message = 'Dataset not found: ' + @DatasetName
			Set @myError = 50001
			Print @message
		End
	End
	
	If @myError = 0
	Begin
	
		If @infoOnly <> 0
		Begin
			SELECT 'Mark dataset as bad: ' + @comment as Message, *
			FROM T_Dataset
			WHERE Dataset_ID = @DatasetID
		End
		Else
		Begin
				
			UPDATE T_Dataset
			SET DS_comment = CASE
			                     WHEN @Comment = '' THEN DS_Comment
			                     ELSE CASE
			                              WHEN IsNull(DS_Comment, '') = '' THEN ''
			                              ELSE DS_Comment + '; '
			                          END + @Comment
			                 END,
			    DS_state_ID = 4,
			    DS_rating = - 1
			WHERE Dataset_ID = @DatasetID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
			Begin
				Set @message = 'Unable to update dataset in T_Dataset: ' + @DatasetName
				Set @myError = 50002
				Print @message
			End
			Else
			Begin
				-- Also update T_Dataset_Archive
				Exec AddArchiveDataset @DatasetID
				
				Set @message = 'Marked dataset as bad: ' + @DatasetName
				Print @message
				
			End
		End
	
	End

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[HandleDatasetCaptureValidationFailure] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[HandleDatasetCaptureValidationFailure] TO [PNL\D3M580] AS [dbo]
GO

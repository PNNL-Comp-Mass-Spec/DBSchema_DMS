/****** Object:  UserDefinedFunction [dbo].[RemoveCaptureErrorsFromString] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.RemoveCaptureErrorsFromString
/****************************************************
**
**	Desc:	Removes common dataset capture error messages
**
**	Returns the updated string
**
**	Auth:	mem
**	Date:	08/08/2017 mem - Initial version
**			08/16/2017 mem - Add "Error running OpenChrom"
**
*****************************************************/
(
	@comment varchar(2048)				-- Dataset comment
)
RETURNS varchar(2048)
AS
Begin
 
	Declare @updatedComment varchar(2048)
	
	Set @updatedComment = dbo.RemoveFromString(dbo.RemoveFromString(dbo.RemoveFromString(dbo.RemoveFromString(dbo.RemoveFromString(dbo.RemoveFromString(
			@comment, 
			'Dataset not ready: Exception validating constant file size'), 
			'Dataset not ready: Exception validating constant folder size'), 
			'Dataset not ready: Folder size changed'), 
			'Dataset not ready: File size changed'),
			'Dataset name matched multiple files; must be a .uimf file, .d folder, or folder with a single .uimf file'),
			'Error running OpenChrom')

	-- Look for text that can have various values following it:
	--   Data file size is less than 50 KB
	--   Data folder size is less than 50 KB'
	--   Dataset data file not found at \\server\share
	Set @updatedComment = dbo.RemoveFromString(dbo.RemoveFromString(dbo.RemoveFromString(
			@updatedComment,
			'Data file size is less than %'),
			'Data folder size is less than %'),
			'Dataset data file not found at %')
		
	Return @updatedComment
	
End

GO

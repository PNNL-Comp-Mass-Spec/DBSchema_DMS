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
**			11/22/2017 mem - Add "Authentication failure: The user name or password is incorrect."
**
*****************************************************/
(
	@comment varchar(2048)				-- Dataset comment
)
RETURNS varchar(2048)
AS
Begin
 
	Declare @updatedComment varchar(2048)
	
	DECLARE @commentsToRemove TABLE
	(
		CommentID int identity(1,1),
		Comment varchar(2048)
	)

    INSERT INTO @commentsToRemove (Comment)
    VALUES ('Dataset not ready: Exception validating constant file size'),
           ('Dataset not ready: Exception validating constant folder size'),
           ('Dataset not ready: Folder size changed'),
           ('Dataset not ready: File size changed'),
           ('Dataset name matched multiple files; must be a .uimf file, .d folder, or folder with a single .uimf file'),
           ('Error running OpenChrom'),
           ('Authentication failure: The user name or password is incorrect.')
    
	Declare @commentID int = 0
	Declare @textToFind varchar(2048)
	Declare @continue int = 1
	
	While @continue > 0
	Begin
		SELECT TOP 1 @commentID = CommentID, 
		             @textToFind = Comment
		FROM @commentsToRemove
		WHERE CommentID > @commentID
		ORDER BY CommentID
		
		If @@rowCount = 0
		Begin
			Set @continue = 0
		End
		Else
		Begin
			Set @updatedComment = dbo.RemoveFromString(@comment, @textToFind)		
		End
	End
	
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

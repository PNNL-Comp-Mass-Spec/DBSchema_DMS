/****** Object:  StoredProcedure [dbo].[EnableDisableArchiveStepTools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.EnableDisableArchiveStepTools
/****************************************************
** 
**	Desc:	Enables or disables archive and archive update step tools
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	05/06/2011 mem - Initial version
**			05/12/2011 mem - Added comment parameter
**    
*****************************************************/
(
	@enable int = 0,
	@DisableComment varchar(128) = '',			-- Optional text to add/remove from the Comment field (added if @enable=0 and removed if @enable=1)
	@infoOnly tinyint = 0,
	@message varchar(255) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @NewState int
	Declare @OldState int
	Declare @Task varchar(24)
		
	Set @message = ''
	
	-----------------------------------------------
	-- Validate the inputs
	-----------------------------------------------
	--
	Set @enable = IsNull(@enable, 0)
	Set @DisableComment = IsNull(@DisableComment, '')
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''
	
	if @enable = 0
	Begin
		Set @NewState = -1
		Set @OldState = 1
		Set @Task = 'Disable'
	End
	Else
	Begin
		Set @NewState = 1
		Set @OldState = -1
		Set @Task = 'Enable'
	End
	
	If @infoOnly <> 0
		SELECT @Task as Task, *
		FROM T_Processor_Tool
		WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate')) AND (Enabled = @OldState)
	Else
	Begin
		-- Update the Enabled column
		--
		UPDATE T_Processor_Tool
		Set Enabled = @NewState
		WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate')) AND (Enabled = @OldState)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @DisableComment <> ''
		Begin
			-- Add or remove @DisableComment from the Comment column
			--
			If @enable = 0
				UPDATE T_Processor_Tool
				SET Comment = CASE WHEN Comment = '' 
				                   THEN @DisableComment
				                   ELSE Comment + '; ' + @DisableComment
				              END
				WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate')) AND
				      (Enabled = @NewState)
			
			Else
			
				UPDATE T_Processor_Tool
				SET Comment = CASE WHEN Comment = @DisableComment 
				                   THEN ''
				                   ELSE Replace(Comment, '; ' + @DisableComment, '')
				              END
				WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate')) AND
				      (Enabled = @NewState)
			
		End
	End
	
	return @myError


GO

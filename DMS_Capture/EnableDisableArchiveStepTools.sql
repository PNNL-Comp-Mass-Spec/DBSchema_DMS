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
**			12/16/2013 mem - Added step tools 'ArchiveVerify' and 'ArchiveStatusCheck'
**			12/11/2015 mem - Clearing comments that start with 'Disabled' when @enable = 1
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
		WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate', 'ArchiveVerify', 'ArchiveStatusCheck')) AND (Enabled = @OldState)
	Else
	Begin
		-- Update the Enabled column
		--
		UPDATE T_Processor_Tool
		Set Enabled = @NewState
		WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate', 'ArchiveVerify', 'ArchiveStatusCheck')) AND (Enabled = @OldState)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @DisableComment <> ''
		Begin
			-- Add or remove @DisableComment from the Comment column
			--
			If @enable = 0
				UPDATE T_Processor_Tool
				SET [Comment] = CASE WHEN [Comment] = '' 
				                   THEN @DisableComment
				                   ELSE [Comment] + '; ' + @DisableComment
				              END
				WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate')) AND
				      (Enabled = @NewState)
			
			Else
			
				UPDATE T_Processor_Tool
				SET [Comment] = CASE WHEN [Comment] = @DisableComment 
				                   THEN ''
				                   ELSE Replace([Comment], '; ' + @DisableComment, '')
				              END
				WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate')) AND
				      (Enabled = @NewState)
			
		End

		If @DisableComment = '' AND @NewState = 1
		Begin
			UPDATE T_Processor_Tool
			SET [Comment] = ''
			WHERE (Tool_Name IN ('DatasetArchive', 'ArchiveUpdate')) AND
			      (Enabled = 1) AND
			      [Comment] LIKE 'Disabled%'

		End
		
	End
	
	return @myError


GO
GRANT EXECUTE ON [dbo].[EnableDisableArchiveStepTools] TO [DMSReader] AS [dbo]
GO

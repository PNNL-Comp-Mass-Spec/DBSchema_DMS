/****** Object:  StoredProcedure [dbo].[EnableDisableStepToolForDebugging] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE EnableDisableStepToolForDebugging
/****************************************************
**
**	Desc: 
**   Bulk enables or disables a step tool to allow for debugging
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	10/22/2013 mem - Initial version
**			11/11/2013 mem - Added parameter @GroupName
**			11/22/2013 mem - Now validating @Tool
**			09/01/2017 mem - Implement functionality of @InfoOnly
**
*****************************************************/
(
	@Tool varchar(512)='',
	@DebugMode tinyint = 0,		-- 1 to disable on pubs to allow for debugging; 0 to enable on pubs
	@GroupName varchar(128) = 'Monroe Development Box',
	@InfoOnly tinyint = 0
)
As
	set nocount on
	
	Declare @myError int = 0
	Declare @myRowCount int = 0

	Declare @GroupID int
	Declare @UpdatedRows int = 0
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @Tool = IsNull(@Tool, '')
	Set @DebugMode = IsNull(@DebugMode, 0)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	
	SELECT @GroupID = Group_ID
	FROM T_Processor_Tool_Groups 
	WHERE Group_Name = @GroupName
	-- 
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0
	Begin
		Print 'Group not found: "' + @GroupName + '"; cannot continue'
		Goto Done
	End

	If Not Exists (SELECT * FROM T_Processor_Tool_Group_Details WHERE Tool_Name = @Tool)
	Begin
		Print 'Tool not found: "' + @Tool + '"; cannot continue'
		Goto Done
	End
	
	If @DebugMode = 0
	Begin -- <a1>
		-- Disable debugging
		
		If @InfoOnly = 0
		Begin			
			UPDATE T_Processor_Tool_Group_Details
			SET Enabled = 1
			WHERE (Tool_Name = @Tool) and Enabled < 0 AND Group_ID <> @GroupID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			Set @UpdatedRows = @UpdatedRows + @myRowCount

			UPDATE T_Processor_Tool_Group_Details
			SET Enabled = 0
			WHERE (Tool_Name = @Tool) and Enabled <> 0 AND Group_ID = @GroupID					
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			Set @UpdatedRows = @UpdatedRows + @myRowCount
			
			If @UpdatedRows = 0
			Begin
				Print 'Debug mode is already disabled for ' + @Tool
			End
			Else
			Begin
				Print 'Debug mode disabled for ' + @Tool + '; updated ' + Cast(@UpdatedRows as varchar(9)) + ' rows'
			End
		End
		Else
		Begin
			SELECT 'Set enabled to 1' as [Action], *
			FROM T_Processor_Tool_Group_Details
			WHERE (Tool_Name = @Tool) and Enabled < 0 AND Group_ID <> @GroupID
			UNION
			SELECT 'Set enabled to 0' as [Action], *
			FROM T_Processor_Tool_Group_Details
			WHERE (Tool_Name = @Tool) and Enabled <> 0 AND Group_ID = @GroupID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
			Begin
				SELECT 'Debug mode is already disabled' AS Comment, *
				FROM T_Processor_Tool_Group_Details
				WHERE (Tool_Name = @Tool) and Enabled > 0
			End
		End				
	End -- </a1>
	Else
	Begin -- <a2>
		-- Enable debugging
		
		If @InfoOnly = 0
		Begin
			UPDATE T_Processor_Tool_Group_Details
			SET Enabled = -1
			WHERE (Tool_Name = @Tool) and Enabled > 0 AND Group_ID <> @GroupID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			Set @UpdatedRows = @UpdatedRows + @myRowCount
			
			UPDATE T_Processor_Tool_Group_Details
			SET Enabled = 1
			WHERE (Tool_Name = @Tool) and Enabled <> 1 AND Group_ID = @GroupID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			Set @UpdatedRows = @UpdatedRows + @myRowCount
			
			If @UpdatedRows = 0
			Begin
				Print 'Debug mode is already enabled for ' + @Tool
			End
			Else
			Begin
				Print 'Debug mode enabled for ' + @Tool + '; updated ' + Cast(@UpdatedRows as varchar(9)) + ' rows'
			End			
		End
		Else
		Begin
			SELECT 'Set enabled to -1' as [Action], *
			FROM T_Processor_Tool_Group_Details
			WHERE (Tool_Name = @Tool) and Enabled > 0 AND Group_ID <> @GroupID
			UNION
			SELECT 'Set enabled to 1' as [Action], *
			FROM T_Processor_Tool_Group_Details
			WHERE (Tool_Name = @Tool) and Enabled <> 1 AND Group_ID = @GroupID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
			Begin
				SELECT 'Debug mode is already enabled' AS Comment, *
				FROM T_Processor_Tool_Group_Details
				WHERE (Tool_Name = @Tool) and Enabled > 0
			End
		End		
	End -- </a2>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[EnableDisableStepToolForDebugging] TO [DDL_Viewer] AS [dbo]
GO

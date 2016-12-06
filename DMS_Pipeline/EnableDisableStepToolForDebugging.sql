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
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	Declare @GroupID int
	Declare @NewValueForPubs tinyint
	
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
	
	If IsNull(@DebugMode, 0) = 0
	Begin
		-- Disable debugging
			
		UPDATE T_Processor_Tool_Group_Details
		SET Enabled = 1
		WHERE (Tool_Name = @Tool) and Enabled < 0 AND Group_ID <> @GroupID

		UPDATE T_Processor_Tool_Group_Details
		SET Enabled = 0
		WHERE (Tool_Name = @Tool) and Enabled <> 0 AND Group_ID = @GroupID
		
	End
	Else
	Begin
		-- Enable debugging
		UPDATE T_Processor_Tool_Group_Details
		SET Enabled = -1
		WHERE (Tool_Name = @Tool) and Enabled > 0 AND Group_ID <> @GroupID

		UPDATE T_Processor_Tool_Group_Details
		SET Enabled = 1
		WHERE (Tool_Name = @Tool) and Enabled <> 1 AND Group_ID = @GroupID
		
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[EnableDisableStepToolForDebugging] TO [DDL_Viewer] AS [dbo]
GO

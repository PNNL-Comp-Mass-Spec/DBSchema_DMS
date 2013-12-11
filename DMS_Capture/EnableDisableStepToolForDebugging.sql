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
**	Date:	10/29/2013 mem - Initial version
**
*****************************************************/
(
	@Tool varchar(512)='',
	@DebugMode tinyint = 0,		-- 1 to disable on pubs to allow for debugging; 0 to enable on pubs
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
	Declare @NewValueForPubs tinyint

	If IsNull(@DebugMode, 0) = 0
	Begin
		-- Disable debugging
			
		UPDATE T_Processor_Tool
		SET Enabled = 1
		WHERE (Tool_Name = @Tool) and Enabled < 0 AND Processor_Name <> 'Monroe_CTM'

		UPDATE T_Processor_Tool
		SET Enabled = 0
		WHERE (Tool_Name = @Tool) and Enabled <> 0 AND Processor_Name = 'Monroe_CTM'
		
	End
	Else
	Begin
		-- Enable debugging
		UPDATE T_Processor_Tool
		SET Enabled = -1
		WHERE (Tool_Name = @Tool) and Enabled > 0 AND Processor_Name <> 'Monroe_CTM'

		UPDATE T_Processor_Tool
		SET Enabled = 1
		WHERE (Tool_Name = @Tool) and Enabled <> 1 AND Processor_Name = 'Monroe_CTM'
		
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO

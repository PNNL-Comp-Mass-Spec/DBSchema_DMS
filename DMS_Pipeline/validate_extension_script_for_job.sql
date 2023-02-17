/****** Object:  StoredProcedure [dbo].[ValidateExtensionScriptForJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ValidateExtensionScriptForJob
/****************************************************
**
**  Desc:	Validates that the given extension script is appropriate for the given job
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	mem
**	Date:	10/22/2010 mem - Initial version
**
*****************************************************/
(
	@Job int,
	@ExtensionScriptName varchar(64),
	@message varchar(512) = '' output
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @CurrentScript varchar(64)
	
	set @message = ''
	
	Declare @CurrentScriptXML xml
	Declare @ExtensionScriptXML xml
	Declare @OverlapCount int
	
	---------------------------------------------------
	-- Determine the script name for the job
	---------------------------------------------------
	-- 

	Set @CurrentScript = ''
	
	SELECT @CurrentScript = Script
	FROM T_Jobs
	WHERE Job = @job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0
	Begin
		-- Job not found in T_Jobs; check T_Jobs_History
		
		-- Find most recent successful historic job
		SELECT TOP 1 @CurrentScript = Script
		FROM T_Jobs_History
		WHERE Job = @job AND State = 4
		ORDER BY Saved Desc
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		If @myRowCount = 0
		Begin
			If Exists (SELECT * FROM T_Jobs_History WHERE Job = @Job)
				Set @message = 'Error: Job not found in T_Jobs, but is present in T_Jobs_History.  However, job is not complete (state <> 4).  Therefore, the job cannot be extended'
			Else
				Set @message = 'Error: Job not found in T_Jobs or T_Jobs_History.'
			
			Set @myError = 62000
			Goto Done			
		End
	End


	---------------------------------------------------
	-- Get the XML for both job scripts
	---------------------------------------------------
	
	SELECT @CurrentScriptXML = Contents
	FROM T_Scripts 
	WHERE Script = @CurrentScript
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		Set @message = 'Error: Current Script (' + @CurrentScript + ') not found in T_Scripts'
		Set @myError = 62001
		Goto Done			
	End
	

	SELECT @ExtensionScriptXML = Contents,
		   @ExtensionScriptName = Script
	FROM T_Scripts 
	WHERE Script = @ExtensionScriptName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		Set @message = 'Error: Extension Script (' + @ExtensionScriptName + ') not found in T_Scripts'
		Set @myError = 62002
		Goto Done			
	End
	
	
	-- Make sure there is no overlap in step numbers between the two scripts
	
	Set @OverlapCount = 0
	
	SELECT @OverlapCount = COUNT(*)
	FROM (	SELECT
				xmlNode.value('@Number', 'nvarchar(128)') Step_Number
			FROM
				@CurrentScriptXML.nodes('//Step') AS R(xmlNode)
		) C
		INNER JOIN 
		(	SELECT
				xmlNode.value('@Number', 'nvarchar(128)') Step_Number
			FROM
				@ExtensionScriptXML.nodes('//Step') AS R(xmlNode)
		) E ON C.Step_Number = E.Step_Number


	If @OverlapCount > 0 
	Begin
		Set @message = 'One or more steps overlap between scripts "' + @CurrentScript + '" and "' + @ExtensionScriptName + '"';
		
		-- Show the conflicting steps
		-- Yes, this query is a bit more complex than was needed
		--
		WITH ConflictQ (Step_Number)
		AS (	SELECT C.Step_Number
				FROM (	SELECT
							xmlNode.value('@Number', 'nvarchar(128)') Step_Number
						FROM
							@CurrentScriptXML.nodes('//Step') AS R(xmlNode)
					) C
					INNER JOIN 
					(	SELECT
							xmlNode.value('@Number', 'nvarchar(128)') Step_Number
						FROM
							@ExtensionScriptXML.nodes('//Step') AS R(xmlNode)
					) E ON C.Step_Number = E.Step_Number
		)	
		SELECT	ScriptSteps.Script, 
				ScriptSteps.Step_Number, 
				ScriptSteps.Step_Tool,
				Case When ConflictQ.Step_Number Is Null Then 0 Else 1 End as Conflict
		FROM (	
			SELECT @CurrentScript AS Script,
				xmlNode.value('@Number', 'nvarchar(128)') Step_Number,
				xmlNode.value('@Tool', 'nvarchar(128)') Step_Tool
			FROM
				@CurrentScriptXML.nodes('//Step') AS R(xmlNode)
			) ScriptSteps LEFT OUTER JOIN ConflictQ ON ScriptSteps.Step_Number = ConflictQ.Step_Number
		UNION
		SELECT	ScriptSteps.Script, 
				ScriptSteps.Step_Number, 
				ScriptSteps.Step_Tool,
				Case When ConflictQ.Step_Number Is Null Then 0 Else 1 End as Conflict
		FROM (	
			SELECT @ExtensionScriptName AS Script,
				xmlNode.value('@Number', 'nvarchar(128)') Step_Number,
				xmlNode.value('@Tool', 'nvarchar(128)') Step_Tool
			FROM
				@ExtensionScriptXML.nodes('//Step') AS R(xmlNode)
			) ScriptSteps LEFT OUTER JOIN ConflictQ ON ScriptSteps.Step_Number = ConflictQ.Step_Number
		ORDER BY Script, Step_Number;
		
		
		Set @myError = 62003
		Goto Done
		
	End


	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
	
Done:
	If @myError <> 0
		Print @Message

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateExtensionScriptForJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateExtensionScriptForJob] TO [Limited_Table_Write] AS [dbo]
GO

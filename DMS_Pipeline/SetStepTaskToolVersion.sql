/****** Object:  StoredProcedure [dbo].[SetStepTaskToolVersion] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SetStepTaskToolVersion
/****************************************************
**
**	Desc: 
**		Record the tool version for the given job step
**		Looks up existing entry in T_Step_Tool_Versions; adds new entry if not defined
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	07/05/2011 mem - Initial version
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**    
*****************************************************/
(
    @job int,
    @step int,
    @ToolVersionInfo varchar(900)
)
As
	set nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0

	declare @ToolVersionID int = 0

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'SetStepTaskToolVersion', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	Set @job = IsNull(@job, 0)
	Set @step = IsNull(@step, 0)
	Set @ToolVersionInfo = IsNull(@ToolVersionInfo, '')
	
	print @ToolVersionInfo
	
	If @ToolVersionInfo = ''
		Set @ToolVersionInfo = 'Unknown'
	
	---------------------------------------------------
	-- Look for @ToolVersionInfo in T_Step_Tool_Versions	
	---------------------------------------------------
	--
	SELECT @ToolVersionID = Tool_Version_ID
	FROM T_Step_Tool_Versions
	WHERE Tool_Version = @ToolVersionInfo
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0
	Begin
		---------------------------------------------------
		-- Add a new entry to T_Step_Tool_Versions
		-- Use a Merge statement to avoid the use of an explicit transaction
		---------------------------------------------------		
		--
		MERGE T_Step_Tool_Versions AS target
		USING 
			(SELECT @ToolVersionInfo AS Tool_Version
			) AS Source ( Tool_Version)
		ON (target.Tool_Version = source.Tool_Version)
		WHEN Not Matched THEN
			INSERT (Tool_Version, Entered)
			VALUES (source.Tool_Version, GetDate());


		SELECT @ToolVersionID = Tool_Version_ID
		FROM T_Step_Tool_Versions
		WHERE Tool_Version = @ToolVersionInfo
		
	End
	
	If @ToolVersionID = 0
	Begin
		---------------------------------------------------
		-- Something went wrong; @ToolVersionInfo wasn't found in T_Step_Tool_Versions 
		-- and we were unable to add it with the Merge statement
		---------------------------------------------------
		
		UPDATE T_Job_Steps
		SET Tool_Version_ID = 1
		WHERE Job = @job AND
		      Step_Number = @step AND
		      Tool_Version_ID IS NULL
	End
	Else
	Begin
		
		If @Job > 0
		Begin		
			UPDATE T_Job_Steps
			SET Tool_Version_ID = @ToolVersionID
			WHERE Job = @job AND
			      Step_Number = @step
			
			UPDATE T_Step_Tool_Versions
			SET Most_Recent_Job = @Job,
			    Last_Used = GetDate()
			WHERE Tool_Version_ID = @ToolVersionID
		End
				
	End
		
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskToolVersion] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskToolVersion] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskToolVersion] TO [svc-dms] AS [dbo]
GO

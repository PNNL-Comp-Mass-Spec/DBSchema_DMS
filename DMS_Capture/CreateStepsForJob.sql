/****** Object:  StoredProcedure [dbo].[CreateStepsForJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CreateStepsForJob
/****************************************************
**
**	Desc: 
**    Make entries in temporary tables:
**      #Job_Steps
**      #Job_Step_Dependencies
**    for the the given job
**    according to definition of scriptXML
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	09/05/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			05/25/2011 mem - Removed @priority parameter and removed priority column from T_Job_Steps
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**    
*****************************************************/
(
	@job int,
	@scriptXML xml,
	@resultsFolderName varchar(128),
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- make set of job steps for job based on scriptXML
	---------------------------------------------------
	--
	INSERT INTO #Job_Steps (
		Job, 
		Step_Number, 
		Step_Tool, 
--		CPU_Load, 
		Dependencies,
		State,
		Output_Folder_Name,
		Special_Instructions,
		Holdoff_Interval_Minutes,
		Retry_Count
	)
	SELECT
		@job AS Job, 
		TS.Step_Number, 
		TS.Step_Tool,
--		CPU_Load,
		0 AS Dependencies,
		1 AS State,
		@resultsFolderName,
		Special_Instructions,
		Holdoff_Interval_Minutes,
		Number_Of_Retries
	FROM 
		(
			SELECT
				xmlNode.value('@Number', 'nvarchar(128)') Step_Number,
				xmlNode.value('@Tool', 'nvarchar(128)') Step_Tool,
				xmlNode.value('@Special', 'nvarchar(128)') Special_Instructions
			FROM
				@scriptXML.nodes('//Step') AS R(xmlNode)
		) TS INNER JOIN 
		T_Step_Tools ON TS.Step_Tool = T_Step_Tools.Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error copying job steps from script'
		goto Done
	end
	  
	---------------------------------------------------
	-- make set of step dependencies based on scriptXML
	---------------------------------------------------
	--
	INSERT INTO #Job_Step_Dependencies
	(
		Step_Number, 
		Target_Step_Number, 
		Condition_Test, 
		Test_Value, 
		Enable_Only, 
		Job
	)
	SELECT 
		xmlNode.value('../@Number', 'nvarchar(24)') Step_Number,
		xmlNode.value('@Step_Number', 'nvarchar(24)') Target_Step_Number,
		xmlNode.value('@Test', 'nvarchar(128)') Condition_Test,
		xmlNode.value('@Value', 'nvarchar(256)') Test_Value,
		isnull(xmlNode.value('@Enable_Only', 'nvarchar(24)'), 0) Enable_Only,
		@job AS Job
	FROM
		@scriptXML.nodes('//Depends_On') AS R(xmlNode)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error copying job step dependencies from script'
		goto Done
	end

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CreateStepsForJob] TO [DDL_Viewer] AS [dbo]
GO

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
**	Date:	08/23/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			12/05/2008 mem - Changed the formatting of the auto-generated results folder name
**			01/14/2009 mem - Increased maximum Value length in @Job_Parameters to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**			01/28/2009 grk - modified for parallelization (http://prismtrac.pnl.gov/trac/ticket/718)
**			01/30/2009 grk - modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**			02/05/2009 grk - modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**			05/25/2011 mem - Removed @priority parameter and removed priority column from T_Job_Steps
**			10/17/2011 mem - Added column Memory_Usage_MB
**			04/16/2012 grk - Added error checking for missing step tools
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
	-- make sure that the tools in the script exist
	---------------------------------------------------
	--
	DECLARE @missingTools VARCHAR(2048) = ''
	--
	SELECT @missingTools = CASE WHEN @missingTools = '' THEN Step_Tool ELSE @missingTools + ', ' + Step_Tool END 
	FROM    ( SELECT    xmlNode.value('@Tool', 'nvarchar(128)') Step_Tool
			  FROM      @scriptXML.nodes('//Step') AS R ( xmlNode )
			) TS
	WHERE   NOT Step_Tool IN ( SELECT [Name] FROM dbo.T_Step_Tools )
	--
	if @missingTools <> ''
	begin
		SET @myError = 51047
		set @message = 'Step tool(s) ' + @missingTools + ' do not exist in tools list' 
		goto Done
	end

	---------------------------------------------------
	-- make set of job steps for job based on scriptXML
	---------------------------------------------------
	--
	INSERT INTO #Job_Steps (
		Job, 
		Step_Number, 
		Step_Tool, 
		CPU_Load, 
		Memory_Usage_MB,
		Shared_Result_Version, 
		Filter_Version, 
		Dependencies,
		State,
		Output_Folder_Name,
		Special_Instructions
	)
	SELECT
		@job AS Job, 
		TS.Step_Number, 
		TS.Step_Tool,
		CPU_Load,
		Memory_Usage_MB,
		Shared_Result_Version,
		Filter_Version,
		0 AS Dependencies,
		1 AS State,
		@resultsFolderName,
		Special_Instructions
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
GRANT VIEW DEFINITION ON [dbo].[CreateStepsForJob] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreateStepsForJob] TO [PNL\D3M578] AS [dbo]
GO

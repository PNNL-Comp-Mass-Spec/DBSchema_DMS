/****** Object:  StoredProcedure [dbo].[CloneJobStep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CloneJobStep
/****************************************************
**
**	Desc: 
**    Clone the given job step in the given job
**    in the temporary tables set up by caller
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	01/28/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/718)
**			02/06/2009 grk - modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**			05/25/2011 mem - Removed priority column from #Job_Steps
**			10/17/2011 mem - Added column Memory_Usage_MB
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**    
*****************************************************/
(
	@job int,
	@pXML xml,
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
	-- Get clone parameters
	---------------------------------------------------

	---------------------------------------------------
	declare @step_to_clone int
	set @step_to_clone = 0
	--
	select @step_to_clone = Step_Number 
	from #Job_Steps 
	where 
		Special_Instructions = 'Clone' AND
		Job = @job
	--
	if @step_to_clone = 0 goto Done

	---------------------------------------------------
	declare @num_clones int
	set @num_clones = 0
	--
	SELECT @num_clones = xmlNode.value('@Value', 'varchar(64)')
	FROM   @pXML.nodes('//Param') AS R(xmlNode)
	WHERE  xmlNode.exist('.[@Name="NumberOfClonedSteps"]') = 1
	--
	if @num_clones = 0 goto Done

	---------------------------------------------------
	declare @clone_step_num_base int
	set @clone_step_num_base = 0
	--
	SELECT @clone_step_num_base = xmlNode.value('@Value', 'varchar(64)')
	FROM   @pXML.nodes('//Param') AS R(xmlNode)
	WHERE  xmlNode.exist('.[@Name="CloneStepRenumberStart"]') = 1
	--
	if @clone_step_num_base = 0 goto Done

	---------------------------------------------------
	-- Clone given job step in given job in the temp
	-- tables
	---------------------------------------------------
	--
	declare @count int
	set @count = 0
	--
	declare @clone_step_number int
	--
	while @count < @num_clones
	begin
	
		set @clone_step_number = @clone_step_num_base + @count

		---------------------------------------------------
		-- copy new job steps from clone step
		---------------------------------------------------
		--
		INSERT INTO #Job_Steps (
			Job,
			Step_Number,
			Step_Tool,
			CPU_Load,
			Memory_Usage_MB,
			Dependencies,
			Shared_Result_Version,
			Filter_Version,
			Signature,
			State,
			Input_Folder_Name,
			Output_Folder_Name
		)
		SELECT 
			Job,
			@clone_step_number as Step_Number,
			Step_Tool,
			CPU_Load,
			Memory_Usage_MB,
			Dependencies,
			Shared_Result_Version,
			Filter_Version,
			Signature,
			State,
			Input_Folder_Name,
			Output_Folder_Name
		FROM   
			#Job_Steps
		WHERE
			Job = @job AND 
			Step_Number = @step_to_clone
		--

		---------------------------------------------------
		-- copy the clone step's dependencies
		---------------------------------------------------
		--
		INSERT INTO #Job_Step_Dependencies (
			Job,
			Step_Number,
			Target_Step_Number,
			Condition_Test,
			Test_Value,
			Enable_Only
		)
		SELECT
			Job,
			@clone_step_number as Step_Number,
			Target_Step_Number,
			Condition_Test,
			Test_Value,
			Enable_Only
		FROM 
			#Job_Step_Dependencies
		WHERE 
			Job = @job AND 
			Step_Number = @step_to_clone


		---------------------------------------------------
		-- copy the dependencies that target the clone step
		---------------------------------------------------
		--
		INSERT INTO #Job_Step_Dependencies (
			Job,
			Step_Number,
			Target_Step_Number,
			Condition_Test,
			Test_Value,
			Enable_Only
		)
		SELECT
			Job,
			Step_Number,
			@clone_step_number as Target_Step_Number,
			Condition_Test,
			Test_Value,
			Enable_Only
		FROM 
			#Job_Step_Dependencies
		WHERE 
			Job = @job AND 
			Target_Step_Number= @step_to_clone

		
		set @count = @count + 1
	end

	---------------------------------------------------
	-- remove original dependencies
	---------------------------------------------------
	--
	DELETE FROM #Job_Step_Dependencies
	WHERE 
		Job = @job AND 
		Target_Step_Number= @step_to_clone

	---------------------------------------------------
	-- remove original dependencies
	---------------------------------------------------
	--
	DELETE FROM #Job_Step_Dependencies
	WHERE 
		Job = @job AND 
		Step_Number = @step_to_clone

	---------------------------------------------------
	-- remove clone step
	---------------------------------------------------
	--
	DELETE FROM #Job_Steps
	WHERE
		Job = @job AND 
		Step_Number = @step_to_clone

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CloneJobStep] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CloneJobStep] TO [Limited_Table_Write] AS [dbo]
GO

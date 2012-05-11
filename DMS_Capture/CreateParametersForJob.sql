/****** Object:  StoredProcedure [dbo].[CreateParametersForJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CreateParametersForJob
/****************************************************
**
**	Desc: 
**  Get parameters for given job into XML format 
**  Make entries in temporary table:
**      #Job_Parameters
**  Update #Job
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	09/05/2009 -- initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**    
*****************************************************/
(
	@job int,
	@datasetID INT,
	@pXML xml output,
	@message varchar(512) output,
	@DebugMode tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- get job parameters from main database
	---------------------------------------------------
	--
	declare @Job_Parameters table (
		[Job] int,
		[Step_Number] int,
		[Section] varchar(64),
		[Name] varchar(128),
		[Value] varchar(2000)		-- Warning: if this field is larger than varchar(2000) then the creation of @s via string concatenation later in this SP will result in corrupted strings (MEM 01/13/2009)
	)
	--
	INSERT INTO @Job_Parameters
		(Job, Step_Number, [Section], [Name], Value)
	execute GetJobParamTable @job, @datasetID		
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting job parameters'
		goto Done
	end
	
	if @DebugMode <> 0
		select * from @Job_Parameters

	---------------------------------------------------
	-- save job parameters as XML into temp table
	---------------------------------------------------
	--
	INSERT INTO #Job_Parameters
	(Job, Parameters)
	Select @job,(select [Step_Number], [Section], [Name], [Value] 
	from @Job_Parameters Param 
	for xml auto)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error copying job param scratch to temp'
		goto Done
	end
/*
	---------------------------------------------------
	-- Update storage server in temp job table
	---------------------------------------------------
	DECLARE @ss VARCHAR(64)
	DECLARE @in VARCHAR(24)
	DECLARE @ic VARCHAR(32)
	DECLARE @mc int
	SELECT @ss = Value FROM @Job_Parameters WHERE Name = 'Storage_Server_Name'
	SELECT @in = Value FROM @Job_Parameters WHERE Name = 'Instrument_Name'
	SELECT @ic = Value FROM @Job_Parameters WHERE Name = 'Instrument_Class'
	SELECT @mc = Value FROM @Job_Parameters WHERE Name = 'Max_Simultaneous_Captures'
	--
	 UPDATE #Jobs
	 SET
	  Storage_Server = @ss,
	  Instrument = @in,
	  Instrument_Class = @ic,
	  Max_Simultaneous_Captures = @mc
	 WHERE
	  Job = @Job
*/
	---------------------------------------------------
	-- return XML
	---------------------------------------------------
	--
	SELECT @pXML = Parameters
	FROM #Job_Parameters
	WHERE Job = @job

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO

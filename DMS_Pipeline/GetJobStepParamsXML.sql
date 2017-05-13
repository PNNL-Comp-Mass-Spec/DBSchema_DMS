/****** Object:  StoredProcedure [dbo].[GetJobStepParamsXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetJobStepParamsXML
/****************************************************
**
**	Desc:
**    Get job step parameters for given job step
**
**	Note: Data comes from table T_Job_Parameters in the DMS_Pipeline DB, not from DMS5
**
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			12/11/2008 grk - initial release
**			01/14/2009 mem - Increased the length of the Value entries extracted from T_Job_Parameters to be 2000 characters (nvarchar(4000)), Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714
**			05/29/2009 mem - Added parameter @DebugMode
**			12/04/2009 mem - Moved the code that defines the job parameters to GetJobStepParamsWork
**			05/11/2017 mem - Add parameter @jobIsRunningRemote
**    
*****************************************************/
(
	@jobNumber int,
	@stepNumber int,
	@parameters varchar(max) output, -- job step parameters (in XML)
    @message varchar(512) output,
    @jobIsRunningRemote tinyint = 0,
    @DebugMode tinyint = 0
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	--

	set @message = ''
	set @parameters = ''

	---------------------------------------------------
	-- Temporary table to hold job parameters
	---------------------------------------------------
	--
	CREATE TABLE #Tmp_JobParamsTable (
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(max)
	)

	---------------------------------------------------
	-- Call GetJobStepParamsWork to populate the temporary table
	---------------------------------------------------
		
	exec @myError = GetJobStepParamsWork @jobNumber, @stepNumber, @message output, @DebugMode
	if @myError <> 0
		Goto Done

	INSERT INTO #Tmp_JobParamsTable (Section, Name, Value)
	VALUES ('StepParameters', 'RunningRemote', IsNull(@jobIsRunningRemote, 0))	
	
	If @DebugMode > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsXML: populate @st table'

	--------------------------------------------------------------
	-- create XML correctly shaped into settings file format
	-- from flat parameter values table (section/item/value)
	--------------------------------------------------------------
	--
	-- need a separate table to hold sections
	-- for outer nested 'for xml' query
	--
	declare @st table (
		[name] varchar(64)
	)
	INSERT INTO @st( [name] )
	SELECT DISTINCT Section
	FROM #Tmp_JobParamsTable


	If @DebugMode > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsXML: populate @x xml variable'

	--------------------------------------------------------------
	-- Run nested query with sections as outer
	-- query and values as inner query to shape XML
	--------------------------------------------------------------
	--
	declare @x xml
	set @x = (
		SELECT 
		  name,
		  (SELECT 
			Name  AS [key],
			IsNull(Value, '') AS [value]
		   FROM   
			#Tmp_JobParamsTable item
		   WHERE item.Section = section.name
		         AND Not item.name Is Null
		   for xml auto, type
		  )
		FROM   
		  @st section
		for xml auto, type
	)

	--------------------------------------------------------------
	-- add XML version of all parameters to parameter list as its own parameter
	--------------------------------------------------------------
	--
	declare @xp varchar(max)
	set @xp = '<sections>' + convert(varchar(max), @x) + '</sections>'

	If @DebugMode > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsXML: exiting'

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	---------------------------------------------------
	-- Return parameters in XML
	---------------------------------------------------
	--
	set @parameters = @xp
	--
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsXML] TO [Limited_Table_Write] AS [dbo]
GO

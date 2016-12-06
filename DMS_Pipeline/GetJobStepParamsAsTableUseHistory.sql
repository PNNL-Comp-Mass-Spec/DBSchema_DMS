/****** Object:  StoredProcedure [dbo].[GetJobStepParamsAsTableUseHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetJobStepParamsAsTableUseHistory
/****************************************************
**
**	Desc:
**    Get job step parameters for given job step
**
**	Note: Data comes from table T_Job_Parameters_History in the DMS_Pipeline DB, not from DMS5
**
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			07/31/2013 mem - initial release
**    
*****************************************************/
(
	@jobNumber int,
	@stepNumber int,
    @message varchar(512) = '' output,
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
	-- Call GetJobStepParamsFromHistoryWork to populate the temporary table
	---------------------------------------------------
		
	exec @myError = GetJobStepParamsFromHistoryWork @jobNumber, @stepNumber, @message output, @DebugMode
	if @myError <> 0
		Goto Done
	
	---------------------------------------------------
	-- Return the contents of #Tmp_JobParamsTable
	---------------------------------------------------
	
	SELECT *
	FROM #Tmp_JobParamsTable
	ORDER BY [Section], [Name], [Value]
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsAsTableUseHistory] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetJobStepParamsAsTableUseHistory] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetJobStepParamsAsTableUseHistory] TO [svc-dms] AS [dbo]
GO

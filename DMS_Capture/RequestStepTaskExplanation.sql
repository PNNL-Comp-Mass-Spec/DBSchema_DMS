/****** Object:  StoredProcedure [dbo].[RequestStepTaskExplanation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestStepTaskExplanation
/****************************************************
**
** Desc:
**  Called from RequestStepTask in info only mode
**  to explain the assignment logic
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	09/07/2009 -- initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**	01/20/2010 grk -- added logic for instrument/processor assignment
**
*****************************************************/
  (
    @processorName VARCHAR(128),
    @processorIsAssigned INT,
    @infoOnly TINYINT,
    @Machine VARCHAR(120)
  )
AS 
  SET nocount ON

	---------------------------------------------------
	-- look at all potential candidate steps
	-- by assignment rules and explain suitability
	---------------------------------------------------
	
  CREATE TABLE #CandidateJobSteps
    (
      Seq SMALLINT IDENTITY(1, 1) NOT NULL,
      Job INT,
      Step_Number INT,
      Job_Priority INT,
      Step_Tool VARCHAR(64),
      Tool_Priority INT,
      Server_OK CHAR(1),
      Bionet_OK CHAR(1),
      Instrument_OK CHAR(1),
      Assignment_OK CHAR(1),
      Retry_Holdoff_OK CHAR(1),
      Candidate CHAR(1) NULL
    )

  INSERT  INTO #CandidateJobSteps
          ( Job,
            Step_Number,
            Job_Priority,
            Step_Tool,
            Tool_Priority,
            Bionet_OK,
            Server_OK,
            Instrument_OK,
            Assignment_OK,
            Retry_Holdoff_OK
          )
         SELECT
            T_Jobs.Job,
            Step_Number,
            T_Jobs.Priority,
            Step_Tool,
            Tool_Priority,
            Bionet_OK,
            CASE WHEN ( Only_On_Storage_Server = 'Y' ) AND ( Storage_Server <> @machine ) THEN 'N' ELSE 'Y' END AS Server_OK,
            CASE WHEN ( #AvailableProcessorTools.Instrument_Capacity_Limited = 'N' OR (NOT ISNULL(Available_Capacity, 1) < 1) ) THEN 'Y' ELSE 'N' END AS Instrument_OK,
            CASE WHEN (
				(Processor_Assignment_Applies = 'N')
				OR
				( 
					( @processorIsAssigned > 0 AND isnull(Assigned_To_This_Processor, 0) > 0 ) 
					OR 
					( @processorIsAssigned = 0 AND isnull(Assigned_To_Any_Processor, 0) = 0 ) 
				)
			) THEN 'Y' ELSE 'N' END 
            AS Assignment_OK,
            CASE WHEN GETDATE() > dbo.T_Job_Steps.Next_Try THEN 'Y' ELSE 'N' END AS Retry_Holdoff_OK
          FROM
            T_Job_Steps
            INNER JOIN dbo.T_Jobs ON T_Job_Steps.Job = T_Jobs.Job
            INNER JOIN #AvailableProcessorTools ON Step_Tool = Tool_Name
            LEFT OUTER JOIN #InstrumentProcessor ON #InstrumentProcessor.Instrument = T_Jobs.Instrument
            LEFT OUTER JOIN #InstrumentLoading ON #InstrumentLoading.Instrument = T_Jobs.Instrument
          WHERE
            T_Job_Steps.State = 2
            AND T_Jobs.State IN (1,2)
          ORDER BY
            T_Jobs.Job,
            Step_Number

		
	---------------------------------------------------
	-- mark actual candidates that were in request table
	---------------------------------------------------
	--

	UPDATE
		#CandidateJobSteps
	SET
		Candidate = 'Y'
	FROM
		#CandidateJobSteps
	INNER JOIN #Tmp_CandidateJobSteps ON #CandidateJobSteps.Job = #Tmp_CandidateJobSteps.Job
									   AND #CandidateJobSteps.Step_Number = #Tmp_CandidateJobSteps.Step_Number


	---------------------------------------------------
	-- dump candidate tables and variables
	---------------------------------------------------
	
	IF @infoOnly > 2
	BEGIN 
	--
	SELECT 'Step tools available to this processor (#AvailableProcessorTools)' AS [Section]

	SELECT
	CONVERT(VARCHAR(24), Tool_Name) AS Tool_Name,
	CONVERT(VARCHAR(12), Tool_Priority) AS Tool_Priority,
	CONVERT(VARCHAR(24), Only_On_Storage_Server) AS Only_On_Storage_Server,
	CONVERT(VARCHAR(24), Instrument_Capacity_Limited) AS Instrument_Capacity_Limited,
	CONVERT(VARCHAR(12), Bionet_OK) AS Bionet_OK,
	CONVERT(VARCHAR(24), Processor_Assignment_Applies) AS Processor_Assignment_Applies
	FROM
	#AvailableProcessorTools
	--
	SELECT 'Instruments subject to CPU loading restrictions (#InstrumentLoading)' AS [Section]

	SELECT
	CONVERT(VARCHAR(24), Instrument) AS Instrument,
	CONVERT(VARCHAR(12), Captures_In_Progress) AS Captures_In_Progress,
	CONVERT(VARCHAR(12), Max_Simultaneous_Captures) AS Max_Simultaneous_Captures,
	CONVERT(VARCHAR(12), Available_Capacity) AS Available_Capacity
	FROM
	#InstrumentLoading

	--
	SELECT 'Instruments assigned to specific processors (#InstrumentProcessor)' AS [Section]

	SELECT 
	CONVERT(VARCHAR(24), Instrument) AS Instrument,
	CONVERT(VARCHAR(24), Assigned_To_This_Processor) AS Assigned_To_This_Processor,
	CONVERT(VARCHAR(24), Assigned_To_Any_Processor) AS Assigned_To_Any_Processor
	FROM 
	#InstrumentProcessor

	END

	--
	SELECT 'Candidate job steps (#CandidateJobSteps)' AS [Section]

	SELECT
		CONVERT(VARCHAR(12), #CandidateJobSteps.Job) AS Job,
		CONVERT(VARCHAR(6), Step_Number) AS Step,
		CONVERT(VARCHAR(24), Step_Tool) AS Tool,
		CONVERT(VARCHAR(20), T_Jobs.Instrument) AS Instrument,
		ISNULL(Candidate, 'N') AS Candidate,

		Bionet_OK,
		Server_OK,
		Instrument_OK,
		Assignment_OK,
		Retry_Holdoff_OK,

		Bionet_Required,
		Only_On_Storage_Server,
		Instrument_Capacity_Limited,
		Processor_Assignment_Applies,
		CONVERT(VARCHAR(8), Holdoff_Interval_Minutes) AS Holdoff_Interval_Minutes,
		CONVERT(VARCHAR(8), Number_Of_Retries) AS Number_Of_Retries,
		CONVERT(VARCHAR(8), Tool_Priority) AS Tool_Pri,
		CONVERT(VARCHAR(8), Job_Priority) AS Job_Pri,
		T_Jobs.Dataset
	FROM
		#CandidateJobSteps
		INNER JOIN dbo.T_Jobs ON T_Jobs.Job = #CandidateJobSteps.Job
		LEFT OUTER JOIN T_Step_Tools ON T_Step_Tools.Name = Step_Tool

GO
GRANT VIEW DEFINITION ON [dbo].[RequestStepTaskExplanation] TO [DDL_Viewer] AS [dbo]
GO

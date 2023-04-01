/****** Object:  StoredProcedure [dbo].[request_ctm_step_task_explanation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[request_ctm_step_task_explanation]
/****************************************************
**
** Desc:
**  Called from request_ctm_step_task in info only mode
**  to explain the assignment logic
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/07/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/20/2010 grk - Added logic for instrument/processor assignment
**          01/27/2017 mem - Clarify some descriptions
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/07/2023 mem - Rename columns in temporary table
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
  (
    @processorName VARCHAR(128),
    @processorIsAssigned INT,
    @infoOnly TINYINT,
    @machine VARCHAR(120)
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
      Step INT,
      Job_Priority INT,
      Tool VARCHAR(64),
      Tool_Priority INT,
      Server_OK CHAR(1),
      Bionet_OK CHAR(1),
      Instrument_OK CHAR(1),
      Assignment_OK CHAR(1),
      Retry_Holdoff_OK CHAR(1),
      Candidate CHAR(1) NULL
    )

  INSERT INTO #CandidateJobSteps
          ( Job,
            Step,
            Job_Priority,
            Tool,
            Tool_Priority,
            Bionet_OK,
            Server_OK,
            Instrument_OK,
            Assignment_OK,
            Retry_Holdoff_OK
          )
         SELECT
            T_Tasks.Job,
            Step,
            T_Tasks.Priority,
            Tool,
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
            CASE WHEN GETDATE() > dbo.T_Task_Steps.Next_Try THEN 'Y' ELSE 'N' END AS Retry_Holdoff_OK
          FROM
            T_Task_Steps
            INNER JOIN dbo.T_Tasks ON T_Task_Steps.Job = T_Tasks.Job
            INNER JOIN #AvailableProcessorTools ON Tool = Tool_Name
            LEFT OUTER JOIN #InstrumentProcessor ON #InstrumentProcessor.Instrument = T_Tasks.Instrument
            LEFT OUTER JOIN #InstrumentLoading ON #InstrumentLoading.Instrument = T_Tasks.Instrument
          WHERE
            T_Task_Steps.State = 2
            AND T_Tasks.State IN (1,2)
          ORDER BY
            T_Tasks.Job,
            Step


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
                                       AND #CandidateJobSteps.Step = #Tmp_CandidateJobSteps.Step


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
    SELECT 'Candidate job steps (#CandidateJobSteps) that could be assigned to this processor, but may be excluded due to a Bionet, Storage Server, Instrument Capacity, or Instrument Lock rule' AS [Section]

    SELECT
        CONVERT(VARCHAR(12), CJS.Job) AS Job,
        CONVERT(VARCHAR(6),  CJS.Step) AS Step,
        CONVERT(VARCHAR(24), CJS.Tool) AS Tool,
        CONVERT(VARCHAR(20), T_Tasks.Instrument) AS Instrument,
        ISNULL(CJS.Candidate, 'N') AS Candidate,

        CJS.Bionet_OK,
        CJS.Server_OK,
        CJS.Instrument_OK,
        CJS.Assignment_OK,
        CJS.Retry_Holdoff_OK,

        CJS.Bionet_Required,
        CJS.Only_On_Storage_Server,
        CJS.Instrument_Capacity_Limited,
        CJS.Processor_Assignment_Applies,
        CONVERT(VARCHAR(8), CJS.Holdoff_Interval_Minutes) AS Holdoff_Interval_Minutes,
        CONVERT(VARCHAR(8), CJS.Number_Of_Retries) AS Number_Of_Retries,
        CONVERT(VARCHAR(8), CJS.Tool_Priority) AS Tool_Pri,
        CONVERT(VARCHAR(8), CJS.Job_Priority) AS Job_Pri,
        T_Tasks.Dataset
    FROM
        #CandidateJobSteps CJS
        INNER JOIN dbo.T_Tasks ON T_Tasks.Job = CJS.Job
        LEFT OUTER JOIN T_Step_Tools ON T_Step_Tools.Name = Tool

GO
GRANT VIEW DEFINITION ON [dbo].[request_ctm_step_task_explanation] TO [DDL_Viewer] AS [dbo]
GO

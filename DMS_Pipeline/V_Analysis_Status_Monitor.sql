/****** Object:  View [dbo].[V_Analysis_Status_Monitor] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Status_Monitor]
AS
SELECT LP.ID AS Processor_ID,
       PS.Processor_Name,
       dbo.GetProcessorStepToolList(PS.Processor_Name) AS Tools,
       ISNULL(PS.Mgr_Status, 'Unknown_Status') AS Mgr_Status,
       PS.Job,
       PS.Job_Step,
       PS.Step_Tool,
       PS.Dataset,
       PS.Duration_Hours,
       PS.Progress,
       PS.Spectrum_Count AS DS_Scan_Count,
       PS.Most_Recent_Job_Info,
       PS.Most_Recent_Log_Message,
       PS.Most_Recent_Error_Message,
       PS.Status_Date,
       CONVERT(decimal(9, 1), DATEDIFF(SECOND, PS.Status_Date, GETDATE()) / 60.0) AS 
         Last_CPU_Status_Minutes
FROM dbo.T_Local_Processors AS LP
     RIGHT OUTER JOIN dbo.T_Processor_Status AS PS
       ON LP.Processor_Name = PS.Processor_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Status_Monitor] TO [DDL_Viewer] AS [dbo]
GO

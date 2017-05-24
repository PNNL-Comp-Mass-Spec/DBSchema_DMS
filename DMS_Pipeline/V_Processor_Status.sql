/****** Object:  View [dbo].[V_Processor_Status] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Status]
AS
SELECT PS.Processor_Name,
       ISNULL(PS.Mgr_Status, 'Unknown_Status') AS Mgr_Status,
       ISNULL(PS.Task_Status, 'Unknown_Status') AS Task_Status,
       ISNULL(PS.Task_Detail_Status, 'Unknown_Status') AS Task_Detail_Status,
       CONVERT(decimal(9, 1), DATEDIFF(second, Status_Date, GETDATE()) / 60.0) AS LastCPUStatus_Minutes,
       PS.Job,
       PS.Job_Step,
       CONVERT(decimal(9, 2), PS.Progress) AS Progress,
       CONVERT(decimal(9, 2), PS.Duration_Hours) AS Duration_Hours,
       CASE
           WHEN PS.Progress > 0 THEN CONVERT(decimal(9, 2), PS.Duration_Hours / (PS.Progress / 100.0) - PS.Duration_Hours)
           ELSE 0
       END AS Hours_Remaining,
       PS.Step_Tool,
       PS.Dataset,
       PS.Current_Operation,
       PS.CPU_Utilization,
       PS.Free_Memory_MB,
	   PS.Process_ID,
       PS.Most_Recent_Job_Info,
       PS.Most_Recent_Log_Message,
       PS.Most_Recent_Error_Message,
       PS.Status_Date,
       PS.Remote_Manager,
	   M.Enabled as Machine_Enabled
FROM dbo.T_Processor_Status AS PS
     LEFT OUTER JOIN T_Local_Processors LP
       ON PS.Processor_Name = LP.Processor_Name
     LEFT OUTER JOIN T_Machines M
       ON LP.Machine = M.Machine          
WHERE (Monitor_Processor <> 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Status] TO [DDL_Viewer] AS [dbo]
GO

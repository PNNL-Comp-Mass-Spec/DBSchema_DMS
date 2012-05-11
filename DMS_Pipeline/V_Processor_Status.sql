/****** Object:  View [dbo].[V_Processor_Status] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Processor_Status
AS
SELECT Processor_Name,
       ISNULL(PS.Mgr_Status, 'Unknown_Status') AS Mgr_Status,
       ISNULL(PS.Task_Status, 'Unknown_Status') AS Task_Status,
       ISNULL(PS.Task_Detail_Status, 'Unknown_Status') AS Task_Detail_Status,
       CONVERT(decimal(9, 1), DATEDIFF(second, Status_Date, GETDATE()) / 60.0) AS LastCPUStatus_Minutes,
       Job,
       Job_Step,
       CONVERT(decimal(9, 2), Progress) AS Progress,
       CONVERT(decimal(9, 2), Duration_Hours) AS Duration_Hours,
       CASE
           WHEN PS.Progress > 0 THEN CONVERT(decimal(9, 2), PS.Duration_Hours / (PS.Progress / 100.0) - PS.Duration_Hours)
           ELSE 0
       END AS Hours_Remaining,
       Step_Tool,
       Dataset,
       Current_Operation,
       CPU_Utilization,
       Free_Memory_MB,
       Most_Recent_Job_Info,
       Most_Recent_Log_Message,
       Most_Recent_Error_Message,
       Status_Date,
       Remote_Status_Location
FROM dbo.T_Processor_Status AS PS
WHERE (Monitor_Processor <> 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Status] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Status] TO [PNL\D3M580] AS [dbo]
GO

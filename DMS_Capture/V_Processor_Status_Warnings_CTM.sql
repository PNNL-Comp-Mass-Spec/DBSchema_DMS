/****** Object:  View [dbo].[V_Processor_Status_Warnings_CTM] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Status_Warnings_CTM]
AS
SELECT PS.Processor_Name,
       ISNULL(PS.Mgr_Status, 'Unknown_Status') AS Mgr_Status,
       ISNULL(PS.Task_Status, 'Unknown_Status') AS Task_Status,
       CONVERT(decimal(9, 2), DATEDIFF(MINUTE, PS.Status_Date, GETDATE()) / 60.0) AS Last_Status_Hours,
       PS.Status_Date,
       PS.Most_Recent_Job_Info,
       PS.Most_Recent_Log_Message,
       PS.Most_Recent_Error_Message,
       ISNULL(PS.Task_Detail_Status, 'Unknown_Status') AS Task_Detail_Status
FROM dbo.T_Processor_Status AS PS
     LEFT OUTER JOIN ( SELECT Processor_Name,
                              'Stale status' AS Status_State
                       FROM dbo.T_Processor_Status AS PS
                       WHERE (Status_Date >= DATEADD(DAY, -21, GETDATE())) AND
                             (Status_Date < DATEADD(HOUR, -4, GETDATE())) 
                     ) AS StaleQ
       ON PS.Processor_Name = StaleQ.Processor_Name
WHERE PS.Monitor_Processor <> 0 AND
      ((PS.Status_Date >= DATEADD(DAY, -21, GETDATE()) AND
        PS.Mgr_Status LIKE '%Error' OR PS.Mgr_Status LIKE 'Disabled%') OR
       (NOT StaleQ.Status_State IS NULL))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Status_Warnings_CTM] TO [DDL_Viewer] AS [dbo]
GO

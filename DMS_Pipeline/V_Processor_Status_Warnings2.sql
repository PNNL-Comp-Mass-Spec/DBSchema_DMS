/****** Object:  View [dbo].[V_Processor_Status_Warnings2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Status_Warnings2]
AS
SELECT Processor_Name,
       Mgr_Status,
       Task_Status,
       Last_Status_Hours,
       Status_Date,
       Most_Recent_Job_Info,
       Most_Recent_Log_Message,
       Most_Recent_Error_Message,
       Task_Detail_Status,
       Job AS Most_Recent_Job,
       Dataset,
       Step,
       Script,
       Tool,
       State_Name,
       State,
       Start,
       Finish,
       RunTime_Minutes,
       Last_CPU_Status_Minutes,
       Job_Progress,
       RunTime_Predicted_Hours
FROM ( SELECT *,
              Row_Number() OVER ( PARTITION BY Processor_Name ORDER BY Start DESC ) AS StartRank
       FROM V_Processor_Status_Warnings PS
            LEFT OUTER JOIN V_Job_Steps JS
              ON PS.Processor_Name = JS.Processor 
     ) LookupQ
WHERE StartRank = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Status_Warnings2] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Machine_Status_Last24Hours] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Machine_Status_Last24Hours]
AS
SELECT StatusQ.*,
       ISNULL(ActiveToolQ.JobCount, 0) AS Active_Tool_Count,
       CASE
           WHEN ISNULL(ActiveToolQ.JobCount, 0) = 0 THEN ''
           WHEN ISNULL(ActiveToolQ.JobCount, 0) = 1 THEN ActiveToolQ.Step_Tool_First
           ELSE ActiveToolQ.Step_Tool_First + ' & ' + ActiveToolQ.Step_Tool_Last
       END AS Active_Tool_Name
FROM ( SELECT PTG.Group_Name,
              MS.Machine,
              MAX(MS.Free_Memory_MB) AS Free_Memory_MB_Max,
              MAX(MS.Processor_Count_Active) AS Processor_Count_Active_Max
       FROM T_Machine_Status_History MS
            INNER JOIN T_Machines M
              ON MS.Machine = M.Machine
            INNER JOIN T_Processor_Tool_Groups PTG
              ON M.ProcTool_Group_ID = PTG.Group_ID
       WHERE (DATEDIFF(HOUR, MS.Posting_Time, GETDATE()) <= 24)
       GROUP BY MS.Machine, PTG.Group_Name ) StatusQ

     LEFT OUTER JOIN ( SELECT LP.Machine,
                              COUNT(*) AS JobCount,
                              MIN(Step_Tool) AS Step_Tool_First,
                              MAX(Step_Tool) AS Step_Tool_Last
                       FROM T_Local_Processors LP
                            INNER JOIN T_Job_Steps JS
                              ON JS.Processor = LP.Processor_Name
                       WHERE JS.State = 4
                       GROUP BY LP.Machine ) ActiveToolQ
       ON StatusQ.Machine = ActiveToolQ.Machine

GO
GRANT VIEW DEFINITION ON [dbo].[V_Machine_Status_Last24Hours] TO [DDL_Viewer] AS [dbo]
GO

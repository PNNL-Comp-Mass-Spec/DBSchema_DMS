/****** Object:  View [dbo].[V_Processor_Status_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Processor_Status_Summary]
AS
SELECT iq.Machine
      ,CASE 
          WHEN iq.Running = 0 AND iq.Idle = 0 AND iq.Errored = 0 THEN 'Disabled'
          WHEN iq.Running = 0 AND iq.Errored > 0 THEN 'Idle, Errored'
          WHEN iq.Running > 0 AND iq.Errored > 0 THEN 'Running, Errored'
          WHEN iq.Running = 0 THEN 'Idle'
          ELSE 'Running'
       END AS Status
      ,iq.Running
      ,iq.Idle
      ,iq.Errored
      ,iq.Disabled
FROM (SELECT 
             LP.Machine AS Machine
            ,SUM(CASE WHEN PS.Mgr_Status = 'running' THEN 1 ELSE 0 END) AS Running
            ,SUM(CASE WHEN PS.Mgr_Status = 'stopped' THEN 1 ELSE 0 END) AS Idle
            ,SUM(CASE WHEN PS.Mgr_Status = 'stopped error' THEN 1 ELSE 0 END) AS Errored
            -- Can have 'Disabled MC' or 'Disabled Local', we don't care which it is.
            ,SUM(CASE WHEN PS.Mgr_Status LIKE 'disabled%' THEN 1 ELSE 0 END) AS Disabled
      FROM dbo.T_Processor_Status AS PS 
           LEFT OUTER JOIN T_Local_Processors LP
             ON PS.Processor_Name = LP.Processor_Name
      WHERE (Monitor_Processor <> 0)
      GROUP BY LP.Machine
     ) AS iq


GO

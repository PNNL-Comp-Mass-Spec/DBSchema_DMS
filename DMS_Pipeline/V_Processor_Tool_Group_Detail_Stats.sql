/****** Object:  View [dbo].[V_Processor_Tool_Group_Detail_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Tool_Group_Detail_Stats]
AS
SELECT PTG.Group_ID,
       PTG.Group_Name,
       PTG.Enabled AS Group_Enabled,
       PTG.[Comment] AS [Comment],
       PTGD.Tool_Name,
       PTGD.Priority,
       PTGD.Enabled,
       COUNT(*) AS Managers
FROM T_Machines M
     INNER JOIN T_Local_Processors LP
       ON M.Machine = LP.Machine
     INNER JOIN T_Processor_Tool_Groups PTG
       ON M.ProcTool_Group_ID = PTG.Group_ID
     INNER JOIN T_Processor_Tool_Group_Details PTGD
       ON PTG.Group_ID = PTGD.Group_ID AND
          LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
GROUP BY PTG.Group_ID
         , PTG.Group_Name, PTG.Enabled, PTG.Comment, PTGD.Tool_Name, PTGD.Priority, PTGD.Enabled



GO

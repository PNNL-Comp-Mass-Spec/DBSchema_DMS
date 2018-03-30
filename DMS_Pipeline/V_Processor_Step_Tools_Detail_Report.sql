/****** Object:  View [dbo].[V_Processor_Step_Tools_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Step_Tools_Detail_Report]
AS
SELECT LP.Processor_Name,
       PTGD.Tool_Name,
       PTGD.Priority,
       PTGD.Enabled,
       PTGD.[Comment],
       ST.CPU_Load As Tool_CPU_Load,
       LP.Latest_Request,
       LP.Manager_Version,
       LP.WorkDir_AdminShare,
       LP.ID As Proc_ID,
       LP.State AS Processor_State,
       M.Machine,
       M.Total_CPUs,
       M.CPUs_Available,
       M.Total_Memory_MB,
       M.Memory_Available,
       M.[Comment] AS Machine_Comment,
       PTG.Group_ID,
       PTG.Group_Name,
       PTG.Enabled AS Group_Enabled,
       PTG.[Comment] AS Group_Comment
FROM T_Machines AS M
     INNER JOIN T_Local_Processors AS LP
       ON M.Machine = LP.Machine
     INNER JOIN T_Processor_Tool_Groups AS PTG
       ON M.ProcTool_Group_ID = PTG.Group_ID
     INNER JOIN T_Processor_Tool_Group_Details AS PTGD
       ON PTG.Group_ID = PTGD.Group_ID AND
          LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
     INNER JOIN T_Step_Tools AS ST
       ON PTGD.Tool_Name = ST.Name
WHERE M.Enabled > 0


GO

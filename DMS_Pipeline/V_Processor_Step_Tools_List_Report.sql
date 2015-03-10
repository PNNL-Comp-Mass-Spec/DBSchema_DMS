/****** Object:  View [dbo].[V_Processor_Step_Tools_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Processor_Step_Tools_List_Report]
AS
SELECT LP.Processor_Name,
       PTGD.Tool_Name,
       PTGD.Priority,
       PTGD.Enabled,
       PTGD.Comment,
       LP.Latest_Request,
       LP.ID,
       LP.State AS Processor_State,
       M.Machine,
       M.Total_CPUs,
       PTG.Group_ID,
       PTG.Group_Name,
       PTG.Enabled AS Group_Enabled
FROM T_Machines M
     INNER JOIN T_Local_Processors LP
       ON M.Machine = LP.Machine
     INNER JOIN T_Processor_Tool_Groups PTG
       ON M.ProcTool_Group_ID = PTG.Group_ID
     INNER JOIN T_Processor_Tool_Group_Details PTGD
       ON PTG.Group_ID = PTGD.Group_ID AND
          LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
     INNER JOIN T_Step_Tools ST
       ON PTGD.Tool_Name = ST.Name
WHERE M.Enabled > 0




GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Step_Tools_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Step_Tools_List_Report] TO [PNL\D3M580] AS [dbo]
GO

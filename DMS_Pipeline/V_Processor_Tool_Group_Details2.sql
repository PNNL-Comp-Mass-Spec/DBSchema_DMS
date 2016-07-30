/****** Object:  View [dbo].[V_Processor_Tool_Group_Details2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Tool_Group_Details2]
AS
SELECT PTGD.*,
       M.Machine,
       LP.Processor_Name AS Processor
FROM T_Local_Processors LP
     INNER JOIN T_Machines M
       ON LP.Machine = M.Machine
     INNER JOIN V_Processor_Tool_Group_Details PTGD
       ON M.ProcTool_Group_ID = PTGD.Group_ID AND
          LP.ProcTool_Mgr_ID = PTGD.Mgr_ID


GO

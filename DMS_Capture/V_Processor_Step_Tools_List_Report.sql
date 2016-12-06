/****** Object:  View [dbo].[V_Processor_Step_Tools_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Step_Tools_List_Report]
AS
SELECT     LP.Processor_Name, dbo.T_Processor_Tool.Tool_Name, dbo.T_Processor_Tool.Priority, dbo.T_Processor_Tool.Enabled, 
                      dbo.T_Processor_Tool.Comment, LP.State AS Processor_State, M.Machine, M.Total_CPUs, M.Bionet_Available, LP.Latest_Request
FROM         dbo.T_Machines AS M RIGHT OUTER JOIN
                      dbo.T_Processor_Tool INNER JOIN
                      dbo.T_Step_Tools AS ST ON dbo.T_Processor_Tool.Tool_Name = ST.Name LEFT OUTER JOIN
                      dbo.T_Local_Processors AS LP ON dbo.T_Processor_Tool.Processor_Name = LP.Processor_Name ON M.Machine = LP.Machine
WHERE M.Enabled > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Step_Tools_List_Report] TO [DDL_Viewer] AS [dbo]
GO

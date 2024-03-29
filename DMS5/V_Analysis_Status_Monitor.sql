/****** Object:  View [dbo].[V_Analysis_Status_Monitor] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Status_Monitor
AS
SELECT     dbo.T_Analysis_Job_Processors.ID, dbo.T_Analysis_Job_Processors.Processor_Name AS Name, 
                      dbo.get_aj_processor_analysis_tool_list(dbo.T_Analysis_Job_Processors.ID) AS Tools, 
                      dbo.get_aj_processor_membership_in_groups_list(dbo.T_Analysis_Job_Processors.ID, 1) AS EnabledGroups, 
                      dbo.get_aj_processor_membership_in_groups_list(dbo.T_Analysis_Job_Processors.ID, 0) AS DisabledGroups, 
                      dbo.T_Analysis_Status_Monitor_Params.StatusFileNamePath, dbo.T_Analysis_Status_Monitor_Params.CheckBoxState, 
                      dbo.T_Analysis_Status_Monitor_Params.UseForStatusCheck
FROM         dbo.T_Analysis_Job_Processors INNER JOIN
                      dbo.T_Analysis_Status_Monitor_Params ON dbo.T_Analysis_Job_Processors.ID = dbo.T_Analysis_Status_Monitor_Params.ProcessorID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Status_Monitor] TO [DDL_Viewer] AS [dbo]
GO

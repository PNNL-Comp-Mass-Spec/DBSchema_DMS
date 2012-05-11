/****** Object:  View [dbo].[V_Analysis_Status_Monitor] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Status_Monitor
AS
SELECT     dbo.T_Analysis_Job_Processors.ID, dbo.T_Analysis_Job_Processors.Processor_Name AS Name, 
                      dbo.GetAJProcessorAnalysisToolList(dbo.T_Analysis_Job_Processors.ID) AS Tools, 
                      dbo.GetAJProcessorMembershipInGroupsList(dbo.T_Analysis_Job_Processors.ID, 1) AS EnabledGroups, 
                      dbo.GetAJProcessorMembershipInGroupsList(dbo.T_Analysis_Job_Processors.ID, 0) AS DisabledGroups, 
                      dbo.T_Analysis_Status_Monitor_Params.StatusFileNamePath, dbo.T_Analysis_Status_Monitor_Params.CheckBoxState, 
                      dbo.T_Analysis_Status_Monitor_Params.UseForStatusCheck
FROM         dbo.T_Analysis_Job_Processors INNER JOIN
                      dbo.T_Analysis_Status_Monitor_Params ON dbo.T_Analysis_Job_Processors.ID = dbo.T_Analysis_Status_Monitor_Params.ProcessorID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Status_Monitor] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Status_Monitor] TO [PNL\D3M580] AS [dbo]
GO

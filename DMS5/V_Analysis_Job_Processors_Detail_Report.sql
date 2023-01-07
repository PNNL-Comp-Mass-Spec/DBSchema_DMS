/****** Object:  View [dbo].[V_Analysis_Job_Processors_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_Detail_Report
AS
SELECT id, state, processor_name, machine, notes,
       dbo.GetAJProcessorMembershipInGroupsList(ID, 1) AS enabled_groups,
       dbo.GetAJProcessorMembershipInGroupsList(ID, 0) AS disabled_groups,
       dbo.GetAJProcessorAnalysisToolList(ID) AS analysis_tools
FROM dbo.T_Analysis_Job_Processors


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO

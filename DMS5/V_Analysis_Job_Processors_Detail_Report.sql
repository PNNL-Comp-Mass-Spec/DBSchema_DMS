/****** Object:  View [dbo].[V_Analysis_Job_Processors_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_Detail_Report
AS
SELECT id, state, processor_name, machine, notes,
       dbo.get_aj_processor_membership_in_groups_list(ID, 1) AS enabled_groups,
       dbo.get_aj_processor_membership_in_groups_list(ID, 0) AS disabled_groups,
       dbo.get_aj_processor_analysis_tool_list(ID) AS analysis_tools
FROM dbo.T_Analysis_Job_Processors

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO

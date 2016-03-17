/****** Object:  View [dbo].[V_Analysis_Job_Processors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_List_Report
AS
SELECT     ID, State, Processor_Name AS Name, Machine, dbo.GetAJProcessorAnalysisToolList(ID) AS [Analysis Tools], Notes, 
                      dbo.GetAJProcessorMembershipInGroupsList(ID, 1) AS [Enabled Groups], dbo.GetAJProcessorMembershipInGroupsList(ID, 0) 
                      AS [Disabled Groups]
FROM         dbo.T_Analysis_Job_Processors

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_List_Report] TO [PNL\D3M580] AS [dbo]
GO

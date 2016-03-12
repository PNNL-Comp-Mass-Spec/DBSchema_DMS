/****** Object:  View [dbo].[V_Analysis_Job_Processors_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_Detail_Report
AS
SELECT ID, State, Processor_Name AS [Processor Name], Machine, 
    Notes, dbo.GetAJProcessorMembershipInGroupsList(ID, 1) 
    AS [Enabled Groups], 
    dbo.GetAJProcessorMembershipInGroupsList(ID, 0) 
    AS [Disabled Groups], dbo.GetAJProcessorAnalysisToolList(ID) 
    AS AnalysisTools
FROM dbo.T_Analysis_Job_Processors

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO

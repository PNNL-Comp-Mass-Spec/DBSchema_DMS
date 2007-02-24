/****** Object:  View [dbo].[V_Analysis_Job_Processors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_List_Report
AS
SELECT ID, State, Processor_Name AS Name, Machine, Notes, 
    dbo.GetAJProcessorMembershipInGroupsList(ID, 1) 
    AS [Enabled Groups], 
    dbo.GetAJProcessorMembershipInGroupsList(ID, 0) 
    AS [Disabled Groups], dbo.GetAJProcessorAnalysisToolList(ID) 
    AS [Analysis Tools]
FROM dbo.T_Analysis_Job_Processors

GO

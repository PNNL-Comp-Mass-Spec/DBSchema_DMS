/****** Object:  View [dbo].[V_Analysis_Job_Processors_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_Detail_Report
AS
SELECT     ID, State, Processor_Name AS [Processor Name], Machine, Notes, dbo.GetAJProcessorMembershipInGroupsList(ID) AS [Group Membership]
FROM         dbo.T_Analysis_Job_Processors

GO

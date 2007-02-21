/****** Object:  View [dbo].[V_Analysis_Job_Processors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_List_Report
AS
SELECT     ID, State, Processor_Name AS Name, Machine, Notes, dbo.GetAJProcessorMembershipInGroupsList(ID) AS [Group Membership]
FROM         dbo.T_Analysis_Job_Processors

GO

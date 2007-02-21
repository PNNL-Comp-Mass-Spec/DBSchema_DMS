/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Membership_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_Membership_List_Report
AS
SELECT     dbo.T_Analysis_Job_Processor_Group_Membership.Processor_ID AS ID, dbo.T_Analysis_Job_Processors.Processor_Name AS Name, 
                      dbo.T_Analysis_Job_Processor_Group_Membership.Membership_Enabled AS [Membership Enabled], dbo.T_Analysis_Job_Processors.Machine, 
                      dbo.T_Analysis_Job_Processors.Notes, dbo.T_Analysis_Job_Processor_Group_Membership.Processor_Group_ID AS [#GroupID], 
                      dbo.GetAJProcessorMembershipInGroupsList(dbo.T_Analysis_Job_Processors.ID) AS [Group Membership]
FROM         dbo.T_Analysis_Job_Processor_Group_Membership INNER JOIN
                      dbo.T_Analysis_Job_Processors ON dbo.T_Analysis_Job_Processor_Group_Membership.Processor_ID = dbo.T_Analysis_Job_Processors.ID

GO

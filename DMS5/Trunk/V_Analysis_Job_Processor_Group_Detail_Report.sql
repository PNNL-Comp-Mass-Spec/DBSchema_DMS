/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_Detail_Report
AS
SELECT     ID, Group_Name AS [Group Name], Group_Enabled AS [Group Enabled], Available_For_General_Processing AS [General Processing], 
                      Group_Description AS [Group Description], Group_Created AS [Group Created], dbo.GetAJProcessorGroupMembershipList(ID) AS Members, 
                      dbo.GetAJProcessorGroupAssociatedJobs(ID) AS [Associated Jobs]
FROM         dbo.T_Analysis_Job_Processor_Group

GO

/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_List_Report
AS
SELECT     ID, Group_Name AS [Group Name], Group_Enabled AS [Group Enabled], Available_For_General_Processing AS [General Processing], 
                      Group_Description AS [Group Description], Group_Created AS [Group Created]
FROM         dbo.T_Analysis_Job_Processor_Group

GO

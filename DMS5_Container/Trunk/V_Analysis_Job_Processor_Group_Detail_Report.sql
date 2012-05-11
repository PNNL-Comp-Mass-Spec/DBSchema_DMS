/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_Detail_Report
AS
SELECT AJPG.ID, AJPG.Group_Name AS [Group Name], 
    AJPG.Group_Enabled AS [Group Enabled], 
    AJPG.Available_For_General_Processing AS [General Processing],
     AJPG.Group_Description AS [Group Description], 
    AJPG.Group_Created AS [Group Created], 
    ISNULL(CountQ.Processor_Count, 0) AS Members, 
    dbo.GetAJProcessorGroupMembershipList(AJPG.ID, 1) 
    AS [Enabled Processors], 
    dbo.GetAJProcessorGroupMembershipList(AJPG.ID, 0) 
    AS [Disabled Processors], 
    dbo.GetAJProcessorGroupAssociatedJobs(AJPG.ID, 2) 
    AS [Associated Jobs]
FROM dbo.T_Analysis_Job_Processor_Group AJPG LEFT OUTER JOIN
        (SELECT Group_ID, COUNT(*) AS Processor_Count
      FROM dbo.T_Analysis_Job_Processor_Group_Membership AJPGM
      GROUP BY Group_ID) CountQ ON 
    AJPG.ID = CountQ.Group_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO

/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_List_Report
AS
SELECT AJPG.ID, AJPG.Group_Name AS [Group Name], 
    AJPG.Group_Description AS [Group Description], 
    AJPG.Group_Enabled AS [Group Enabled], 
    AJPG.Available_For_General_Processing AS [General Processing],
     CountQ.Enabled_Procs_Count AS Enabled_Procs, 
    CountQ.Disabled_Procs_Count AS Disabled_Procs, 
    dbo.GetAJProcessorGroupAssociatedJobs(AJPG.ID, 1) 
    AS [Associated Jobs], 
    AJPG.Group_Created AS [Group Created]
FROM dbo.T_Analysis_Job_Processor_Group AJPG INNER JOIN
        (SELECT AJPG.ID, 
           SUM(CASE WHEN AJPGM.Membership_Enabled = 'Y' THEN
            1 ELSE 0 END) AS Enabled_Procs_Count, 
           SUM(CASE WHEN AJPGM.Membership_Enabled <> 'Y' THEN
            1 ELSE 0 END) AS Disabled_Procs_Count
      FROM dbo.T_Analysis_Job_Processor_Group AJPG LEFT OUTER
            JOIN
           dbo.T_Analysis_Job_Processor_Group_Membership AJPGM
            ON AJPG.ID = AJPGM.Group_ID
      GROUP BY AJPG.ID) CountQ ON AJPG.ID = CountQ.ID

GO

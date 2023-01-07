/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Processor_Group_List_Report]
AS
SELECT AJPG.id, AJPG.Group_Name AS group_name,
    AJPG.Group_Description AS group_description,
    AJPG.Group_Enabled AS group_enabled,
	'Y' AS general_processing,
    -- Deprecated in February 2015; now always "Y"
	-- AJPG.Available_For_General_Processing AS general_processing,
     CountQ.Enabled_Procs_Count AS enabled_procs,
    CountQ.Disabled_Procs_Count AS disabled_procs,
    dbo.GetAJProcessorGroupAssociatedJobs(AJPG.ID, 1) AS associated_jobs,
    AJPG.Group_Created AS group_created
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
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_List_Report] TO [DDL_Viewer] AS [dbo]
GO

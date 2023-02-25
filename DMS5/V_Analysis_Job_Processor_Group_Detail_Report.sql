/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Processor_Group_Detail_Report]
AS
SELECT AJPG.id, AJPG.Group_Name AS group_name,
    AJPG.Group_Enabled AS group_enabled,
	'Y' AS general_processing,
    -- Deprecated in February 2015; now always "Y"
	-- AJPG.Available_For_General_Processing AS general_processing,
    AJPG.Group_Description AS group_description,
    AJPG.Group_Created AS group_created,
    ISNULL(CountQ.processor_count, 0) AS members,
    dbo.get_aj_processor_group_membership_list(AJPG.ID, 1) AS enabled_processors,
    dbo.get_aj_processor_group_membership_list(AJPG.ID, 0) AS disabled_processors,
    dbo.get_aj_processor_group_associated_jobs(AJPG.ID, 2) AS associated_jobs
FROM dbo.T_Analysis_Job_Processor_Group AJPG LEFT OUTER JOIN
        (SELECT Group_ID, COUNT(*) AS Processor_Count
      FROM dbo.T_Analysis_Job_Processor_Group_Membership AJPGM
      GROUP BY Group_ID) CountQ ON
    AJPG.ID = CountQ.Group_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO

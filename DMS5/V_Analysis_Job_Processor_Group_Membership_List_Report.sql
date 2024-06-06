/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Membership_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_Membership_List_Report
AS
SELECT AJPGM.Processor_ID AS id,
    AJP.Processor_Name AS name,
    AJPGM.Group_ID AS group_id,
    AJPGM.Membership_Enabled AS membership_enabled,
    AJP.machine,
    AJP.notes,
    dbo.get_aj_processor_membership_in_groups_list(AJP.ID, 2) AS group_membership
FROM dbo.T_Analysis_Job_Processor_Group_Membership AJPGM 
     INNER JOIN dbo.T_Analysis_Job_Processors AJP 
       ON AJPGM.Processor_ID = AJP.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Membership_List_Report] TO [DDL_Viewer] AS [dbo]
GO

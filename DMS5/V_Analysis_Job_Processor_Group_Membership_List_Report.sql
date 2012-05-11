/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Membership_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_Membership_List_Report
AS
SELECT AJPGM.Processor_ID AS ID, 
    AJP.Processor_Name AS Name, 
    AJPGM.Membership_Enabled AS [Membership Enabled], 
    AJP.Machine, AJP.Notes, AJPGM.Group_ID AS [#GroupID], 
    dbo.GetAJProcessorMembershipInGroupsList(AJP.ID, 2) 
    AS [Group Membership]
FROM dbo.T_Analysis_Job_Processor_Group_Membership AJPGM INNER
     JOIN
    dbo.T_Analysis_Job_Processors AJP ON 
    AJPGM.Processor_ID = AJP.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Membership_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Membership_List_Report] TO [PNL\D3M580] AS [dbo]
GO

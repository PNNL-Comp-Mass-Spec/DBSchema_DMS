/****** Object:  View [dbo].[V_Sample_Prep_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Prep_Request_List_Report
AS
SELECT     dbo.T_Sample_Prep_Request.ID, dbo.T_Sample_Prep_Request.Request_Name AS RequestName, dbo.T_Sample_Prep_Request.Created, 
                      dbo.T_Sample_Prep_Request.Estimated_Completion AS [Est. Complete], dbo.T_Sample_Prep_Request.Priority, 
                      dbo.T_Sample_Prep_Request_State_Name.State_Name AS State, dbo.T_Sample_Prep_Request.Reason, 
                      dbo.T_Sample_Prep_Request.Number_of_Samples AS NumSamples, dbo.T_Sample_Prep_Request.Estimated_MS_runs AS [MS Runs TBG], 
                      dbo.T_Sample_Prep_Request.Prep_Method AS PrepMethod, dbo.T_Sample_Prep_Request.Requested_Personnel AS RequestedPersonnel, 
                      dbo.T_Sample_Prep_Request.Assigned_Personnel AS AssignedPersonnel, 
                      QP.U_Name + ' (' + dbo.T_Sample_Prep_Request.Requester_PRN + ')' AS Requester, dbo.T_Sample_Prep_Request.Organism, 
                      dbo.T_Sample_Prep_Request.Biohazard_Level AS BiohazardLevel, dbo.T_Sample_Prep_Request.Campaign, dbo.T_Sample_Prep_Request.Comment, 
                      dbo.T_Sample_Prep_Request.Instrument_Name AS [Inst. Name], 
                      dbo.T_Sample_Prep_Request.Instrument_Analysis_Specifications AS [Inst. Analysis]
FROM         dbo.T_Sample_Prep_Request INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name ON 
                      dbo.T_Sample_Prep_Request.State = dbo.T_Sample_Prep_Request_State_Name.State_ID LEFT OUTER JOIN
                      dbo.T_Users AS QP ON dbo.T_Sample_Prep_Request.Requester_PRN = QP.U_PRN
WHERE     (dbo.T_Sample_Prep_Request_State_Name.State_ID > 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_List_Report] TO [PNL\D3M580] AS [dbo]
GO

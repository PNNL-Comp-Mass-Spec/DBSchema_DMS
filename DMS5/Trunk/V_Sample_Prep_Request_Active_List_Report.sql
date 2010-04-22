/****** Object:  View [dbo].[V_Sample_Prep_Request_Active_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Sample_Prep_Request_Active_List_Report
as
SELECT     T_Sample_Prep_Request.ID, T_Sample_Prep_Request.Request_Name AS RequestName, T_Sample_Prep_Request.Created, 
                      T_Sample_Prep_Request.Estimated_Completion AS [Est. Complete], T_Sample_Prep_Request.Priority, 
                      T_Sample_Prep_Request_State_Name.State_Name AS State, T_Sample_Prep_Request.Reason, 
                      T_Sample_Prep_Request.Number_of_Samples AS NumSamples, T_Sample_Prep_Request.Estimated_MS_runs AS [MS Runs TBG], 
                      T_Sample_Prep_Request.Prep_Method AS PrepMethod, T_Sample_Prep_Request.Requested_Personnel AS RequestedPersonnel, 
                      T_Sample_Prep_Request.Assigned_Personnel AS AssignedPersonnel, QP.U_Name + ' (' + T_Sample_Prep_Request.Requester_PRN + ')' AS Requester,
                       T_Sample_Prep_Request.Organism, T_Sample_Prep_Request.Biohazard_Level AS BiohazardLevel, T_Sample_Prep_Request.Campaign, 
                      T_Sample_Prep_Request.Comment, T_Sample_Prep_Request.Work_Package_Number AS [Work Package], 
                      T_Sample_Prep_Request.Instrument_Name AS [Inst. Name], T_Sample_Prep_Request.Instrument_Analysis_Specifications AS [Inst. Analysis]
FROM         T_Sample_Prep_Request INNER JOIN
                      T_Sample_Prep_Request_State_Name ON T_Sample_Prep_Request.State = T_Sample_Prep_Request_State_Name.State_ID LEFT OUTER JOIN
                      T_Users AS QP ON T_Sample_Prep_Request.Requester_PRN = QP.U_PRN
WHERE     (NOT (T_Sample_Prep_Request_State_Name.State_ID IN (0, 4, 5)))
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Active_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Active_List_Report] TO [PNL\D3M580] AS [dbo]
GO

/****** Object:  View [dbo].[V_Sample_Prep_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Sample_Prep_Request_Detail_Report as
SELECT     T_Sample_Prep_Request.ID, T_Sample_Prep_Request.Request_Name AS [Request Name], 
                      QP.U_Name + ' (' + T_Sample_Prep_Request.Requester_PRN + ')' AS Requester, T_Sample_Prep_Request.Reason, 
                      T_Sample_Prep_Request.Cell_Culture_List AS [Cell Culture List], T_Sample_Prep_Request.Organism, 
                      T_Sample_Prep_Request.Biohazard_Level AS [Biohazard Level], T_Sample_Prep_Request.Campaign, 
                      T_Sample_Prep_Request.Number_of_Samples AS [Number of Samples], T_Sample_Prep_Request.Sample_Name_List AS [Sample Name List], 
                      T_Sample_Prep_Request.Sample_Type AS [Sample Type], T_Sample_Prep_Request.Technical_Replicates AS [Technical Replicates], 
                      T_Sample_Prep_Request.Instrument_Name AS [Instrument Name], T_Sample_Prep_Request.Dataset_Type AS [Dataset Type], 
                      T_Sample_Prep_Request.Instrument_Analysis_Specifications AS [Instrument Analysis Specifications], 
                      T_Sample_Prep_Request.Prep_Method AS [Prep Method], T_Sample_Prep_Request.Prep_By_Robot AS [Prep By Robot], 
                      T_Sample_Prep_Request.Special_Instructions AS [Special Instructions], T_Sample_Prep_Request.UseSingleLCColumn, 
                      T_Internal_Standards.Name AS [Predigest Int Std], T_Internal_Standards_1.Name AS [Postdigest Int Std], 
                      T_Sample_Prep_Request.Sample_Naming_Convention AS [Sample Group Naming Prefix], T_Sample_Prep_Request.Facility, 
                      T_Sample_Prep_Request.Requested_Personnel AS [Requested Personnel], T_Sample_Prep_Request.Assigned_Personnel AS [Assigned Personnel], 
                      T_Sample_Prep_Request.Work_Package_Number AS [Work Package Number], T_Sample_Prep_Request.Project_Number AS [Project Number], 
                      T_Sample_Prep_Request.EUS_UsageType AS [EUS Usage Type], T_Sample_Prep_Request.EUS_Proposal_ID AS [EUS Proposal], 
                      T_Sample_Prep_Request.EUS_User_List AS [EUS Users], T_Sample_Prep_Request.Replicates_of_Samples AS [Replicates of Samples], 
                      T_Sample_Prep_Request.Comment, T_Sample_Prep_Request.Priority, T_Sample_Prep_Request_State_Name.State_Name AS State, 
                      T_Sample_Prep_Request.Created, T_Sample_Prep_Request.Estimated_Completion AS [Estimated Completion], 
                      T_Sample_Prep_Request.Estimated_MS_runs AS [MS Runs To Be Generated], dbo.ExperimentsFromRequest(T_Sample_Prep_Request.ID) 
                      AS Experiments, NU.Updates
FROM         T_Sample_Prep_Request INNER JOIN
                      T_Sample_Prep_Request_State_Name ON T_Sample_Prep_Request.State = T_Sample_Prep_Request_State_Name.State_ID INNER JOIN
                      T_Internal_Standards ON T_Sample_Prep_Request.Internal_standard_ID = T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      T_Internal_Standards AS T_Internal_Standards_1 ON 
                      T_Sample_Prep_Request.Postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID LEFT OUTER JOIN
                      T_Users AS QP ON T_Sample_Prep_Request.Requester_PRN = QP.U_PRN LEFT OUTER JOIN
                          (SELECT     Request_ID, COUNT(*) AS Updates
                            FROM          T_Sample_Prep_Request_Updates
                            GROUP BY Request_ID) AS NU ON T_Sample_Prep_Request.ID = NU.Request_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO

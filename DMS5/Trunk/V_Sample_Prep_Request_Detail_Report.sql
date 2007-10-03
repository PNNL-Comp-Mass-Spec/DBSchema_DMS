/****** Object:  View [dbo].[V_Sample_Prep_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Prep_Request_Detail_Report
AS
SELECT     dbo.T_Sample_Prep_Request.ID, dbo.T_Sample_Prep_Request.Request_Name AS [Request Name], 
                      QP.U_Name + ' (' + dbo.T_Sample_Prep_Request.Requester_PRN + ')' AS Requester, dbo.T_Sample_Prep_Request.Reason, 
                      dbo.T_Sample_Prep_Request.Cell_Culture_List AS [Cell Culture List], dbo.T_Sample_Prep_Request.Organism, 
                      dbo.T_Sample_Prep_Request.Biohazard_Level AS [Biohazard Level], dbo.T_Sample_Prep_Request.Campaign, 
                      dbo.T_Sample_Prep_Request.Number_of_Samples AS [Number of Samples], dbo.T_Sample_Prep_Request.Sample_Name_List AS [Sample Name List],
                       dbo.T_Sample_Prep_Request.Sample_Type AS [Sample Type], dbo.T_Sample_Prep_Request.Technical_Replicates AS [Technical Replicates], 
                      dbo.T_Sample_Prep_Request.Instrument_Name AS [Instrument Name], dbo.T_Sample_Prep_Request.Dataset_Type AS [Dataset Type], 
                      dbo.T_Sample_Prep_Request.Instrument_Analysis_Specifications AS [Instrument Analysis Specifications], 
                      dbo.T_Sample_Prep_Request.Prep_Method AS [Prep Method], dbo.T_Sample_Prep_Request.Prep_By_Robot AS [Prep By Robot], 
                      dbo.T_Sample_Prep_Request.Special_Instructions AS [Special Instructions], dbo.T_Sample_Prep_Request.UseSingleLCColumn, 
                      dbo.T_Internal_Standards.Name AS [Predigest Int Std], T_Internal_Standards_1.Name AS [Postdigest Int Std], 
                      dbo.T_Sample_Prep_Request.Sample_Naming_Convention AS [Sample Group Naming Prefix], 
                      dbo.T_Sample_Prep_Request.Requested_Personnel AS [Requested Personnel], 
                      dbo.T_Sample_Prep_Request.Assigned_Personnel AS [Assigned Personnel], 
                      dbo.T_Sample_Prep_Request.Work_Package_Number AS [Work Package Number], dbo.T_Sample_Prep_Request.Project_Number AS [Project Number], 
                      dbo.T_Sample_Prep_Request.EUS_UsageType AS [EUS Usage Type], dbo.T_Sample_Prep_Request.EUS_Proposal_ID AS [EUS Proposal], 
                      dbo.T_Sample_Prep_Request.EUS_User_List AS [EUS Users], dbo.T_Sample_Prep_Request.Replicates_of_Samples AS [Replicates of Samples], 
                      dbo.T_Sample_Prep_Request.Comment, dbo.T_Sample_Prep_Request.Priority, dbo.T_Sample_Prep_Request_State_Name.State_Name AS State, 
                      dbo.T_Sample_Prep_Request.Created, dbo.T_Sample_Prep_Request.Estimated_Completion AS [Estimated Completion], 
                      dbo.T_Sample_Prep_Request.Estimated_MS_runs AS [MS Runs To Be Generated], dbo.ExperimentsFromRequest(dbo.T_Sample_Prep_Request.ID) 
                      AS Experiments, NU.Updates
FROM         dbo.T_Sample_Prep_Request INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name ON dbo.T_Sample_Prep_Request.State = dbo.T_Sample_Prep_Request_State_Name.State_ID INNER JOIN
                      dbo.T_Internal_Standards ON dbo.T_Sample_Prep_Request.Internal_standard_ID = dbo.T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Internal_Standards AS T_Internal_Standards_1 ON 
                      dbo.T_Sample_Prep_Request.Postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID LEFT OUTER JOIN
                      dbo.T_Users AS QP ON dbo.T_Sample_Prep_Request.Requester_PRN = QP.U_PRN LEFT OUTER JOIN
                          (SELECT     Request_ID, COUNT(*) AS Updates
                            FROM          dbo.T_Sample_Prep_Request_Updates
                            GROUP BY Request_ID) AS NU ON dbo.T_Sample_Prep_Request.ID = NU.Request_ID

GO

/****** Object:  View [dbo].[V_Sample_Prep_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_Sample_Prep_Request_Detail_Report] as
SELECT SPR.ID,
       SPR.Request_Name AS [Request Name],
       QP.U_Name + ' (' + SPR.Requester_PRN + ')' AS Requester,
       SPR.Reason,
       SPR.Cell_Culture_List AS [Cell Culture List],
       SPR.Organism,
       SPR.Biohazard_Level AS [Biohazard Level],
       SPR.Campaign,
       SPR.Number_of_Samples AS [Number of Samples],
       SPR.Sample_Name_List AS [Sample Name List],
       SPR.Sample_Type AS [Sample Type],
       SPR.Technical_Replicates AS [Technical Replicates],
       SPR.Instrument_Name AS [Instrument Group],
       SPR.Dataset_Type AS [Dataset Type],
       SPR.Instrument_Analysis_Specifications AS [Instrument Analysis Specifications],
       SPR.Prep_Method AS [Prep Method],
       SPR.Prep_By_Robot AS [Prep By Robot],
       SPR.Special_Instructions AS [Special Instructions],
       SPR.UseSingleLCColumn,
       PreIntStd.Name AS [Predigest Int Std],
       PostIntStd.Name AS [Postdigest Int Std],
       SPR.Sample_Naming_Convention AS [Sample Group Naming Prefix],
       SPR.Facility,
       SPR.Requested_Personnel AS [Requested Personnel],
       SPR.Assigned_Personnel AS [Assigned Personnel],
       SPR.Work_Package_Number AS [Work Package Number],
       SPR.Project_Number AS [Project Number],
       SPR.EUS_UsageType AS [EUS Usage Type],
       SPR.EUS_Proposal_ID AS [EUS Proposal],
       SPR.EUS_User_List AS [EUS Users],
       SPR.Replicates_of_Samples AS [Replicates of Samples],
       SPR.[Comment],
       SPR.Priority,
       SN.State_Name AS State,
       SPR.Created,
       QT.[Complete or Closed],
       QT.[Days In Queue],
       SPR.Estimated_Completion AS [Estimated Completion],
       SPR.Estimated_MS_runs AS [MS Runs To Be Generated],
       dbo.ExperimentsFromRequest(SPR.ID) AS Experiments,
       NU.Updates
FROM T_Sample_Prep_Request SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID
     INNER JOIN T_Internal_Standards PreIntStd
       ON SPR.Internal_standard_ID = PreIntStd.Internal_Std_Mix_ID
     INNER JOIN T_Internal_Standards AS PostIntStd
       ON SPR.Postdigest_internal_std_ID = PostIntStd.Internal_Std_Mix_ID
     LEFT OUTER JOIN T_Users AS QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN ( SELECT Request_ID,
                              COUNT(*) AS Updates
                       FROM T_Sample_Prep_Request_Updates
                       GROUP BY Request_ID ) AS NU
       ON SPR.ID = NU.Request_ID
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times QT
       ON SPR.ID = QT.Request_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO

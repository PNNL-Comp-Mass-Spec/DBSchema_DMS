/****** Object:  View [dbo].[V_Data_Analysis_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_Detail_Report]
AS
SELECT R.ID,
       R.Request_Name AS [Request Name],
       R.Analysis_Type AS [Analysis Type],
       U.Name_with_PRN AS Requester,
       R.Description,
       R.Analysis_Specifications As [Analysis Specifications],
       R.Comment,
       dbo.GetDataAnalysisRequestBatchList(R.ID) As [Requested Run Batch IDs],
       R.Data_Package_ID As [Data Package],
       R.Exp_Group_ID As [Experiment Group],
       R.Campaign,
       R.Organism,
       R.Dataset_Count As [Dataset Count],
       R.Work_Package AS [Work Package],
       ISNULL(CC.Activation_State_Name, 'Invalid') AS [Work Package State],
       R.EUS_Proposal_ID AS [EUS Proposal],
       EPT.Proposal_Type_Name AS [EUS Proposal Type],
       CAST(EUP.Proposal_End_Date AS DATE) AS [EUS Proposal End Date],
       PSN.Name AS [EUS Proposal State],
       R.Requested_Personnel AS [Requested Personnel],
       R.Assigned_Personnel AS [Assigned Personnel],
       R.Priority,
       R.Reason_For_High_Priority AS [Reason For High Priority],
       R.Estimated_Analysis_Time_Days AS [Estimated Analysis Time (days)],
       SN.State_Name AS State,
       R.State_Comment AS [State Comment],
       R.Created,
       QT.Closed,
       QT.[Days In Queue],
       Case When R.State In (0, 4) Then Null Else QT.[Days In State] End As [Days In State],
       UpdateQ.Updates,
       CASE
       WHEN R.State <> 4 AND
            CC.Activation_State >= 3 THEN 10    -- If the analysis request is not closed, but the charge code is inactive, return 10 for wp_activation_state
       ELSE CC.Activation_State
       END AS wp_activation_state
FROM T_Data_Analysis_Request AS R
     INNER JOIN T_Data_Analysis_Request_State_Name AS SN
       ON R.State = SN.State_ID
     LEFT OUTER JOIN T_Users AS U
       ON R.Requester_PRN = U.U_PRN
     LEFT OUTER JOIN ( SELECT Request_ID, COUNT(*) AS Updates
                       FROM T_Data_Analysis_Request_Updates
                       GROUP BY Request_ID ) AS UpdateQ
       ON R.ID = UpdateQ.Request_ID
     LEFT OUTER JOIN V_Data_Analysis_Request_Queue_Times AS QT
       ON R.ID = QT.Request_ID
     LEFT OUTER JOIN V_Charge_Code_Status AS CC
       ON R.Work_Package = CC.Charge_Code
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON R.EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
     LEFT OUTER JOIN T_EUS_Proposal_State_Name PSN
       ON EUP.State_ID = PSN.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO

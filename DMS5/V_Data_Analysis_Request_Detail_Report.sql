/****** Object:  View [dbo].[V_Data_Analysis_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Analysis_Request_Detail_Report]
AS
SELECT R.id,
       R.Request_Name AS request_name,
       R.Analysis_Type AS analysis_type,
       U.Name_with_PRN AS requester,
       R.description,
       R.Analysis_Specifications As analysis_specifications,
       R.comment,
       dbo.get_data_analysis_request_batch_list(R.ID) As requested_run_batch_ids,
       R.Data_Package_ID As data_package,
       R.Exp_Group_ID As experiment_group,
       R.campaign,
       R.organism,
       R.Dataset_Count As dataset_count,
       R.Work_Package AS work_package,
       ISNULL(CC.activation_state_name, 'Invalid') AS work_package_state,
       R.EUS_Proposal_ID AS eus_proposal,
       EPT.Proposal_Type_Name AS eus_proposal_type,
       CAST(EUP.Proposal_End_Date AS DATE) AS eus_proposal_end_date,
       PSN.Name AS eus_proposal_state,
       R.Requested_Personnel AS requested_personnel,
       R.Assigned_Personnel AS assigned_personnel,
       R.priority,
       R.Reason_For_High_Priority AS reason_for_high_priority,
       R.Estimated_Analysis_Time_Days AS estimated_analysis_time_days,
       SN.State_Name AS state,
       R.State_Comment AS state_comment,
       R.created,
       QT.closed,
       QT.days_in_queue,
       Case When R.State In (0, 4) Then Null Else QT.Days_In_State End As days_in_state,
       UpdateQ.updates,
       CASE
       WHEN R.State <> 4 AND
            CC.Activation_State >= 3 THEN 10    -- If the analysis request is not closed, but the charge code is inactive, return 10 for wp_activation_state
       ELSE CC.activation_state
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

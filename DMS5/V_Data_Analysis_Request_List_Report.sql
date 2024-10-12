/****** Object:  View [dbo].[V_Data_Analysis_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Analysis_Request_List_Report]
AS
SELECT R.id,
       R.Request_Name AS request_name,
       R.Analysis_Type AS analysis_type,
       R.created,
       R.Estimated_Analysis_Time_Days AS est_analysis_time,
       R.priority,
       TA.Attachments AS files,
       SN.State_Name AS state,
       R.State_Comment AS state_comment,
       U.Name_with_PRN AS requester,
       R.description,
       QT.days_in_queue,
       R.Requested_Personnel AS requested_personnel,
       R.Assigned_Personnel AS assigned_personnel,
       R.Representative_Batch_ID As batch,
       R.Representative_Data_Pkg_ID As data_package,
       R.Exp_Group_ID As exp_group,
       R.campaign,
       R.organism,
       R.Dataset_Count As dataset_count,
       R.Work_Package AS work_package,
       ISNULL(CC.activation_state_name, 'Invalid') AS wp_state,
       R.EUS_Proposal_ID AS eus_proposal,
       EPT.Proposal_Type_Name AS eus_proposal_type,
       CASE
           WHEN R.State = 4 THEN 0                  -- Request is closed
           WHEN QT.Days_In_Queue <= 30 THEN 30    -- Request is 0 to 30 days old
           WHEN QT.Days_In_Queue <= 60 THEN 60    -- Request is 30 to 60 days old
           WHEN QT.Days_In_Queue <= 90 THEN 90    -- Request is 60 to 90 days old
           ELSE 120                                 -- Request is over 90 days old
       END AS days_in_queue_bin,
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
     LEFT OUTER JOIN V_Data_Analysis_Request_Queue_Times AS QT
       ON R.ID = QT.Request_ID
     LEFT OUTER JOIN ( SELECT Entity_ID_Value,
                              COUNT(*) AS Attachments
                       FROM T_File_Attachment
                       WHERE Entity_Type = 'data_analysis_request' AND Active > 0
                       GROUP BY Entity_ID_Value ) AS TA
       ON R.ID = TA.Entity_ID_Value
     LEFT OUTER JOIN V_Charge_Code_Status CC
       ON R.Work_Package = CC.Charge_Code
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON R.EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
WHERE R.State > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_List_Report] TO [DDL_Viewer] AS [dbo]
GO

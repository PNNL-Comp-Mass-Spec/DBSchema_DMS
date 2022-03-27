/****** Object:  View [dbo].[V_Data_Analysis_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_List_Report]
AS
SELECT R.ID,
       R.Request_Name AS [Request Name],
       R.Analysis_Type AS [Analysis Type],
       R.Created,
       R.Estimated_Analysis_Time_Days AS [Est. Analysis Time],
       R.Priority,
       TA.Attachments AS Files,
       SN.State_Name AS State,
       R.State_Comment AS [State Comment],
       U.Name_with_PRN AS Requester,
       R.Description,
       QT.[Days In Queue],
       R.Requested_Personnel AS [Requested Personnel],
       R.Assigned_Personnel AS [Assigned Personnel],
       R.Representative_Batch_ID As Batch,
       R.Data_Package_ID As [Data Package],
       R.Exp_Group_ID As [Exp. Group],
       R.Campaign,
       R.Organism,
       R.Dataset_Count As [Dataset Count],
       R.Work_Package AS WP,
       ISNULL(CC.Activation_State_Name, 'Invalid') AS [WP State],
       R.EUS_Proposal_ID AS [EUS Proposal],
       EPT.Proposal_Type_Name AS [EUS Proposal Type],
       Case 
           When R.State = 4 Then 0                  -- Request is closed
           When QT.[Days In Queue] <= 30 Then 30    -- Request is 0 to 30 days old
           When QT.[Days In Queue] <= 60 Then 60    -- Request is 30 to 60 days old
           When QT.[Days In Queue] <= 90 Then 90    -- Request is 60 to 90 days old
           Else 120                                 -- Request is over 90 days old
       END AS #DaysInQueue,
       CASE
       WHEN R.State <> 4 AND
            CC.Activation_State >= 3 THEN 10    -- If the analysis request is not closed, but the charge code is inactive, return 10 for #WPActivationState
       ELSE CC.Activation_State
       END AS #WPActivationState
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

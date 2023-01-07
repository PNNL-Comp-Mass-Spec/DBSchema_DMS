/****** Object:  View [dbo].[V_Sample_Prep_Request_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Planning_Report]
AS
SELECT SPR.id,
       U.U_Name AS requester,
       SPR.Request_Name AS request_name,
       SPR.created,
       SPR.Estimated_Prep_Time_Days AS est_prep_time,
       SPR.State_Comment AS state_comment,
       SPR.priority,
       SN.State_Name AS state,
       SPR.Number_of_Samples AS num_samples,
       SPR.Estimated_MS_runs AS ms_runs_tbg,
       QT.days_in_queue,
       Case When SPR.State In (0, 4, 5) Then Null Else QT.Days_In_State End As days_in_state,
       SPR.Requested_Personnel AS req_personnel,
       SPR.Assigned_Personnel AS assigned,
       SPR.Prep_Method AS prep_method,
       SPR.Instrument_Group AS instrument,
       SPR.campaign,
       SPR.Work_Package_Number AS wp,
       ISNULL(CC.activation_state_name, '') AS wp_state,
       Case
            When SPR.State In (4, 5) Then 0          -- Request is complete or closed
            When QT.Days_In_Queue <= 30 Then 30    -- Request is 0 to 30 days old
            When QT.Days_In_Queue <= 60 Then 60    -- Request is 30 to 60 days old
            When QT.Days_In_Queue <= 90 Then 90    -- Request is 60 to 90 days old
            Else 120                                 -- Request is over 90 days old
       END AS days_in_queue_bin,
       CASE
           WHEN SPR.State <> 5 AND
                CC.Activation_State >= 3 THEN 10    -- If the request is not closed, but the charge code is inactive, then return 10 for wp_activation_state
           ELSE CC.activation_state
       END AS wp_activation_state,
       SPR.Assigned_Personnel_SortKey As assigned_sort_key
FROM T_Sample_Prep_Request AS SPR
     INNER JOIN T_Sample_Prep_Request_State_Name AS SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN T_Users AS U
       ON SPR.Requester_PRN = U.U_PRN
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT
       ON SPR.ID = QT.Request_ID
     LEFT OUTER JOIN V_Charge_Code_Status CC
       ON SPR.Work_Package_Number = CC.Charge_Code
WHERE (SPR.State > 0) And SPR.State < 5 AND
      SPR.Request_Type = 'Default'
GROUP BY SPR.ID, U.U_Name, SPR.Request_Name, SPR.Created, SPR.Estimated_Prep_Time_Days,
         SPR.State_Comment, SPR.Priority, SN.State_Name, SPR.Number_of_Samples,
         SPR.Estimated_MS_runs, QT.Days_In_Queue, QT.Days_In_State,
         SPR.Requested_Personnel, SPR.Assigned_Personnel, SPR.Prep_Method,
         SPR.Instrument_Group, SPR.Campaign,
         SPR.Work_Package_Number, CC.Activation_State_Name, SPR.State,
         CC.Activation_State, SPR.Assigned_Personnel_SortKey


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Planning_Report] TO [DDL_Viewer] AS [dbo]
GO

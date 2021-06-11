/****** Object:  View [dbo].[V_Sample_Prep_Request_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Planning_Report]
AS
SELECT SPR.ID,
       U.U_Name AS Requester,       
       SPR.Request_Name AS [Request Name],
       SPR.Created,
       SPR.Estimated_Prep_Time_Days AS [Est. Prep Time],
       SPR.State_Comment AS [State Comment],
       SPR.Priority,
       SN.State_Name AS [State],
       SPR.Number_of_Samples AS [Num Samples],
       SPR.Estimated_MS_runs AS [MS Runs TBG],
       QT.[Days In Queue],
       SPR.Requested_Personnel AS [Req. Personnel],
       SPR.Assigned_Personnel AS [Assigned],
       SPR.Prep_Method AS [Prep Method],
       SPR.Instrument_Group AS Instrument,
       SPR.Campaign,
       SPR.Work_Package_Number AS WP,
       ISNULL(CC.Activation_State_Name, '') AS [WP State],
       Case 
            When SPR.State In (4, 5) Then 0           -- Request is complete or closed
            When QT.[Days In Queue] <= 30 Then 30    -- Request is 0 to 30 days old
            When QT.[Days In Queue] <= 60 Then 60    -- Request is 30 to 60 days old
            When QT.[Days In Queue] <= 90 Then 90    -- Request is 60 to 90 days old
            Else 120                                 -- Request is over 90 days old
       END AS #DaysInQueue,
       CASE
           WHEN SPR.State <> 5 AND
                CC.Activation_State >= 3 THEN 10    -- If the request is not closed, but the charge code is inactive, then return 10 for #WPActivationState
           ELSE CC.Activation_State
       END AS #WPActivationState
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
         SPR.Estimated_MS_runs, QT.[Days In Queue], SPR.Requested_Personnel, 
         SPR.Assigned_Personnel, SPR.Prep_Method, SPR.Instrument_Group, SPR.Campaign, 
         SPR.Work_Package_Number, CC.Activation_State_Name, SPR.State, CC.Activation_State

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Planning_Report] TO [DDL_Viewer] AS [dbo]
GO

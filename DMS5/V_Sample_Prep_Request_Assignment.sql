/****** Object:  View [dbo].[V_Sample_Prep_Request_Assignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[V_Sample_Prep_Request_Assignment]
AS
SELECT '' AS [Sel.],
       SPR.ID,
       SPR.Created,
       SPR.Estimated_Completion AS [Est. Complete],
       SN.State_Name AS State,
       SPR.Request_Name AS Name,
       QP.Name_with_PRN AS Requester,
       SPR.Priority,
       QT.[Days In Queue],
       SPR.Requested_Personnel AS Requested,
       SPR.Assigned_Personnel AS Assigned,
       SPR.Organism,
       SPR.Biohazard_Level AS Biohazard,
       SPR.Campaign,
       SPR.Number_of_Samples AS Samples,
       SPR.Sample_Type AS [Sample Type],
       SPR.Prep_Method AS [Prep Method],
       SPR.Replicates_of_Samples AS Replicates,
       SPR.[Comment],
       Case 
			When SPR.State In (4,5) Then 0			-- Request is complete or closed
			When QT.[Days In Queue] <= 30 Then	30	-- Request is 0 to 30 days old
			When QT.[Days In Queue] <= 60 Then	60	-- Request is 30 to 60 days old
			When QT.[Days In Queue] <= 90 Then	90	-- Request is 60 to 90 days old
			Else 120								-- Request is over 90 days old
		End
		AS #DaysInQueue
FROM T_Sample_Prep_Request SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN T_Users QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times QT 
       ON SPR.ID = QT.Request_ID
WHERE (SPR.State > 0) And SPR.Request_Type = 'Default'






GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Assignment] TO [DDL_Viewer] AS [dbo]
GO

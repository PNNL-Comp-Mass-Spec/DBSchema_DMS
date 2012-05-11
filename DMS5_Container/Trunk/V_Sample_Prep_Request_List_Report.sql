/****** Object:  View [dbo].[V_Sample_Prep_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Sample_Prep_Request_List_Report]
AS
SELECT SPR.ID,
       SPR.Request_Name AS RequestName,
       SPR.Created,
       SPR.Estimated_Completion AS [Est. Complete],
       SPR.Priority,
       SN.State_Name AS [State],
       SPR.Reason,
       SPR.Number_of_Samples AS NumSamples,
       SPR.Estimated_MS_runs AS [MS Runs TBG],
       QT.[Days In Queue],
       SPR.Prep_Method AS PrepMethod,
       SPR.Requested_Personnel AS RequestedPersonnel,
       SPR.Assigned_Personnel AS AssignedPersonnel,
       QP.U_Name + ' (' + SPR.Requester_PRN + ')' AS Requester,
       SPR.Organism,
       SPR.Biohazard_Level AS BiohazardLevel,
       SPR.Campaign,
       SPR.[Comment],
       SPR.Work_Package_Number AS WP,
       SPR.Instrument_Name AS [Instrument],
       SPR.Instrument_Analysis_Specifications AS [Inst. Analysis],
       Case 
			When SPR.State In (4,5) Then 0			-- Request is complete or closed
			When QT.[Days In Queue] <= 30 Then	30	-- Request is 0 to 30 days old
			When QT.[Days In Queue] <= 60 Then	60	-- Request is 30 to 60 days old
			When QT.[Days In Queue] <= 90 Then	90	-- Request is 60 to 90 days old
			Else 120								-- Request is over 90 days old
		End
		AS #DaysInQueue
FROM dbo.T_Sample_Prep_Request SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN dbo.T_Users AS QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times QT 
       ON SPR.ID = QT.Request_ID
WHERE (SPR.State > 0)



GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_List_Report] TO [PNL\D3M580] AS [dbo]
GO

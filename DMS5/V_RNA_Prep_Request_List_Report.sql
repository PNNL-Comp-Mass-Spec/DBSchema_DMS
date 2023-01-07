/****** Object:  View [dbo].[V_RNA_Prep_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_RNA_Prep_Request_List_Report]
AS
SELECT SPR.id,
       SPR.Request_Name AS request_name,
       SPR.created,
       SPR.Estimated_Completion AS est_complete,
	   TA.Attachments AS files,
       SN.State_Name AS state,
       SPR.reason,
       SPR.Number_of_Samples AS num_samples,
	   QT.days_in_queue,
       SPR.Prep_Method AS prep_method,
       QP.Name_with_PRN AS requester,
       SPR.organism,
       SPR.Biohazard_Level AS biohazard_level,
       SPR.campaign,
       SPR.Work_Package_Number AS wp,
       ISNULL(CC.activation_state_name, '') AS wp_state,
       SPR.Instrument_Name AS instrument,
       SPR.Instrument_Analysis_Specifications AS inst_analysis,
	   SPR.eus_proposal_id,
	   SPR.Sample_Naming_Convention As sample_prefix,
       SUM (Case When DATEDIFF(day, E.ex_created, GETDATE()) < 8 Then 1 Else 0 End) AS experiments_last_7days,
       SUM (Case When DATEDIFF(day, E.ex_created, GETDATE()) < 32 Then 1 Else 0 End) AS experiments_last_31days,
       SUM (Case When DATEDIFF(day, E.ex_created, GETDATE()) < 181 Then 1 Else 0 End) AS experiments_last_180days,
       SUM (Case When Not E.EX_created Is Null Then 1 Else 0 End) AS experiments_total,
       Case
			When SPR.State In (4,5) Then 0			-- Request is complete or closed
			When QT.Days_In_Queue <= 30 Then	30	-- Request is 0 to 30 days old
			When QT.Days_In_Queue <= 60 Then	60	-- Request is 30 to 60 days old
			When QT.Days_In_Queue <= 90 Then	90	-- Request is 60 to 90 days old
			Else 120								-- Request is over 90 days old
		END AS days_in_queue_bin,
	   CASE
           WHEN SPR.State <> 5 AND
                CC.Activation_State >= 3 THEN 10	-- If the request is not closed, but the charge code is inactive, then return 10 for wp_activation_state
           ELSE CC.activation_state
       END AS wp_activation_state
FROM T_Sample_Prep_Request AS SPR
        INNER JOIN T_Sample_Prep_Request_State_Name AS SN ON SPR.State = SN.State_ID
        LEFT OUTER JOIN T_Users AS QP ON SPR.Requester_PRN = QP.U_PRN
		LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT ON SPR.ID = QT.Request_ID
        LEFT OUTER JOIN ( SELECT Entity_ID AS Entity_ID,
                                    COUNT(*) AS Attachments
                          FROM T_File_Attachment
                          WHERE     ( Entity_Type = 'sample_prep_request' ) And Active > 0
                          GROUP BY  Entity_ID
                        ) AS TA ON SPR.ID = TA.Entity_ID
        LEFT OUTER JOIN T_Experiments E ON SPR.ID = E.EX_sample_prep_request_ID
        LEFT OUTER JOIN V_Charge_Code_Status CC ON SPR.Work_Package_Number = CC.Charge_Code
WHERE (SPR.State > 0) And SPR.Request_Type = 'RNA'
GROUP BY SPR.ID, SPR.Request_Name, SPR.Created, SPR.Estimated_Completion, TA.Attachments,
         SPR.State, SN.State_Name, SPR.Reason, SPR.Number_of_Samples,
		 QT.Days_In_Queue, SPR.Prep_Method,
         QP.Name_with_PRN, SPR.Organism, SPR.Biohazard_Level, SPR.Campaign,
         SPR.Work_Package_Number, SPR.Instrument_Name,
         SPR.Instrument_Analysis_Specifications,  SPR.EUS_Proposal_ID,
	     SPR.Sample_Naming_Convention,
         CC.Activation_State, CC.Activation_State_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_RNA_Prep_Request_List_Report] TO [DDL_Viewer] AS [dbo]
GO

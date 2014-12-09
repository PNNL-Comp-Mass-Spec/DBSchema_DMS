/****** Object:  View [dbo].[V_Find_Sample_Prep_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Find_Sample_Prep_Request]
AS
SELECT SPR.ID AS Request_ID,
       SPR.Request_Name,
       SPR.Created,
       SPR.Estimated_Completion AS Est_Complete,
       SPR.Priority,
       RSN.State_Name AS State,
       SPR.Reason,
       SPR.Prep_Method,
       SPR.Requested_Personnel,
       SPR.Assigned_Personnel,
       QP.Name_with_PRN AS Requester,
       SPR.Organism,
       SPR.Biohazard_Level,
       SPR.Campaign,
       SPR.[Comment]
FROM dbo.T_Sample_Prep_Request SPR
     INNER JOIN dbo.T_Sample_Prep_Request_State_Name RSN
       ON SPR.State = RSN.State_ID
     LEFT OUTER JOIN dbo.T_Users QP
       ON SPR.Requester_PRN = QP.U_PRN



GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Sample_Prep_Request] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Sample_Prep_Request] TO [PNL\D3M580] AS [dbo]
GO

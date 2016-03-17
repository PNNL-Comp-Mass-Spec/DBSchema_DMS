/****** Object:  View [dbo].[V_Sample_Prep_Assignments_24Hrs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Assignments_24Hrs]
AS
SELECT SPR.ID,
       SPR.Request_Name AS [Request Name],
       AP.Name_with_PRN AS [Assigned Personnel],
       QP.Name_with_PRN AS Requester,
       SPR.Reason,
       SPR.Organism,
       SPR.Number_of_Samples AS [Number of Samples],
       SPR.Sample_Type AS [Sample Type],
       SPR.Prep_Method AS [Prep Method]
FROM dbo.T_Sample_Prep_Request SPR
     INNER JOIN dbo.T_Sample_Prep_Request_State_Name
       ON SPR.State = dbo.T_Sample_Prep_Request_State_Name.State_ID
     LEFT OUTER JOIN dbo.T_Users AP
       ON SPR.Assigned_Personnel = AP.U_PRN
     LEFT OUTER JOIN dbo.T_Users QP
       ON SPR.Requester_PRN = QP.U_PRN
WHERE (SPR.State = 2) AND
      (SPR.StateChanged > DATEADD(hh, - 24, GETDATE()))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Assignments_24Hrs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Assignments_24Hrs] TO [PNL\D3M580] AS [dbo]
GO

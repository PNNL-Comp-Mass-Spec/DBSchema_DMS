/****** Object:  View [dbo].[V_Sample_Prep_New_Requests_24Hrs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_New_Requests_24Hrs]
AS
SELECT SPR.ID,
       SPR.Request_Name AS [Request Name],
       QP.Name_with_PRN AS Requester,
       SPR.Reason,
       SPR.Organism,
       SPR.Number_of_Samples AS [Number of Samples],
       SPR.Sample_Type AS [Sample Type],
       SPR.Prep_Method AS [Prep Method],
       RP.Name_with_PRN AS [Requested Personnel],
       SPR.Work_Package_Number AS [Work Package Number],
       SPR.User_Proposal_Number AS [User Proposal Number],
       SPR.Replicates_of_Samples AS [Replicates of Samples],
       SPR.Created
FROM dbo.T_Sample_Prep_Request SPR
     INNER JOIN dbo.T_Sample_Prep_Request_State_Name
       ON SPR.State = dbo.T_Sample_Prep_Request_State_Name.State_ID
     LEFT OUTER JOIN dbo.T_Users RP
       ON SPR.Requested_Personnel = RP.U_PRN
     LEFT OUTER JOIN dbo.T_Users QP
       ON SPR.Requester_PRN = QP.U_PRN
WHERE (SPR.Created > DATEADD(hh, -24, GETDATE()))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_New_Requests_24Hrs] TO [DDL_Viewer] AS [dbo]
GO

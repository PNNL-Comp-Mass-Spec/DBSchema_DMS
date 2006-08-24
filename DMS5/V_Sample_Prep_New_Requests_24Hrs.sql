/****** Object:  View [dbo].[V_Sample_Prep_New_Requests_24Hrs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Prep_New_Requests_24Hrs
AS
SELECT     dbo.T_Sample_Prep_Request.ID, dbo.T_Sample_Prep_Request.Request_Name AS [Request Name], 
                      QP.U_Name + ' (' + dbo.T_Sample_Prep_Request.Requester_PRN + ')' AS Requester, dbo.T_Sample_Prep_Request.Reason, 
                      dbo.T_Sample_Prep_Request.Organism, dbo.T_Sample_Prep_Request.Number_of_Samples AS [Number of Samples], 
                      dbo.T_Sample_Prep_Request.Sample_Type AS [Sample Type], dbo.T_Sample_Prep_Request.Prep_Method AS [Prep Method], 
                      RP.U_Name + ' (' + dbo.T_Sample_Prep_Request.Requested_Personnel + ')' AS [Requested Personnel], 
                      dbo.T_Sample_Prep_Request.Work_Package_Number AS [Work Package Number], 
                      dbo.T_Sample_Prep_Request.User_Proposal_Number AS [User Proposal Number], 
                      dbo.T_Sample_Prep_Request.Replicates_of_Samples AS [Replicates of Samples], dbo.T_Sample_Prep_Request.Created
FROM         dbo.T_Sample_Prep_Request INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name ON 
                      dbo.T_Sample_Prep_Request.State = dbo.T_Sample_Prep_Request_State_Name.State_ID LEFT OUTER JOIN
                      dbo.T_Users RP ON dbo.T_Sample_Prep_Request.Requested_Personnel = RP.U_PRN LEFT OUTER JOIN
                      dbo.T_Users QP ON dbo.T_Sample_Prep_Request.Requester_PRN = QP.U_PRN
WHERE     (dbo.T_Sample_Prep_Request.Created > DATEADD(hh, - 24, GETDATE()))

GO

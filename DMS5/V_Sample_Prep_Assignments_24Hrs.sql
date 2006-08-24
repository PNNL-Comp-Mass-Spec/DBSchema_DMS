/****** Object:  View [dbo].[V_Sample_Prep_Assignments_24Hrs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Prep_Assignments_24Hrs
AS
SELECT     dbo.T_Sample_Prep_Request.ID, dbo.T_Sample_Prep_Request.Request_Name AS [Request Name], 
                      AP.U_Name + ' (' + dbo.T_Sample_Prep_Request.Requested_Personnel + ')' AS [Assigned Personnel], 
                      QP.U_Name + ' (' + dbo.T_Sample_Prep_Request.Requester_PRN + ')' AS Requester, dbo.T_Sample_Prep_Request.Reason, 
                      dbo.T_Sample_Prep_Request.Organism, dbo.T_Sample_Prep_Request.Number_of_Samples AS [Number of Samples], 
                      dbo.T_Sample_Prep_Request.Sample_Type AS [Sample Type], dbo.T_Sample_Prep_Request.Prep_Method AS [Prep Method]
FROM         dbo.T_Sample_Prep_Request INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name ON 
                      dbo.T_Sample_Prep_Request.State = dbo.T_Sample_Prep_Request_State_Name.State_ID LEFT OUTER JOIN
                      dbo.T_Users AP ON dbo.T_Sample_Prep_Request.Assigned_Personnel = AP.U_PRN LEFT OUTER JOIN
                      dbo.T_Users QP ON dbo.T_Sample_Prep_Request.Requester_PRN = QP.U_PRN
WHERE     (dbo.T_Sample_Prep_Request.State = 2) AND (dbo.T_Sample_Prep_Request.StateChanged > DATEADD(hh, - 24, GETDATE()))

GO

/****** Object:  View [dbo].[V_Sample_Prep_Request_Assignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Sample_Prep_Request_Assignment
AS
SELECT     '' AS [Sel.], T_Sample_Prep_Request.ID, T_Sample_Prep_Request.Created, T_Sample_Prep_Request.Estimated_Completion AS [Est. Complete], 
                      T_Sample_Prep_Request_State_Name.State_Name AS State, T_Sample_Prep_Request.Request_Name AS Name, 
                      QP.U_Name + ' (' + T_Sample_Prep_Request.Requester_PRN + ')' AS Requester, T_Sample_Prep_Request.Priority, 
                      T_Sample_Prep_Request.Requested_Personnel AS Requested, T_Sample_Prep_Request.Assigned_Personnel AS Assigned, 
                      T_Sample_Prep_Request.Organism, T_Sample_Prep_Request.Biohazard_Level AS Biohazard, T_Sample_Prep_Request.Campaign, 
                      T_Sample_Prep_Request.Number_of_Samples AS Samples, T_Sample_Prep_Request.Sample_Type AS [Sample Type], 
                      T_Sample_Prep_Request.Prep_Method AS [Prep Method], T_Sample_Prep_Request.Replicates_of_Samples AS Replicates, 
                      T_Sample_Prep_Request.Comment
FROM         T_Sample_Prep_Request INNER JOIN
                      T_Sample_Prep_Request_State_Name ON T_Sample_Prep_Request.State = T_Sample_Prep_Request_State_Name.State_ID LEFT OUTER JOIN
                      T_Users QP ON T_Sample_Prep_Request.Requester_PRN = QP.U_PRN
WHERE     (T_Sample_Prep_Request.State > 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Assignment] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Assignment] TO [PNL\D3M580] AS [dbo]
GO

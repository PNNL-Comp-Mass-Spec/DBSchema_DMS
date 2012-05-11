/****** Object:  View [dbo].[V_Find_Sample_Prep_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Find_Sample_Prep_Request
AS
SELECT     dbo.T_Sample_Prep_Request.ID AS Request_ID, dbo.T_Sample_Prep_Request.Request_Name, dbo.T_Sample_Prep_Request.Created, 
                      dbo.T_Sample_Prep_Request.Estimated_Completion AS Est_Complete, dbo.T_Sample_Prep_Request.Priority, 
                      dbo.T_Sample_Prep_Request_State_Name.State_Name AS State, dbo.T_Sample_Prep_Request.Reason, dbo.T_Sample_Prep_Request.Prep_Method, 
                      dbo.T_Sample_Prep_Request.Requested_Personnel, dbo.T_Sample_Prep_Request.Assigned_Personnel, 
                      QP.U_Name + ' (' + dbo.T_Sample_Prep_Request.Requester_PRN + ')' AS Requester, dbo.T_Sample_Prep_Request.Organism, 
                      dbo.T_Sample_Prep_Request.Biohazard_Level, dbo.T_Sample_Prep_Request.Campaign, dbo.T_Sample_Prep_Request.Comment
FROM         dbo.T_Sample_Prep_Request INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name ON 
                      dbo.T_Sample_Prep_Request.State = dbo.T_Sample_Prep_Request_State_Name.State_ID LEFT OUTER JOIN
                      dbo.T_Users QP ON dbo.T_Sample_Prep_Request.Requester_PRN = QP.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Sample_Prep_Request] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Sample_Prep_Request] TO [PNL\D3M580] AS [dbo]
GO

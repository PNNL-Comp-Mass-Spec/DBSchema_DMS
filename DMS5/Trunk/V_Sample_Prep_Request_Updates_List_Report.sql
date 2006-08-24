/****** Object:  View [dbo].[V_Sample_Prep_Request_Updates_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Sample_Prep_Request_Updates_List_Report
AS
SELECT     dbo.T_Sample_Prep_Request_Updates.Date_of_Change, dbo.T_Sample_Prep_Request_Updates.System_Account, dbo.T_Users.U_Name AS Name, 
                      BSN.State_Name AS [Beginning Sate], ESN.State_Name AS [End State], dbo.T_Sample_Prep_Request_Updates.Request_ID AS [#RequestID]
FROM         dbo.T_Sample_Prep_Request_Updates INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name BSN ON dbo.T_Sample_Prep_Request_Updates.Beginning_State_ID = BSN.State_ID INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name ESN ON dbo.T_Sample_Prep_Request_Updates.End_State_ID = ESN.State_ID LEFT OUTER JOIN
                      dbo.T_Users ON dbo.T_Sample_Prep_Request_Updates.System_Account = dbo.T_Users.U_PRN

GO

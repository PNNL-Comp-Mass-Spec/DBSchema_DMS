/****** Object:  View [dbo].[V_Sample_Prep_Request_Updates_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Updates_List_Report]
AS
SELECT Updates.date_of_change,
       Updates.system_account,
       U.U_Name AS name,
       BSN.State_Name AS beginning_state,
       ESN.State_Name AS end_state,
       Updates.request_id
FROM dbo.T_Sample_Prep_Request_Updates AS Updates
     INNER JOIN dbo.T_Sample_Prep_Request_State_Name AS BSN
       ON Updates.Beginning_State_ID = BSN.State_ID
     INNER JOIN dbo.T_Sample_Prep_Request_State_Name AS ESN
       ON Updates.End_State_ID = ESN.State_ID
     LEFT OUTER JOIN dbo.T_Users U
       ON Updates.System_Account = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Updates_List_Report] TO [DDL_Viewer] AS [dbo]
GO

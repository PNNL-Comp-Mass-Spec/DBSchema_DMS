/****** Object:  View [dbo].[V_Data_Analysis_Request_Updates_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_Updates_List_Report]
AS
SELECT Updates.entered,
       Updates.entered_by,
       U.U_Name AS name,
       Updates.old_state_id,
       Updates.new_state_id,
       OldState.State_Name AS old_state,
       NewState.State_Name AS new_state,
       Updates.request_id
FROM dbo.T_Data_Analysis_Request_Updates AS Updates
     INNER JOIN dbo.T_Data_Analysis_Request_State_Name AS OldState
       ON Updates.Old_State_ID = OldState.State_ID
     INNER JOIN dbo.T_Data_Analysis_Request_State_Name AS NewState
       ON Updates.New_State_ID = NewState.State_ID
     LEFT OUTER JOIN dbo.T_Users U
       ON Updates.Entered_By = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_Updates_List_Report] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Event_Log_Archive_Update_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_Archive_Update_List]
AS
SELECT EL.Event_ID,
       EL.Target_ID AS [Dataset ID],
       T_Dataset.Dataset_Num AS Dataset,
       T_Dataset_Archive_Update_State_Name.AUS_name AS [Old State],
       S1.AUS_name AS [New State],
       EL.Entered AS [Date]
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_Dataset_Archive_Update_State_Name S1
       ON EL.Target_State = S1.AUS_stateID
     INNER JOIN T_Dataset_Archive_Update_State_Name T_Dataset_Archive_Update_State_Name
       ON EL.Prev_Target_State = T_Dataset_Archive_Update_State_Name.AUS_stateID
WHERE EL.Target_Type = 7 AND
      EL.Entered > DateAdd(day, -4, GetDate())

GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Archive_Update_List] TO [DDL_Viewer] AS [dbo]
GO

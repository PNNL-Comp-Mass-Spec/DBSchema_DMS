/****** Object:  View [dbo].[V_Event_Log_Archive_List_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_Archive_List_2] 
as
SELECT EL.Event_ID,
       EL.Target_ID AS [Dataset ID],
       T_Dataset.Dataset_Num AS Dataset,
       'Update' AS [Type],
       OldState.AUS_name AS [Old State],
       NewState.AUS_name AS [New State],
       EL.Entered AS [Date]
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_Archive_Update_State_Name AS NewState
       ON EL.Target_State = NewState.AUS_stateID
     INNER JOIN T_Archive_Update_State_Name AS OldState
       ON EL.Prev_Target_State = OldState.AUS_stateID
WHERE EL.Target_Type = 7 AND
      EL.Entered > DateAdd(day, -4, GetDate())
UNION
SELECT EL.Event_ID,
       EL.Target_ID AS [Dataset ID],
       T_Dataset.Dataset_Num AS Dataset,
       'Archive' AS [Type],
       OldState.DASN_StateName AS [Old State],
       NewState.DASN_StateName AS [New State],
       EL.Entered AS [Date]
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_DatasetArchiveStateName AS NewState
       ON EL.Target_State = NewState.DASN_StateID
     INNER JOIN T_DatasetArchiveStateName AS OldState
       ON EL.Prev_Target_State = OldState.DASN_StateID
WHERE EL.Target_Type = 6 AND
      EL.Entered > DateAdd(day, -4, GetDate())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Archive_List_2] TO [DDL_Viewer] AS [dbo]
GO

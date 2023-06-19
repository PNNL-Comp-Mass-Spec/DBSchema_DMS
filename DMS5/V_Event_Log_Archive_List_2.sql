/****** Object:  View [dbo].[V_Event_Log_Archive_List_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_Archive_List_2]
AS
SELECT EL.event_id,
       EL.Target_ID AS dataset_id,
       T_Dataset.Dataset_Num AS dataset,
       'Update' AS type,
       OldState.AUS_name AS old_state,
       NewState.AUS_name AS new_state,
       EL.Entered AS date
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_Dataset_Archive_Update_State_Name AS NewState
       ON EL.Target_State = NewState.AUS_stateID
     INNER JOIN T_Dataset_Archive_Update_State_Name AS OldState
       ON EL.Prev_Target_State = OldState.AUS_stateID
WHERE EL.Target_Type = 7 AND
      EL.Entered > DateAdd(day, -4, GetDate())
UNION
SELECT EL.event_id,
       EL.Target_ID AS dataset_id,
       T_Dataset.Dataset_Num AS dataset,
       'Archive' AS type,
       OldState.archive_state AS old_state,
       NewState.archive_state AS new_state,
       EL.Entered AS date
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_Dataset_Archive_State_Name AS NewState
       ON EL.Target_State = NewState.archive_state_id
     INNER JOIN T_Dataset_Archive_State_Name AS OldState
       ON EL.Prev_Target_State = OldState.archive_state_id
WHERE EL.Target_Type = 6 AND
      EL.Entered > DateAdd(day, -4, GetDate())

GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Archive_List_2] TO [DDL_Viewer] AS [dbo]
GO

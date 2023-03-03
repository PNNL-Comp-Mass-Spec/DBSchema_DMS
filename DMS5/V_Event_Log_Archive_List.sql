/****** Object:  View [dbo].[V_Event_Log_Archive_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_Archive_List]
AS
SELECT EL.Event_ID,
       EL.Target_ID AS [Dataset ID],
       T_Dataset.Dataset_Num AS Dataset,
       OldState.archive_state AS [Old State],
       NewState.archive_state AS [New State],
       EL.Entered AS [Date]
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_Dataset_Archive_State_Name NewState
       ON EL.Target_State = NewState.archive_state_id
     INNER JOIN T_Dataset_Archive_State_Name OldState
       ON EL.Prev_Target_State = OldState.archive_state_id
WHERE EL.Target_Type = 6 AND
      EL.Entered > DateAdd(day, -4, GetDate())

GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Archive_List] TO [DDL_Viewer] AS [dbo]
GO

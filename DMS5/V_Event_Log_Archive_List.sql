/****** Object:  View [dbo].[V_Event_Log_Archive_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_Archive_List]
As
SELECT EL.Event_ID,
       EL.Target_ID AS [Dataset ID],
       T_Dataset.Dataset_Num AS Dataset,
       OldState.DASN_StateName AS [Old State],
       NewState.DASN_StateName AS [New State],
       EL.Entered AS [Date]
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_DatasetArchiveStateName NewState
       ON EL.Target_State = NewState.DASN_StateID
     INNER JOIN T_DatasetArchiveStateName OldState
       ON EL.Prev_Target_State = OldState.DASN_StateID
WHERE EL.Target_Type = 6 AND
      EL.Entered > DateAdd(day, -4, GetDate())



GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Archive_List] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Event_Log_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_Dataset_List]
As
SELECT EL.event_id,
       EL.Target_ID AS dataset_id,
       T_Dataset.Dataset_Num AS dataset,
       S2.DSS_name AS old_state,
       S1.DSS_name AS new_state,
       EL.Entered AS date,
       T_Instrument_Name.IN_name AS instrument
FROM T_Event_Log EL
     INNER JOIN T_Dataset
       ON EL.Target_ID = T_Dataset.Dataset_ID
     INNER JOIN T_DatasetStateName S1
       ON EL.Target_State = S1.Dataset_state_ID
     INNER JOIN T_DatasetStateName S2
       ON EL.Prev_Target_State = S2.Dataset_state_ID
     INNER JOIN T_Instrument_Name
       ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE EL.Target_Type = 4 AND
      EL.Entered > DateAdd(day, -4, GetDate())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Dataset_List] TO [DDL_Viewer] AS [dbo]
GO

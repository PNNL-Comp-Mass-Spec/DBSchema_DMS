/****** Object:  View [dbo].[V_Event_Log_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_Dataset_List]
As
SELECT EL.Event_ID,
       EL.Target_ID AS [Dataset ID],
       T_Dataset.Dataset_Num AS Dataset,
       S2.DSS_name AS [Old State],
       S1.DSS_name AS [New State],
       EL.Entered AS [Date],
       T_Instrument_Name.IN_name AS Instrument
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

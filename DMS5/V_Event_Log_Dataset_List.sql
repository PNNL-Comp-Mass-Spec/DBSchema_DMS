/****** Object:  View [dbo].[V_Event_Log_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






Create View V_Event_Log_Dataset_List
As
SELECT     T_Event_Log.[Index], T_Event_Log.Target_ID AS [Dataset ID], T_Dataset.Dataset_Num AS Dataset, S2.DSS_name AS [Old State], 
                      S1.DSS_name AS [New State], T_Event_Log.Entered AS Date, T_Instrument_Name.IN_name AS Instrument
FROM         T_Event_Log INNER JOIN
                      T_Dataset ON T_Event_Log.Target_ID = T_Dataset.Dataset_ID INNER JOIN
                      T_DatasetStateName S1 ON T_Event_Log.Target_State = S1.Dataset_state_ID INNER JOIN
                      T_DatasetStateName S2 ON T_Event_Log.Prev_Target_State = S2.Dataset_state_ID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE     (T_Event_Log.Target_Type = 4) AND (DATEDIFF(Day, T_Event_Log.Entered, GETDATE()) < 4)



GO

/****** Object:  View [dbo].[V_Event_Log_Archive_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





Create View V_Event_Log_Archive_List
As
SELECT     T_Event_Log.[Index], T_Event_Log.Target_ID AS [Dataset ID], T_Dataset.Dataset_Num AS Dataset, 
                      T_DatasetArchiveStateName_1.DASN_StateName AS [Old State], S1.DASN_StateName AS [New State], T_Event_Log.Entered AS Date
FROM         T_Event_Log INNER JOIN
                      T_Dataset ON T_Event_Log.Target_ID = T_Dataset.Dataset_ID INNER JOIN
                      T_DatasetArchiveStateName S1 ON T_Event_Log.Target_State = S1.DASN_StateID INNER JOIN
                      T_DatasetArchiveStateName T_DatasetArchiveStateName_1 ON 
                      T_Event_Log.Prev_Target_State = T_DatasetArchiveStateName_1.DASN_StateID
WHERE     (T_Event_Log.Target_Type = 6) AND (DATEDIFF(Day, T_Event_Log.Entered, GETDATE()) < 4)


GO

/****** Object:  View [dbo].[V_Event_Log_Analysis_Job_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





Create View V_Event_Log_Analysis_Job_List
As
SELECT     T_Event_Log.[Index], T_Event_Log.Target_ID AS Job, T_Dataset.Dataset_Num AS Dataset, T_Analysis_State_Name_1.AJS_name AS [Old State], 
                      S1.AJS_name AS [New State], T_Event_Log.Entered AS Date
FROM         T_Event_Log INNER JOIN
                      T_Analysis_State_Name S1 ON T_Event_Log.Target_State = S1.AJS_stateID INNER JOIN
                      T_Analysis_State_Name T_Analysis_State_Name_1 ON T_Event_Log.Prev_Target_State = T_Analysis_State_Name_1.AJS_stateID INNER JOIN
                      T_Analysis_Job ON T_Event_Log.Target_ID = T_Analysis_Job.AJ_jobID INNER JOIN
                      T_Dataset ON T_Analysis_Job.AJ_datasetID = T_Dataset.Dataset_ID
WHERE     (T_Event_Log.Target_Type = 5) AND (DATEDIFF(Day, T_Event_Log.Entered, GETDATE()) < 4)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Analysis_Job_List] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Event_Log_Analysis_Job_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[V_Event_Log_Analysis_Job_List]
As
SELECT EL.[Index],
       EL.Target_ID AS Job,
       T_Dataset.Dataset_Num AS Dataset,
       OldState.AJS_name AS [Old State],
       NewState.AJS_name AS [New State],
       EL.Entered AS [Date]
FROM T_Event_Log EL
     INNER JOIN T_Analysis_State_Name NewState
       ON EL.Target_State = NewState.AJS_stateID
     INNER JOIN T_Analysis_State_Name OldState
       ON EL.Prev_Target_State = OldState.AJS_stateID
     INNER JOIN T_Analysis_Job
       ON EL.Target_ID = T_Analysis_Job.AJ_jobID
     INNER JOIN T_Dataset
       ON T_Analysis_Job.AJ_datasetID = T_Dataset.Dataset_ID
WHERE EL.Target_Type = 5 AND
      EL.Entered > DateAdd(DAY, - 4, GetDate())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Analysis_Job_List] TO [DDL_Viewer] AS [dbo]
GO

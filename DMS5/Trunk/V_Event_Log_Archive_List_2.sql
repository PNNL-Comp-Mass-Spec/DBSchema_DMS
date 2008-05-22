/****** Object:  View [dbo].[V_Event_Log_Archive_List_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Event_Log_Archive_List_2 
as
SELECT 
  dbo.T_Event_Log.[Index],
  dbo.T_Event_Log.Target_ID            AS [Dataset ID],
  dbo.T_Dataset.Dataset_Num            AS Dataset,
   'Update' AS Type,
  T_Archive_Update_State_Name.AUS_name AS [Old State],
  S1.AUS_name                          AS [New State],
  dbo.T_Event_Log.Entered              AS DATE
FROM   
  dbo.T_Event_Log
  INNER JOIN dbo.T_Dataset
    ON dbo.T_Event_Log.Target_ID = dbo.T_Dataset.Dataset_ID
  INNER JOIN dbo.T_Archive_Update_State_Name AS S1
    ON dbo.T_Event_Log.Target_State = S1.AUS_stateID
  INNER JOIN dbo.T_Archive_Update_State_Name AS T_Archive_Update_State_Name
    ON dbo.T_Event_Log.Prev_Target_State = T_Archive_Update_State_Name.AUS_stateID
WHERE  (dbo.T_Event_Log.Target_Type = 7) 
AND (Datediff(DAY,dbo.T_Event_Log.Entered,Getdate()) < 4)
UNION
SELECT 
  dbo.T_Event_Log.[Index],
  dbo.T_Event_Log.Target_ID                  AS [Dataset ID],
  dbo.T_Dataset.Dataset_Num                  AS Dataset,
  'Archive' AS Type,
  T_DatasetArchiveStateName_1.DASN_StateName AS [Old State],
  S1.DASN_StateName                          AS [New State],
  dbo.T_Event_Log.Entered                    AS DATE
FROM   
  dbo.T_Event_Log
  INNER JOIN dbo.T_Dataset
    ON dbo.T_Event_Log.Target_ID = dbo.T_Dataset.Dataset_ID
  INNER JOIN dbo.T_DatasetArchiveStateName AS S1
    ON dbo.T_Event_Log.Target_State = S1.DASN_StateID
  INNER JOIN dbo.T_DatasetArchiveStateName AS T_DatasetArchiveStateName_1
    ON dbo.T_Event_Log.Prev_Target_State = T_DatasetArchiveStateName_1.DASN_StateID
WHERE  (dbo.T_Event_Log.Target_Type = 6)
AND (Datediff(DAY,dbo.T_Event_Log.Entered,Getdate()) < 4)

GO

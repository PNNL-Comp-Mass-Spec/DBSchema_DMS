/****** Object:  View [dbo].[V_Event_Log_Archive_Update_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Event_Log_Archive_Update_List
AS
SELECT     TOP 100 PERCENT dbo.T_Event_Log.[Index], dbo.T_Event_Log.Target_ID AS [Dataset ID], dbo.T_Dataset.Dataset_Num AS Dataset, 
                      T_Archive_Update_State_Name.AUS_name AS [Old State], S1.AUS_name AS [New State], dbo.T_Event_Log.Entered AS Date
FROM         dbo.T_Event_Log INNER JOIN
                      dbo.T_Dataset ON dbo.T_Event_Log.Target_ID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Archive_Update_State_Name S1 ON dbo.T_Event_Log.Target_State = S1.AUS_stateID INNER JOIN
                      dbo.T_Archive_Update_State_Name T_Archive_Update_State_Name ON 
                      dbo.T_Event_Log.Prev_Target_State = T_Archive_Update_State_Name.AUS_stateID
WHERE     (dbo.T_Event_Log.Target_Type = 7) AND (DATEDIFF(Day, dbo.T_Event_Log.Entered, GETDATE()) < 4)
ORDER BY dbo.T_Dataset.Dataset_Num, dbo.T_Event_Log.Entered DESC

GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_Archive_Update_List] TO [PNL\D3M578] AS [dbo]
GO

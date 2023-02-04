/****** Object:  View [dbo].[V_DMS_Dataset_Archive_Status] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Dataset_Archive_Status]
AS
SELECT DA.AS_Dataset_ID AS Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DS.DS_state_ID AS Dataset_State_ID,
       DA.AS_state_ID AS Archive_State_ID,
       DA.AS_state_Last_Affected AS Archive_State_Last_Affected,
       DA.AS_datetime AS Archive_Date,
       DA.AS_last_update AS Last_Update,
       DA.AS_update_state_ID AS Archive_Update_State_ID,
       DA.AS_update_state_Last_Affected AS Archive_Update_State_Last_Affected,
       DA.AS_Last_Successful_Archive AS Last_Successful_Archive
FROM S_DMS_T_Dataset_Archive DA
     INNER JOIN S_DMS_T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Dataset_Archive_Status] TO [DDL_Viewer] AS [dbo]
GO

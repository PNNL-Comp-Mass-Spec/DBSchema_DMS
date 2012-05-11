/****** Object:  View [dbo].[V_DMS_Get_New_Archive_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_Get_New_Archive_Datasets
AS
SELECT DA.AS_Dataset_ID AS Dataset_ID,
       DS.Dataset_Num AS Dataset
FROM S_DMS_T_Dataset_Archive DA
     INNER JOIN S_DMS_T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
WHERE (DA.AS_state_ID = 1)

GO

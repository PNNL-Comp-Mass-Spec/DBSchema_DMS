/****** Object:  View [dbo].[V_Analysis_Job_Use_MonoMass] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Use_MonoMass]
AS
SELECT dbo.T_Dataset.Dataset_ID,
       dbo.T_Dataset.Dataset_Num AS Dataset_Name,
       dbo.T_DatasetTypeName.DST_name AS Dataset_Type,
       CASE 
           WHEN DST_name LIKE 'HMS%' THEN 1
           ELSE 0
       END AS Use_Mono_Parent
FROM dbo.T_Dataset
     INNER JOIN dbo.T_DatasetTypeName
       ON dbo.T_Dataset.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Use_MonoMass] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Use_MonoMass] TO [PNL\D3M580] AS [dbo]
GO

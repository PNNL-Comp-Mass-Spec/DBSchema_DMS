/****** Object:  View [dbo].[V_GetDatasetsByInst] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW dbo.V_GetDatasetsByInst
AS
SELECT *
FROM T_Dataset INNER JOIN
   t_storage_path ON 
   T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID
WHERE (T_Dataset.DS_state_ID = 3)
GO

/****** Object:  View [dbo].[V_dataset_date] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/****** Object:  View dbo.V_dataset_date ******/

CREATE VIEW dbo.V_dataset_date
AS
SELECT Dataset_Num, { fn YEAR(DS_created) } AS year, 
   { fn MONTH(DS_created) } AS month, day(DS_created) 
   AS day
FROM T_Dataset
GO

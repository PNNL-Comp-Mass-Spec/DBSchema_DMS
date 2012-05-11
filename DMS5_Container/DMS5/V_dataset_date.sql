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
GRANT VIEW DEFINITION ON [dbo].[V_dataset_date] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_dataset_date] TO [PNL\D3M580] AS [dbo]
GO

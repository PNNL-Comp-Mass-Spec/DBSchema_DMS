/****** Object:  View [dbo].[V_Dataset_count_by_month] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Dataset_count_by_month
AS
SELECT year, month, COUNT(*) AS [Number of Datasets Created], 
   CONVERT(varchar(24), month) + '/' + CONVERT(varchar(24), year) 
   AS Date
FROM V_dataset_date
GROUP BY year, month
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_count_by_month] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_count_by_month] TO [PNL\D3M580] AS [dbo]
GO

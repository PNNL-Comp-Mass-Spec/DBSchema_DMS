/****** Object:  View [dbo].[V_Dataset_count_by_day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Dataset_count_by_day
AS
SELECT year, month, day, CONVERT(datetime, 
   CONVERT(varchar(24), month) + '/' + CONVERT(varchar(24), day) 
   + '/' + CONVERT(varchar(24), year)) AS date, COUNT(*) 
   AS [Number of Datasets Created]
FROM V_dataset_date
GROUP BY year, month, day
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_count_by_day] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_count_by_day] TO [PNL\D3M580] AS [dbo]
GO

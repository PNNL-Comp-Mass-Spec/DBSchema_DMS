/****** Object:  View [dbo].[V_Dataset_QC_Metric_Definitions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_QC_Metric_Definitions]
AS 
SELECT Metric,
       Short_Description,
	   Source,
       Category,
       Metric_Group,
       Metric_Value,
       Units,
       Optimal,
       Purpose,
       Description,       
       SortKey
FROM T_Dataset_QC_Metric_Names
WHERE Ignored = 0
-- Order By SortKey



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metric_Definitions] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metric_Definitions] TO [PNL\D3M580] AS [dbo]
GO

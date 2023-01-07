/****** Object:  View [dbo].[V_Dataset_QC_Metric_Definitions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_QC_Metric_Definitions]
AS
SELECT metric,
       short_description,
	   source,
       category,
       metric_group,
       metric_value,
       units,
       optimal,
       purpose,
       description,
       sortkey as sort_key
FROM T_Dataset_QC_Metric_Names
WHERE Ignored = 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metric_Definitions] TO [DDL_Viewer] AS [dbo]
GO

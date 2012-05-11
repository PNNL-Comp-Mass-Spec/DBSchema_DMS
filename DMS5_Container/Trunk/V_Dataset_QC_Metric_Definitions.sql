/****** Object:  View [dbo].[V_Dataset_QC_Metric_Definitions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_QC_Metric_Definitions]
AS 
SELECT Metric,
       Category,
       Metric_Group,
       Metric_Value,
       Units,
       Optimal,
       Purpose,
       Description
FROM T_Dataset_QC_Metric_Names


GO

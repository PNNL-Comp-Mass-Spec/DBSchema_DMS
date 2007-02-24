/****** Object:  View [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Tool_Helper_List_Report
AS
SELECT     AJT_toolName AS Name, AJT_resultType AS ResultType, AJT_allowedInstClass AS [Allowed Inst. Classes], AJT_orgDbReqd AS [OrgDB Req], 
                      AJT_extractionRequired AS [Extract Req], AJT_allowedDatasetTypes AS [Allowed DS Types]
FROM         dbo.T_Analysis_Tool
WHERE     (AJT_toolID > 0) AND (AJT_active = 1)

GO

/****** Object:  View [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report]
AS
SELECT Tool.AJT_toolName AS Name,
       Tool.AJT_resultType AS ResultType,
       Tool.AJT_allowedInstClass AS [Allowed Inst. Classes],
       Tool.AJT_orgDbReqd AS [OrgDB Req],
       Tool.AJT_extractionRequired AS [Extract Req],
       DSTypes.AllowedDatasetTypes AS [Allowed DS Types]       
FROM dbo.T_Analysis_Tool Tool CROSS 
    apply GetAnalysisToolAllowedDSTypeList(Tool.AJT_toolID) DSTypes
WHERE (Tool.AJT_toolID > 0) AND
      (Tool.AJT_active = 1)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report] TO [PNL\D3M580] AS [dbo]
GO

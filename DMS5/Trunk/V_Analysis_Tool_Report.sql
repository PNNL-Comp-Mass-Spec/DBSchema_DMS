/****** Object:  View [dbo].[V_Analysis_Tool_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Tool_Report]
AS
SELECT Tool.AJT_toolName AS Name,
       Tool.AJT_toolID as ID,
       Tool.AJT_resultType AS ResultType,
       Tool.AJT_parmFileStoragePath AS [Param file storage (client)],
       Tool.AJT_parmFileStoragePathLocal AS [Param file storage (server)],
       InstClasses.AllowedInstrumentClasses AS [Allowed Inst. Classes],
       Tool.AJT_defaultSettingsFileName AS [Default Settings File],
       Tool.AJT_active AS Active,
       AJT_orgDbReqd AS [OrgDB Req],
       Tool.AJT_extractionRequired AS [Extract Req],
       DSTypes.AllowedDatasetTypes AS [Allowed DS Types]
FROM T_Analysis_Tool Tool
     CROSS APPLY dbo.GetAnalysisToolAllowedDSTypeList ( Tool.AJT_toolID ) DSTypes
     CROSS APPLY dbo.GetAnalysisToolAllowedInstClassList ( Tool.AJT_toolID ) InstClasses
WHERE (Tool.AJT_toolID > 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Report] TO [PNL\D3M580] AS [dbo]
GO

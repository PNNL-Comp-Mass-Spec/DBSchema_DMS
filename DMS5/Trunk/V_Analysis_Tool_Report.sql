/****** Object:  View [dbo].[V_Analysis_Tool_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Tool_Report
AS
SELECT     AJT_toolName AS Name, AJT_resultType AS ResultType, AJT_parmFileStoragePath AS [Param file storage (client)], 
                      AJT_parmFileStoragePathLocal AS [Param file storage (server)], AJT_allowedInstClass AS [Allowed Inst. Classes], 
                      AJT_defaultSettingsFileName AS [Default Settings File], AJT_active AS Active
FROM         dbo.T_Analysis_Tool
WHERE     (AJT_toolID > 0)

GO

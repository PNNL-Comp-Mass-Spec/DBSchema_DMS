/****** Object:  View [dbo].[V_Param_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Param_File_Picklist]
AS
SELECT PF.Param_File_Name AS "Name",
       PF.Param_File_Description AS "Desc",
       ISNULL(ParamUsageQ.JobCount, 0) AS "Job Count",
       AnTool.AJT_toolName AS ToolName
FROM dbo.T_Param_Files PF
     INNER JOIN dbo.T_Analysis_Tool AnTool
       ON PF.Param_File_Type_ID = AnTool.AJT_paramFileType
     LEFT OUTER JOIN ( SELECT AJ_analysisToolID,
                              AJ_parmFileName,
                              COUNT(*) AS JobCount
                       FROM dbo.T_Analysis_Job
                       WHERE AJ_Created >= DateAdd(year, -2, GetDate())
                       GROUP BY AJ_parmFileName, AJ_analysisToolID ) ParamUsageQ
       ON AnTool.AJT_toolID = ParamUsageQ.AJ_analysisToolID AND
          PF.Param_File_Name = ParamUsageQ.AJ_parmFileName
WHERE (PF.Valid = 1)

GO

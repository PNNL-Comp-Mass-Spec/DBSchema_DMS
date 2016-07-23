/****** Object:  View [dbo].[V_Param_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Picklist]
AS
SELECT PF.Param_File_Name AS [Name],
       PF.Param_File_Description AS [Desc],
	   ISNULL(PF.Job_Usage_Last_Year, 0) AS [Job Count],
       ISNULL(PF.Job_Usage_Count, 0) AS [Jobs (all time)],
       PF.Param_File_ID AS ID,
       AnTool.AJT_toolName AS ToolName,
	   CASE WHEN ISNULL(PF.Job_Usage_Last_Year, 0) > 0 THEN PF.Job_Usage_Last_Year + 1000000 ELSE ISNULL(PF.Job_Usage_Count, 0) END as SortKey
FROM dbo.T_Param_Files PF
     INNER JOIN dbo.T_Analysis_Tool AnTool
       ON PF.Param_File_Type_ID = AnTool.AJT_paramFileType    
WHERE (PF.Valid = 1)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Picklist] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Picklist] TO [PNL\D3M580] AS [dbo]
GO

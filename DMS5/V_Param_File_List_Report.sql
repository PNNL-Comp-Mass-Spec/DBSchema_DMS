/****** Object:  View [dbo].[V_Param_File_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_List_Report]
AS
SELECT PF.param_file_id,
       PF.param_file_name,
       PFT.param_file_type,
       PF.param_file_description,
       Tool.AJT_toolName AS primary_tool,
       PF.date_created,
       PF.date_modified,
       PF.job_usage_count,
       PF.job_usage_last_year,
       PF.valid,
       PF.mod_list
FROM T_Param_Files PF
     INNER JOIN T_Param_File_Types PFT
       ON PF.Param_File_Type_ID = PFT.Param_File_Type_ID
     INNER JOIN T_Analysis_Tool Tool
       ON PFT.Primary_Tool_ID = Tool.AJT_toolID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_List_Report] TO [DDL_Viewer] AS [dbo]
GO

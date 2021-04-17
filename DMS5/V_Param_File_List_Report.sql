/****** Object:  View [dbo].[V_Param_File_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_List_Report]
AS
SELECT PF.Param_File_ID,
       PF.Param_File_Name,
       PFT.Param_File_Type,
       PF.Param_File_Description,
       Tool.AJT_toolName AS Primary_Tool,
       PF.Date_Created,
       PF.Date_Modified,
       PF.Job_Usage_Count,
       PF.Job_Usage_Last_Year,
       PF.Valid
FROM T_Param_Files PF
     INNER JOIN T_Param_File_Types PFT
       ON PF.Param_File_Type_ID = PFT.Param_File_Type_ID
     INNER JOIN T_Analysis_Tool Tool       
       ON PFT.Primary_Tool_ID = Tool.AJT_toolID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_List_Report] TO [DDL_Viewer] AS [dbo]
GO

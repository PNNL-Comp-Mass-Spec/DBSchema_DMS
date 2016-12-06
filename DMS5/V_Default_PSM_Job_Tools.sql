/****** Object:  View [dbo].[V_Default_PSM_Job_Tools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Default_PSM_Job_Tools]
AS  
SELECT DISTINCT T_Default_PSM_Job_Settings.Tool_Name,
                T_Analysis_Tool.AJT_Description AS Description
FROM T_Default_PSM_Job_Settings
     INNER JOIN T_Analysis_Tool
       ON T_Default_PSM_Job_Settings.Tool_Name = T_Analysis_Tool.AJT_toolName
WHERE T_Default_PSM_Job_Settings.Enabled > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Default_PSM_Job_Tools] TO [DDL_Viewer] AS [dbo]
GO

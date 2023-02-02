/****** Object:  View [dbo].[V_Get_Pipeline_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Get_Pipeline_Settings_Files]
AS
SELECT id,
       analysis_tool,
       file_name,
       description,
       active,
       last_updated,
       contents,
       job_usage_count
FROM dbo.T_Settings_Files


GO
GRANT VIEW DEFINITION ON [dbo].[V_Get_Pipeline_Settings_Files] TO [DDL_Viewer] AS [dbo]
GO

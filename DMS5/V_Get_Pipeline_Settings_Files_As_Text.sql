/****** Object:  View [dbo].[V_Get_Pipeline_Settings_Files_As_Text] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Get_Pipeline_Settings_Files_As_Text]
AS
SELECT id,
       analysis_tool,
       file_name,
       description,
       active,
       last_updated,
       CONVERT(varchar(MAX), Contents) AS contents,
       job_usage_count
FROM dbo.T_Settings_Files


GO

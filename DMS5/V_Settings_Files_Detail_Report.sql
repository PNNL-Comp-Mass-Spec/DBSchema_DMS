/****** Object:  View [dbo].[V_Settings_Files_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Settings_Files_Detail_Report]
AS
SELECT id,
       analysis_tool,
       file_name,
       description,
       active,
       job_usage_count,
       msgfplus_autocentroid AS msgfplus_auto_centroid,
       hms_autosupersede AS hms_auto_supersede,
       dbo.xml_to_html(contents) AS contents
FROM dbo.T_Settings_Files

GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO

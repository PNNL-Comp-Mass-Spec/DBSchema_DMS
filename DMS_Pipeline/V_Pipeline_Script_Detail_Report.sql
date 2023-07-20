/****** Object:  View [dbo].[V_Pipeline_Script_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Pipeline_Script_Detail_Report]
AS
SELECT id,
       script,
       description,
       enabled,
       results_tag,
       Case When Backfill_to_DMS = 0 Then 'N' Else 'Y' End AS backfill_to_dms,
       '<pre>' + REPLACE(REPLACE(LTRIM(RTRIM(REPLACE(CONVERT(varchar(MAX), Contents),   '<', CHAR(13) + CHAR(10) + '<'))), '<', '&lt;'), '>', '&gt;')
       + '</pre>' AS contents,
       '<pre>' + REPLACE(REPLACE(LTRIM(RTRIM(REPLACE(CONVERT(varchar(MAX), Parameters), '<', CHAR(13) + CHAR(10) + '<'))), '<', '&lt;'), '>', '&gt;')
       + '</pre>' AS parameters,
       '<pre>' + REPLACE(REPLACE(LTRIM(RTRIM(REPLACE(CONVERT(varchar(MAX), Fields), '<', CHAR(13) + CHAR(10) + '<'))), '<', '&lt;'), '>', '&gt;')
       + '</pre>' AS fields_for_wizard
FROM T_Scripts

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO

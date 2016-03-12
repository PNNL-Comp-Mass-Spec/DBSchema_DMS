/****** Object:  View [dbo].[V_Pipeline_Script_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Pipeline_Script_Detail_Report] as
SELECT ID,
       Script,
       Description,
       Enabled,
       Results_Tag,
       Case When Backfill_to_DMS = 0 Then 'N' Else 'Y' End AS Backfill_to_DMS,
       '<pre>' + REPLACE(REPLACE(LTRIM(RTRIM(REPLACE(CONVERT(varchar(MAX), Contents),   '<', CHAR(13) + CHAR(10) + '<'))), '<', '&lt;'), '>', '&gt;') 
       + '</pre>' AS Contents,
       '<pre>' + REPLACE(REPLACE(LTRIM(RTRIM(REPLACE(CONVERT(varchar(MAX), Parameters), '<', CHAR(13) + CHAR(10) + '<'))), '<', '&lt;'), '>', '&gt;') 
       + '</pre>' AS Parameters,
       '<pre>' + REPLACE(REPLACE(LTRIM(RTRIM(REPLACE(CONVERT(varchar(MAX), Fields), '<', CHAR(13) + CHAR(10) + '<'))), '<', '&lt;'), '>', '&gt;') 
       + '</pre>' AS Fields_for_Wizard
FROM T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO

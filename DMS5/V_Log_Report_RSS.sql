/****** Object:  View [dbo].[V_Log_Report_RSS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Log_Report_RSS
AS
SELECT Entry AS url_title,
       CONVERT(varchar(12), Entry) + ' - ' + Message AS post_title,
       CONVERT(varchar(12), Entry) AS guid,
       [Posted_By] + ' ' + Message AS post_body,
       'na' AS u_prn,
       Entered AS post_date
FROM dbo.V_Log_Report
WHERE (TYPE = 'Error') AND
      (NOT (Message LIKE '%Error posting xml%'))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Report_RSS] TO [DDL_Viewer] AS [dbo]
GO

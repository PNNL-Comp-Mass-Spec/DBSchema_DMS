/****** Object:  View [dbo].[V_Log_Report_RSS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Log_Report_RSS
AS
SELECT     Entry AS url_title, CONVERT(VARCHAR(12), Entry) + ' - ' + Message AS post_title, CONVERT(VARCHAR(12), Entry) AS guid, 
                      [Posted By] + ' ' + Message AS post_body, 'na' AS U_PRN, [Posting Time] AS post_date
FROM         dbo.V_Log_Report
WHERE     (Type = 'Error') AND (NOT (Message LIKE '%Error posting xml%'))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Report_RSS] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Report_RSS] TO [PNL\D3M580] AS [dbo]
GO

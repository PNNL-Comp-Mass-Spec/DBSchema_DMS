/****** Object:  View [dbo].[V_Analysis_Log_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW dbo.V_Analysis_Log_Report
AS
SELECT Entry_ID AS Entry, posted_by AS [Posted By], 
   posting_time AS [Posting Time], type, message
FROM T_Analysis_Log
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Log_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Log_Report] TO [PNL\D3M580] AS [dbo]
GO

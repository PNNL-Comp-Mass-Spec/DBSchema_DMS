/****** Object:  View [dbo].[V_Log_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW dbo.V_Log_Report
AS
SELECT Entry_ID AS Entry, posted_by AS [Posted By], 
   posting_time AS [Posting Time], type AS Type, 
   message AS Message
FROM T_Log_Entries
GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Report] TO [PNL\D3M578] AS [dbo]
GO

/****** Object:  View [dbo].[V_Historic_Log_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Historic_Log_Report]
AS
SELECT Entry_ID AS Entry, posted_by AS [Posted By], 
   Entered AS [Posting Time], type AS Type, 
   message AS Message
FROM T_Log_Entries


GO
GRANT VIEW DEFINITION ON [dbo].[V_Historic_Log_Report] TO [DDL_Viewer] AS [dbo]
GO

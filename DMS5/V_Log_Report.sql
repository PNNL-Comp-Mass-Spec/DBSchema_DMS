/****** Object:  View [dbo].[V_Log_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Log_Report]
AS
SELECT Entry_ID AS entry, posted_by AS posted_by,
   entered, type AS type,
   message AS message
FROM T_Log_Entries


GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Report] TO [DDL_Viewer] AS [dbo]
GO

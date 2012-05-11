/****** Object:  View [dbo].[V_Log_Errors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Log_Errors
AS
SELECT Entry_ID, posted_by, posting_time, type, message, '' AS Entered_By
FROM T_Log_Entries
WHERE (type = 'Error')
GO

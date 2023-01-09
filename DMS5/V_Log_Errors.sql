/****** Object:  View [dbo].[V_Log_Errors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Log_Errors
AS
SELECT entry_id, posted_by, entered, type, message, '' AS entered_by
FROM T_Log_Entries
WHERE (type = 'Error')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Errors] TO [DDL_Viewer] AS [dbo]
GO

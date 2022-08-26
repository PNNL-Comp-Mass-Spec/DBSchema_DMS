/****** Object:  View [dbo].[V_Log_Errors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Log_Errors]
AS
SELECT Entry_ID, posted_by, Entered, 
    type, message, Entered_By
FROM T_Log_Entries
WHERE (type = 'error')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Errors] TO [DDL_Viewer] AS [dbo]
GO

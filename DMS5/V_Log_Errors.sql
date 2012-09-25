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
GRANT VIEW DEFINITION ON [dbo].[V_Log_Errors] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Errors] TO [PNL\D3M580] AS [dbo]
GO

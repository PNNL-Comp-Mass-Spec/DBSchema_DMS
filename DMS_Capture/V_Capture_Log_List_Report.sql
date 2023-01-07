/****** Object:  View [dbo].[V_Capture_Log_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Log_List_Report
AS
SELECT entry_id as id, posted_by, entered as time, type, message, entered_by
FROM dbo.T_Log_Entries


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Log_List_Report] TO [DDL_Viewer] AS [dbo]
GO

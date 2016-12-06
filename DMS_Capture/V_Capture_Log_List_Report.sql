/****** Object:  View [dbo].[V_Capture_Log_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Log_List_Report
AS
SELECT     Entry_ID AS ID, posted_by AS Posted_By, posting_time AS Time, type AS Type, message AS Message, Entered_By
FROM         dbo.T_Log_Entries

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Log_List_Report] TO [DDL_Viewer] AS [dbo]
GO

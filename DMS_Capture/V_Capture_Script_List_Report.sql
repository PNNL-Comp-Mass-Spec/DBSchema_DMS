/****** Object:  View [dbo].[V_Capture_Script_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Script_List_Report]
AS
SELECT script, description, enabled, results_tag, id
FROM dbo.T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Script_List_Report] TO [DDL_Viewer] AS [dbo]
GO

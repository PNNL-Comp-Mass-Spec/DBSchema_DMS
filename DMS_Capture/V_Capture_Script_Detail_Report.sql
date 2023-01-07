/****** Object:  View [dbo].[V_Capture_Script_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Script_Detail_Report]
AS
SELECT id, script, description, enabled, results_tag
FROM dbo.T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Script_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Pipeline_Script_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Pipeline_Script_List_Report
AS
SELECT script,
       description,
       enabled,
       results_tag,
       id,
       Case When Backfill_to_DMS = 0 Then 'N' Else 'Y' End AS backfill_to_dms
FROM dbo.T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_List_Report] TO [DDL_Viewer] AS [dbo]
GO

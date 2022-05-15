/****** Object:  View [dbo].[V_Pipeline_Script_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Script_Entry]
AS
SELECT id,
       script,
       description,
       enabled,
       results_tag,
       Case When Backfill_to_DMS = 0 Then 'N' Else 'Y' End AS backfill_to_dms,
       contents,
       parameters,
       fields
FROM dbo.T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_Entry] TO [DDL_Viewer] AS [dbo]
GO

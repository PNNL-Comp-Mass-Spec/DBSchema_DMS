/****** Object:  View [dbo].[V_Capture_Script_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [V_Capture_Script_Entry]
AS
SELECT
    id,
    script,
    description,
    enabled,
    results_tag,
    contents
FROM T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Script_Entry] TO [DDL_Viewer] AS [dbo]
GO

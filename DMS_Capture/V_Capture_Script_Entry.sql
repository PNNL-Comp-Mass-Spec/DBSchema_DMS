/****** Object:  View [dbo].[V_Capture_Script_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [V_Capture_Script_Entry]
AS
SELECT 
    ID AS ID, 
    Script AS Script, 
    Description AS Description, 
    Enabled AS Enabled, 
    Results_Tag AS ResultsTag, 
    Contents AS Contents
FROM T_Scripts

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Script_Entry] TO [DDL_Viewer] AS [dbo]
GO

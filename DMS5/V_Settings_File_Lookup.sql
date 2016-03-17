/****** Object:  View [dbo].[V_Settings_File_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Settings_File_Lookup
AS
(
SELECT SourceQ.Analysis_Tool,
SourceQ.File_Name,       
       SourceQ.Mapped_Tool
FROM (SELECT SF.File_Name,
             SF.Analysis_Tool,
             SF.Analysis_Tool AS Mapped_Tool
      FROM dbo.T_Settings_Files SF
           INNER JOIN dbo.T_Analysis_Tool AnTool
             ON SF.Analysis_Tool = AnTool.AJT_toolName
      WHERE (SF.Active <> 0)
      UNION
      SELECT SF.File_Name,
             AnTool.AJT_toolName AS Analysis_Tool,
             SF.Analysis_Tool AS Mapped_Tool
      FROM T_Settings_Files SF
           INNER JOIN T_Analysis_Tool AnTool
             ON SF.Analysis_Tool = AnTool.AJT_toolBasename
      WHERE (SF.Active <> 0) ) SourceQ
)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_File_Lookup] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_File_Lookup] TO [PNL\D3M580] AS [dbo]
GO

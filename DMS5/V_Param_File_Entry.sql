/****** Object:  View [dbo].[V_Param_File_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Entry]
AS
SELECT pf.param_file_id,
       pf.param_file_name,
       pft.param_file_type,
       pf.param_file_description,
       pf.valid,
	   '# Paste the static and dynamic mods here from a MSGF+ or MSPathFinder parameter file' + char(10) +
	   '# Typically used when creating new parameter files' + char(10) +
	   '# Can also be used with existing parameter files if mass mods are not yet defined' + Char(10) +
	   '# Alternatively, enable "Replace Existing Mass Mods"' AS mass_mods
FROM T_Param_Files PF
     INNER JOIN T_Param_File_Types PFT
       ON PF.Param_File_Type_ID = PFT.Param_File_Type_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Entry] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Peptide_Mod_Param_File_List_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Peptide_Mod_Param_File_List_Export
AS
SELECT TOP 100 PERCENT dbo.T_Param_Files.Param_File_Name, 
    dbo.T_Seq_Local_Symbols_List.Local_Symbol, 
    dbo.T_Peptide_Mod_Param_File_List.Mod_ID, 
    dbo.T_Peptide_Mod_Param_File_List.RefNum, 
    dbo.T_Peptide_Mod_Param_File_List.Param_File_ID
FROM dbo.T_Peptide_Mod_Param_File_List INNER JOIN
    dbo.T_Param_Files ON 
    dbo.T_Peptide_Mod_Param_File_List.Param_File_ID = dbo.T_Param_Files.Param_File_ID
     INNER JOIN
    dbo.T_Seq_Local_Symbols_List ON 
    dbo.T_Peptide_Mod_Param_File_List.Local_Symbol_ID = dbo.T_Seq_Local_Symbols_List.Local_Symbol_ID

GO

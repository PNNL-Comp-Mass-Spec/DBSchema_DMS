/****** Object:  View [dbo].[V_Archived_Output_File_Stats_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archived_Output_File_Stats_Export]
AS
SELECT AOF.Archived_File_ID,
       AOF.Filesize AS File_Size_Bytes,
       COUNT(PC.Protein_Collection_ID) AS Protein_Collection_Count,
       SUM(PC.NumProteins) AS Protein_Count,
       SUM(PC.NumResidues) AS Residue_Count,
       dbo.udfGetFileNameFromPath(AOF.Archived_File_Path) AS Archived_File_Name
FROM dbo.T_Archived_Output_Files AOF
     INNER JOIN dbo.T_Archived_Output_File_Collections_XRef AOFC
       ON AOF.Archived_File_ID = AOFC.Archived_File_ID
     INNER JOIN dbo.T_Protein_Collections PC
       ON AOFC.Protein_Collection_ID = PC.Protein_Collection_ID
GROUP BY AOF.Archived_File_ID, AOF.Filesize, dbo.udfGetFileNameFromPath(AOF.Archived_File_Path)


GO

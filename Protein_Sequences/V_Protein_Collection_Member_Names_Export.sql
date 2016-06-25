/****** Object:  View [dbo].[V_Protein_Collection_Member_Names_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_Member_Names_Export]
AS
SELECT PCM.Protein_Collection_ID,
       PC.FileName AS Protein_Collection,
       PCM.Protein_Name,
       PCM.Description,
       PCM.Residue_Count,
       PCM.Monoisotopic_Mass,
       PCM.Protein_ID,
       PCM.Reference_ID
FROM T_Protein_Collection_Members_Cached PCM
     INNER JOIN T_Protein_Collections PC
       ON PCM.Protein_Collection_ID = PC.Protein_Collection_ID


GO

/****** Object:  View [dbo].[V_Collection_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Collection_Picker]
AS
SELECT PC.[FileName] AS [Name],
       PC.Protein_Collection_ID AS ID,
       PC.[Description],
       PC.[Source],
       PC.NumProteins AS Entries,
       PC.NumResidues AS Residues,
       OrgList.[Name] AS Organism_Name,
       PCTypes.[Type],
       AOF.Filesize,
       OrgXref.Organism_ID
FROM T_Protein_Collections PC
     INNER JOIN T_Collection_Organism_Xref OrgXref
       ON PC.Protein_Collection_ID = OrgXref.Protein_Collection_ID
     INNER JOIN MT_Main.dbo.T_DMS_Organisms OrgList
       ON OrgXref.Organism_ID = OrgList.Organism_ID
     INNER JOIN T_Protein_Collection_Types AS PCTypes
       ON PC.Collection_Type_ID = PCTypes.Collection_Type_ID
     LEFT OUTER JOIN dbo.T_Archived_Output_Files AS AOF
       ON PC.Authentication_Hash = AOF.Authentication_Hash
WHERE PC.Collection_State_ID BETWEEN 1 AND 3


GO

/****** Object:  View [dbo].[V_Protein_Collections_By_Organism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collections_By_Organism]
AS
SELECT DISTINCT PC.Protein_Collection_ID,
                PC.Collection_Name + ' (' + CAST(PC.NumProteins AS varchar) + ' Entries)' AS [Display],
                PC.[Description],
                PC.Source,
                PC.Collection_State_ID,
                PCS.State AS State_Name,
                PC.Collection_Type_ID,
                PCTypes.[Type],
                PC.NumProteins,
                PC.NumResidues,
                PC.Authentication_Hash,
                PC.Collection_Name,
                OrgXref.Organism_ID,
                PC.Primary_Annotation_Type_ID AS Authority_ID,
                OrgList.[Name] AS Organism_Name,
                PC.Contents_Encrypted,
                PC.Includes_Contaminants,
                AOF.Filesize
FROM T_Protein_Collections PC
     INNER JOIN T_Collection_Organism_Xref OrgXref
       ON PC.Protein_Collection_ID = OrgXref.Protein_Collection_ID
     INNER JOIN MT_Main.dbo.T_DMS_Organisms OrgList
       ON OrgXref.Organism_ID = OrgList.Organism_ID
     INNER JOIN T_Protein_Collection_Types AS PCTypes
       ON PC.Collection_Type_ID = PCTypes.Collection_Type_ID
     INNER JOIN T_Protein_Collection_States PCS
       ON PC.Collection_State_ID = PCS.Collection_State_ID
     LEFT OUTER JOIN dbo.T_Archived_Output_Files AS AOF
       ON PC.Authentication_Hash = AOF.Authentication_Hash


GO
GRANT SELECT ON [dbo].[V_Protein_Collections_By_Organism] TO [pnl\d3l243] AS [dbo]
GO

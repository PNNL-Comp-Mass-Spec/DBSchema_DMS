/****** Object:  View [dbo].[V_Protein_Collection_List_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_List_Export]
AS
SELECT PC.Protein_Collection_ID,
       PC.Collection_Name AS Name,
       PC.Description,
       PCS.State AS Collection_State,
       PCT.Type AS Collection_Type,
       PC.NumProteins AS Protein_Count,
       PC.NumResidues AS Residue_Count,
       NameAuth.Name AS Annotation_Naming_Authority,
       AnType.TypeName AS Annotation_Type,
       OrgXref.Organism_ID,
       PC.DateCreated AS Created,
       PC.DateModified AS Last_Modified,
       PC.Authentication_Hash,
       PC.Collection_RowVersion
FROM dbo.T_Protein_Collections PC
     INNER JOIN dbo.T_Protein_Collection_Types PCT
       ON PC.Collection_Type_ID = PCT.Collection_Type_ID
     INNER JOIN dbo.T_Protein_Collection_States PCS
       ON PC.Collection_State_ID = PCS.Collection_State_ID
     INNER JOIN dbo.T_Annotation_Types AnType
       ON PC.Primary_Annotation_Type_ID = AnType.Annotation_Type_ID
     INNER JOIN dbo.T_Naming_Authorities NameAuth
       ON AnType.Authority_ID = NameAuth.Authority_ID
     LEFT OUTER JOIN dbo.T_Collection_Organism_Xref OrgXref
       ON PC.Protein_Collection_ID = OrgXref.Protein_Collection_ID

GO

/****** Object:  View [dbo].[V_Protein_Collection_List_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Collection_List_Export
AS
SELECT dbo.T_Protein_Collections.Protein_Collection_ID, 
    dbo.T_Protein_Collections.FileName AS Name, 
    dbo.T_Protein_Collections.Description, 
    dbo.T_Protein_Collection_States.State AS Collection_State, 
    dbo.T_Protein_Collection_Types.Type AS Collection_Type, 
    dbo.T_Protein_Collections.NumProteins AS Protein_Count, 
    dbo.T_Protein_Collections.NumResidues AS Residue_Count, 
    dbo.T_Naming_Authorities.Name AS Annotation_Naming_Authority,
     dbo.T_Annotation_Types.TypeName AS Annotation_Type, 
    dbo.T_Collection_Organism_Xref.Organism_ID, 
    dbo.T_Protein_Collections.DateCreated AS Created, 
    dbo.T_Protein_Collections.DateModified AS Last_Modified, 
    dbo.T_Protein_Collections.Authentication_Hash
FROM dbo.T_Protein_Collections INNER JOIN
    dbo.T_Protein_Collection_Types ON 
    dbo.T_Protein_Collections.Collection_Type_ID = dbo.T_Protein_Collection_Types.Collection_Type_ID
     INNER JOIN
    dbo.T_Protein_Collection_States ON 
    dbo.T_Protein_Collections.Collection_State_ID = dbo.T_Protein_Collection_States.Collection_State_ID
     INNER JOIN
    dbo.T_Annotation_Types ON 
    dbo.T_Protein_Collections.Primary_Annotation_Type_ID = dbo.T_Annotation_Types.Annotation_Type_ID
     INNER JOIN
    dbo.T_Naming_Authorities ON 
    dbo.T_Annotation_Types.Authority_ID = dbo.T_Naming_Authorities.Authority_ID
     LEFT OUTER JOIN
    dbo.T_Collection_Organism_Xref ON 
    dbo.T_Protein_Collections.Protein_Collection_ID = dbo.T_Collection_Organism_Xref.Protein_Collection_ID

GO

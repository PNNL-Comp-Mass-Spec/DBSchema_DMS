/****** Object:  View [dbo].[V_Protein_Collections_List_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collections_List_Report_Ex]
AS
SELECT PC.Collection_Name AS [Name],
       OrgPicker.Organism_Name AS [Organism Name],
       OrgXref.Organism_ID AS [Organism ID],
       PC.[Description],
       PC.NumProteins AS [Protein Count],
       PC.NumResidues AS [Residue Count],
       NamingAuth.[Name] + ' - ' + AnType.TypeName AS [Annotation Type],
       PC.DateCreated AS Created,
       PC.DateModified AS [Last Modified],
       PCS.[State],
       PC.Protein_Collection_ID AS [Collection ID]
FROM T_Annotation_Types AnType
     INNER JOIN T_Naming_Authorities NamingAuth
       ON AnType.Authority_ID = NamingAuth.Authority_ID
     INNER JOIN T_Protein_Collections PC
                INNER JOIN T_Protein_Collection_States PCS
                  ON PC.Collection_State_ID = PCS.Collection_State_ID
       ON AnType.Annotation_Type_ID = PC.Primary_Annotation_Type_ID
     INNER JOIN T_Collection_Organism_Xref OrgXref
       ON PC.Protein_Collection_ID = OrgXref.Protein_Collection_ID
     INNER JOIN V_Organism_Picker OrgPicker
       ON OrgXref.Organism_ID = OrgPicker.ID



GO

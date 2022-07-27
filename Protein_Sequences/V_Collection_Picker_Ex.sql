/****** Object:  View [dbo].[V_Collection_Picker_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Collection_Picker_Ex]
AS
SELECT DISTINCT PC.Collection_Name AS Name,
                PC.Protein_Collection_ID AS ID,
                PC.Description,
                PC.NumProteins AS Entries,
                dbo.V_Organism_Picker.Organism_Name,
                dbo.T_Protein_Collection_Types.Display AS Type,
                dbo.V_Organism_Picker.Organism_Name_Abbrev_Genus AS Short_Name,
                PC.Authentication_Hash AS Auth_Hash,
                dbo.V_Annotation_Type_Picker.Display_Name AS Authority_Display,
  CASE
      WHEN NameAuth.Description IS NOT NULL THEN NameAuth.Description
      ELSE 'Other'
  END AS Authority_Name,
                CASE
                    WHEN NameAuth.Web_Address IS NOT NULL THEN
                      NameAuth.Web_Address
                    ELSE '(Not Specified)'
                END AS Authority_Address,
                PC.DateCreated AS Creation_Date,
                dbo.V_Organism_Picker.Search_Terms AS Organism_Path
FROM dbo.T_Protein_Collections PC
     INNER JOIN dbo.T_Collection_Organism_Xref
       ON PC.Protein_Collection_ID 
          = dbo.T_Collection_Organism_Xref.Protein_Collection_ID
     INNER JOIN dbo.V_Organism_Picker
       ON dbo.T_Collection_Organism_Xref.Organism_ID = dbo.V_Organism_Picker.ID
     INNER JOIN dbo.T_Protein_Collection_Types
       ON PC.Collection_Type_ID 
          = dbo.T_Protein_Collection_Types.Collection_Type_ID
     INNER JOIN dbo.V_Annotation_Type_Picker
       ON PC.Primary_Annotation_Type_ID = dbo.V_Annotation_Type_Picker.ID
     INNER JOIN dbo.T_Naming_Authorities NameAuth
       ON dbo.V_Annotation_Type_Picker.Authority_ID = NameAuth.Authority_ID
WHERE (PC.Collection_State_ID BETWEEN 1 AND 3)

GO

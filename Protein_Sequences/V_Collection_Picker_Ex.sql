/****** Object:  View [dbo].[V_Collection_Picker_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Collection_Picker_Ex
AS
SELECT DISTINCT 
                      TOP (100) PERCENT dbo.T_Protein_Collections.FileName AS Name, dbo.T_Protein_Collections.Protein_Collection_ID AS ID, 
                      dbo.T_Protein_Collections.Description, dbo.T_Protein_Collections.NumProteins AS Entries, dbo.V_Organism_Picker.Organism_Name, 
                      dbo.T_Protein_Collection_Types.Display AS Type, dbo.V_Organism_Picker.Organism_Name_Abbrev_Genus AS Short_Name, 
                      dbo.T_Protein_Collections.Authentication_Hash AS Auth_Hash, dbo.V_Annotation_Type_Picker.Display_Name AS Authority_Display, 
                      CASE WHEN T_Naming_Authorities.Description IS NOT NULL THEN T_Naming_Authorities.Description ELSE 'Other' END AS Authority_Name, 
                      CASE WHEN dbo.T_Naming_Authorities.Web_Address IS NOT NULL 
                      THEN dbo.T_Naming_Authorities.Web_Address ELSE '(Not Specified)' END AS Authority_Address, 
                      dbo.T_Protein_Collections.DateCreated AS Creation_Date, dbo.V_Organism_Picker.Search_Terms AS Organism_Path
FROM         dbo.T_Protein_Collections INNER JOIN
                      dbo.T_Collection_Organism_Xref ON 
                      dbo.T_Protein_Collections.Protein_Collection_ID = dbo.T_Collection_Organism_Xref.Protein_Collection_ID INNER JOIN
                      dbo.V_Organism_Picker ON dbo.T_Collection_Organism_Xref.Organism_ID = dbo.V_Organism_Picker.ID INNER JOIN
                      dbo.T_Protein_Collection_Types ON dbo.T_Protein_Collections.Collection_Type_ID = dbo.T_Protein_Collection_Types.Collection_Type_ID INNER JOIN
                      dbo.V_Annotation_Type_Picker ON dbo.T_Protein_Collections.Primary_Annotation_Type_ID = dbo.V_Annotation_Type_Picker.ID INNER JOIN
                      dbo.T_Naming_Authorities ON dbo.V_Annotation_Type_Picker.Authority_ID = dbo.T_Naming_Authorities.Authority_ID
WHERE     (dbo.T_Protein_Collections.Collection_State_ID BETWEEN 1 AND 3)

GO

/****** Object:  View [dbo].[V_Web_Protein_Name_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Web_Protein_Name_Info
AS
SELECT     TOP (100) PERCENT dbo.V_Protein_Names.Name, dbo.V_Protein_Names.Description, CASE WHEN LEN(dbo.T_Naming_Authorities.Description) 
                      > 0 THEN dbo.T_Naming_Authorities.Description ELSE dbo.T_Naming_Authorities.Name END AS [Naming Authority], 
                      dbo.T_Annotation_Types.TypeName AS [Name Type], dbo.T_Naming_Authorities.Web_Address AS AuthorityURL, dbo.V_Protein_Names.Reference_ID, 
                      dbo.V_Protein_Names.Protein_ID
FROM         dbo.V_Protein_Names INNER JOIN
                      dbo.T_Annotation_Types ON dbo.V_Protein_Names.Annotation_Type_ID = dbo.T_Annotation_Types.Annotation_Type_ID INNER JOIN
                      dbo.T_Naming_Authorities ON dbo.T_Annotation_Types.Authority_ID = dbo.T_Naming_Authorities.Authority_ID

GO

/****** Object:  View [dbo].[V_Protein_Names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Protein_Names
AS
SELECT     TOP (100) PERCENT dbo.T_Protein_Descriptions.Reference_ID, dbo.T_Protein_Names_Revised.Name, dbo.T_Protein_Descriptions.Description_ID, 
                      dbo.T_Protein_Descriptions.Description, dbo.T_Protein_Names_Revised.Annotation_Type_ID, dbo.T_Protein_Names_Revised.DateAdded, 
                      dbo.T_Protein_Names_Revised.Protein_ID
FROM         dbo.T_Protein_Descriptions INNER JOIN
                      dbo.T_Protein_Names_Revised ON dbo.T_Protein_Descriptions.Reference_ID = dbo.T_Protein_Names_Revised.Reference_ID
ORDER BY dbo.T_Protein_Descriptions.Reference_ID

GO

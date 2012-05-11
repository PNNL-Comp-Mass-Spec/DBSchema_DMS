/****** Object:  View [dbo].[V_Alternate_Name_Xref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Alternate_Name_Xref
AS
SELECT     dbo.T_Protein_Names.Protein_ID, dbo.T_Protein_Names.Name AS Alternate_Name, dbo.T_Protein_Names.Annotation_Type_ID, 
                      dbo.T_Protein_Collection_Members.Protein_Collection_ID
FROM         dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Protein_Names.Protein_ID

GO

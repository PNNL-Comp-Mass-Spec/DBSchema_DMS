/****** Object:  View [dbo].[V_Protein_Names_Not_Primary_Authority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Names_Not_Primary_Authority
AS
SELECT     dbo.T_Protein_Collection_Members.Protein_ID, dbo.T_Protein_Collections.Protein_Collection_ID, dbo.T_Protein_Names.Name
FROM         dbo.T_Protein_Collections INNER JOIN
                      dbo.T_Protein_Collection_Members ON 
                      dbo.T_Protein_Collections.Protein_Collection_ID = dbo.T_Protein_Collection_Members.Protein_Collection_ID INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Protein_Names.Protein_ID AND 
                      dbo.T_Protein_Collections.Primary_Annotation_Type_ID <> dbo.T_Protein_Names.Annotation_Type_ID

GO

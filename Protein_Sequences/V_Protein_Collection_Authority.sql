/****** Object:  View [dbo].[V_Protein_Collection_Authority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW dbo.V_Protein_Collection_Authority
AS
SELECT     dbo.T_Protein_Collection_Members.Protein_Collection_ID, dbo.T_Protein_Names.Annotation_Type_ID
FROM         dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Protein_Names.Protein_ID
GROUP BY dbo.T_Protein_Collection_Members.Protein_Collection_ID, dbo.T_Protein_Names.Annotation_Type_ID


GO

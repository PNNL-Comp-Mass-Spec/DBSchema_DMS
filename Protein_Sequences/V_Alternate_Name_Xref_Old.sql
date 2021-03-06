/****** Object:  View [dbo].[V_Alternate_Name_Xref_Old] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Alternate_Name_Xref_Old
AS
SELECT     dbo.T_Protein_Collection_Members.Protein_ID, dbo.T_Protein_Names.Name AS Alternate_Name, 
                      dbo.V_Protein_Names_Primary_Authority.Name AS Primary_Name, dbo.T_Protein_Names.Annotation_Type_ID, 
                      dbo.T_Protein_Collections.Protein_Collection_ID
FROM         dbo.T_Protein_Collections INNER JOIN
                      dbo.T_Protein_Collection_Members ON 
                      dbo.T_Protein_Collections.Protein_Collection_ID = dbo.T_Protein_Collection_Members.Protein_Collection_ID INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Protein_Names.Protein_ID AND 
                      dbo.T_Protein_Collections.Primary_Annotation_Type_ID <> dbo.T_Protein_Names.Annotation_Type_ID INNER JOIN
                      dbo.V_Protein_Names_Primary_Authority ON dbo.T_Protein_Names.Protein_ID = dbo.V_Protein_Names_Primary_Authority.Protein_ID AND 
                      dbo.T_Protein_Collections.Primary_Annotation_Type_ID = dbo.V_Protein_Names_Primary_Authority.Annotation_Type_ID

GO

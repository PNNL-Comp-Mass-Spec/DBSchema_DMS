/****** Object:  View [dbo].[V_Collection_Member_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Collection_Member_List_Report
AS
SELECT     dbo.T_Proteins.Protein_ID, dbo.T_Protein_Names.Name, dbo.T_Protein_Names.Description, dbo.T_Proteins.Sequence, dbo.T_Proteins.Length, 
                      dbo.T_Proteins.Molecular_Formula AS [Molecular formula], dbo.T_Proteins.Monoisotopic_Mass AS [Monoisotopic mass], 
                      dbo.T_Proteins.Average_Mass AS [Average mass], dbo.V_Annotation_Type_Picker.Display_Name AS [Annotation type], 
                      dbo.T_Protein_Collection_Members.Protein_Collection_ID
FROM         dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Proteins ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Proteins.Protein_ID INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Original_Reference_ID = dbo.T_Protein_Names.Reference_ID INNER JOIN
                      dbo.V_Annotation_Type_Picker ON dbo.T_Protein_Names.Annotation_Type_ID = dbo.V_Annotation_Type_Picker.ID

GO

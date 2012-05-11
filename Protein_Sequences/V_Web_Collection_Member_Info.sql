/****** Object:  View [dbo].[V_Web_Collection_Member_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Web_Collection_Member_Info
AS
SELECT     dbo.T_Protein_Names_Revised.Name, CASE WHEN LEN(dbo.T_Protein_Descriptions.Description) 
                      > 100 THEN SUBSTRING(dbo.T_Protein_Descriptions.Description, 1, 50) + '...' + SUBSTRING(dbo.T_Protein_Descriptions.Description, 
                      LEN(dbo.T_Protein_Descriptions.Description) - 50, 50) ELSE dbo.T_Protein_Descriptions.Description END AS Description, dbo.T_Proteins.Length, 
                      ROUND(dbo.T_Proteins.Monoisotopic_Mass, 0) AS [Monoisotopic mass], dbo.T_Proteins.Protein_ID, 
                      dbo.T_Protein_Collection_Members.Protein_Collection_ID
FROM         dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Proteins ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Proteins.Protein_ID INNER JOIN
                      dbo.T_Protein_Names_Revised ON 
                      dbo.T_Protein_Collection_Members.Original_Reference_ID = dbo.T_Protein_Names_Revised.Reference_ID INNER JOIN
                      dbo.T_Protein_Descriptions ON dbo.T_Protein_Collection_Members.Original_Description_ID = dbo.T_Protein_Descriptions.Description_ID

GO

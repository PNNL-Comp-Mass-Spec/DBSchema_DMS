/****** Object:  View [dbo].[V_Protein_Export_Web] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Export_Web
AS
SELECT     dbo.T_Protein_Names.Protein_ID, dbo.T_Protein_Names.Reference_ID, dbo.T_Protein_Names.Name, ISNULL(dbo.T_Protein_Descriptions.Description, 
                      dbo.T_Protein_Names.Description) AS description, dbo.T_Proteins.Sequence, dbo.T_Proteins.Length
FROM         dbo.T_Proteins INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Proteins.Protein_ID = dbo.T_Protein_Names.Protein_ID LEFT OUTER JOIN
                      dbo.T_Protein_Descriptions ON dbo.T_Protein_Names.Reference_ID = dbo.T_Protein_Descriptions.Reference_ID

GO

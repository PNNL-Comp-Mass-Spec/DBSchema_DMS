/****** Object:  View [dbo].[V_Protein_Names_by_Protein_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Names_by_Protein_ID
AS
SELECT     dbo.T_Proteins.Protein_ID AS protein_id, dbo.T_Protein_Names.Reference_ID AS reference_id, dbo.T_Protein_Names.Name AS name, 
                      ISNULL(dbo.T_Protein_Descriptions.Description, dbo.T_Protein_Names.Description) AS description, 
                      dbo.T_Protein_Names.DateAdded AS creation_date, dbo.T_Protein_Names.Reference_Fingerprint AS name_hash
FROM         dbo.T_Protein_Names INNER JOIN
                      dbo.T_Proteins ON dbo.T_Protein_Names.Protein_ID = dbo.T_Proteins.Protein_ID LEFT OUTER JOIN
                      dbo.T_Protein_Descriptions ON dbo.T_Protein_Names.Reference_ID = dbo.T_Protein_Descriptions.Reference_ID

GO

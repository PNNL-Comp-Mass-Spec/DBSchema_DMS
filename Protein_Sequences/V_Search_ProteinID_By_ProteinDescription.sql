/****** Object:  View [dbo].[V_Search_ProteinID_By_ProteinDescription] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Search_ProteinID_By_ProteinDescription
AS
SELECT     Protein_ID, Description AS Name, 'proteinIDByProteinDescription' AS Value_type
FROM         dbo.T_Protein_Names

GO

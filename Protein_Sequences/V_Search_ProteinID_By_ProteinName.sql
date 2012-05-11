/****** Object:  View [dbo].[V_Search_ProteinID_By_ProteinName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Search_ProteinID_By_ProteinName
AS
SELECT     Protein_ID, Name, 'proteinIDByProteinName' AS Value_type
FROM         dbo.T_Protein_Names

GO

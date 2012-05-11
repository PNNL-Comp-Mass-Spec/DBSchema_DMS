/****** Object:  View [dbo].[V_Search_ProteinID_By_Sequence] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Search_ProteinID_By_Sequence
AS
SELECT     Protein_ID, Sequence AS Name, 'proteinIDBySequence' AS Value_type
FROM         dbo.T_Proteins

GO

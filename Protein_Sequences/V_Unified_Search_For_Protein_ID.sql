/****** Object:  View [dbo].[V_Unified_Search_For_Protein_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Unified_Search_For_Protein_ID
AS
SELECT     Name, Protein_ID, Value_type
FROM         dbo.V_Search_ProteinID_By_ProteinName

GO

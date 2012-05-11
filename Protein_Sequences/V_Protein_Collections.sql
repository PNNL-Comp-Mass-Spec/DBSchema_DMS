/****** Object:  View [dbo].[V_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Collections
AS
SELECT DISTINCT 
                      TOP 100 PERCENT Protein_Collection_ID, FileName + ' (' + CAST(NumProteins AS varchar) + ' Entries)' AS Display, FileName, 
                      Primary_Annotation_Type_ID, Description, Contents_Encrypted, Collection_Type_ID, Collection_State_ID
FROM         dbo.T_Protein_Collections
ORDER BY FileName + ' (' + CAST(NumProteins AS varchar) + ' Entries)'

GO

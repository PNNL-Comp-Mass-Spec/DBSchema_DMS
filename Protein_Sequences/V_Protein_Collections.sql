/****** Object:  View [dbo].[V_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collections]
AS
SELECT DISTINCT Protein_Collection_ID,
                Collection_Name + ' (' + CAST(NumProteins AS varchar) + ' Entries)' AS Display,
                Collection_Name,
                Primary_Annotation_Type_ID,
                Description,
                Contents_Encrypted,
                Collection_Type_ID,
                Collection_State_ID
FROM dbo.T_Protein_Collections

GO

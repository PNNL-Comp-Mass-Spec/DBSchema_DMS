/****** Object:  View [dbo].[V_Protein_Database_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Protein_Database_Export]
AS
SELECT Protein_ID,
       Name,
       LEFT(Description, 500) AS Description,
       Sequence,
       Protein_Collection_ID,
       Annotation_Type_ID,
       Primary_Annotation_Type_ID,
       SHA1_Hash,
       Sorting_Index
FROM dbo.V_Protein_Storage_Entry_Import


GO
GRANT SELECT ON [dbo].[V_Protein_Database_Export] TO [pnl\d3l243] AS [dbo]
GO

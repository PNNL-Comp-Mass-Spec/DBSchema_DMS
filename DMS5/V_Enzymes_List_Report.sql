/****** Object:  View [dbo].[V_Enzymes_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Enzymes_List_Report]
AS
SELECT enzyme_id,
       enzyme_name,
       description,
       P1 AS left_cleave_residues,
       P1_Exception AS left_exception,
       P2 AS right_cleave_residues,
       P2_Exception AS right_exception,
       Cleavage_Method AS cleavage_method,
       CASE
           WHEN Cleavage_Offset = 0 THEN 'Cleave Before'
           ELSE 'Cleave After'
       END AS cleavage_offset,
       Protein_Collection_Name AS protein_collection,
       comment
FROM dbo.T_Enzymes


GO

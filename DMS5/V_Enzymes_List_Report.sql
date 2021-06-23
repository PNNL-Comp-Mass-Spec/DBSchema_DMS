/****** Object:  View [dbo].[V_Enzymes_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Enzymes_List_Report]
AS
SELECT Enzyme_ID,
       Enzyme_Name,
       Description,
       P1 AS [Left Cleave Residues],
       P1_Exception AS [Left Exception],
       P2 AS [Right Cleave Residues],
       P2_Exception AS [Right Exception],
       Cleavage_Method AS [Cleavage Method],
       CASE
           WHEN Cleavage_Offset = 0 THEN 'Cleave Before'
           ELSE 'Cleave After'
       END AS [Cleavage Offset],
       Protein_Collection_Name AS [Protein Collection],
       [Comment]
FROM dbo.T_Enzymes


GO

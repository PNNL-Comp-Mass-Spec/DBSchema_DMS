/****** Object:  View [dbo].[V_Enzyme_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Enzyme_Export]
AS
SELECT Enzyme_ID,
       Enzyme_Name,
       Description,
       P1,
       P1_Exception,
       P2,
       P2_Exception,
       Cleavage_Method,
       Cleavage_Offset,
       Sequest_Enzyme_Index,
       Protein_Collection_Name
FROM T_Enzymes


GO
GRANT VIEW DEFINITION ON [dbo].[V_Enzyme_Export] TO [DDL_Viewer] AS [dbo]
GO

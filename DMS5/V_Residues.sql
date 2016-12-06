/****** Object:  View [dbo].[V_Residues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Residues]
AS
SELECT Residue_ID,
       Residue_Symbol,
       Description,
       Average_Mass,
       Monoisotopic_Mass,
       Empirical_Formula,
       Num_C,
       Num_H,
       Num_N,
       Num_O,
       Num_S
FROM dbo.T_Residues


GO
GRANT VIEW DEFINITION ON [dbo].[V_Residues] TO [DDL_Viewer] AS [dbo]
GO

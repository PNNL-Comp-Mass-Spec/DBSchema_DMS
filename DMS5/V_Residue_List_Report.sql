/****** Object:  View [dbo].[V_Residue_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Residue_List_Report]
AS
SELECT residue_id,
       residue_symbol as symbol,
       description as abbreviation,
       amino_acid_name as amino_acid,
       monoisotopic_mass,
       average_mass,
       empirical_formula,
       num_c,
       num_h,
       num_n,
       num_o,
       num_s
FROM dbo.t_residues


GO
GRANT VIEW DEFINITION ON [dbo].[V_Residue_List_Report] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Ext_PGDump_Organisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Organisms
AS
SELECT     O.Organism_ID AS id, O.OG_name AS name, CASE WHEN OG_genus IS NOT NULL THEN COALESCE (OG_Genus, '') + ' ' + COALESCE (OG_Species, '') 
                      + ' ' + COALESCE (OG_Strain, '') ELSE [OG_name] END AS full_name, D.Dataset_ID AS ds_id
FROM         dbo.T_Organisms AS O INNER JOIN
                      dbo.T_Experiments AS E ON E.EX_organism_ID = O.Organism_ID INNER JOIN
                      dbo.T_Dataset AS D ON D.Exp_ID = E.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Organisms] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Organisms] TO [PNL\D3M580] AS [dbo]
GO

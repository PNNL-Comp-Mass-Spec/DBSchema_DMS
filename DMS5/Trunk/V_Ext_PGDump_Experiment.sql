/****** Object:  View [dbo].[V_Ext_PGDump_Experiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Experiment
AS
SELECT     E.Exp_ID AS id, E.Experiment_Num AS experiment_name, E.EX_created AS created, O.OG_name AS organism_name, E.EX_reason AS reason, 
                      E.EX_cell_culture_list AS biomaterial_list, E.EX_campaign_ID AS campaign_id, D.Dataset_ID AS ds_id
FROM         dbo.T_Dataset AS D INNER JOIN
                      dbo.T_Experiments AS E ON D.Exp_ID = E.Exp_ID INNER JOIN
                      dbo.T_Organisms AS O ON E.EX_organism_ID = O.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Experiment] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Experiment] TO [PNL\D3M580] AS [dbo]
GO

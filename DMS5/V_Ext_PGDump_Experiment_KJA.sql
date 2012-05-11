/****** Object:  View [dbo].[V_Ext_PGDump_Experiment_KJA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Experiment_KJA
AS
SELECT     dbo.T_Experiments.Exp_ID AS id, dbo.T_Experiments.Experiment_Num AS experiment_name, dbo.T_Experiments.EX_created AS created, 
                      dbo.T_Organisms.OG_name AS organism_name, dbo.T_Experiments.EX_reason AS reason, 
                      dbo.T_Experiments.EX_cell_culture_list AS biomaterial_list, dbo.T_Experiments.EX_campaign_ID AS campaign_id
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.EX_organism_ID = dbo.T_Organisms.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Experiment_KJA] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Experiment_KJA] TO [PNL\D3M580] AS [dbo]
GO

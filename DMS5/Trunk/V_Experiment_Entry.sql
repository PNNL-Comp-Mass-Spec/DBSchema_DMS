/****** Object:  View [dbo].[V_Experiment_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_Entry
AS
SELECT     dbo.T_Experiments.Experiment_Num, dbo.T_Campaign.Campaign_Num AS EX_Campaign_Num, dbo.T_Experiments.EX_researcher_PRN, 
                      dbo.T_Organisms.OG_name AS EX_organism_name, dbo.T_Experiments.EX_reason, dbo.T_Experiments.EX_sample_concentration, 
                      dbo.T_Enzymes.Enzyme_Name, dbo.T_Experiments.EX_lab_notebook_ref, dbo.T_Experiments.EX_comment, 
                      dbo.GetExpCellCultureList(dbo.T_Experiments.Experiment_Num) AS EX_cell_culture_list, dbo.T_Experiments.EX_Labelling, 
                      dbo.T_Experiments.EX_sample_prep_request_ID AS samplePrepRequest, dbo.T_Internal_Standards.Name AS internalStandard, 
                      T_Internal_Standards_1.Name AS postdigestIntStd
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Enzymes ON dbo.T_Experiments.EX_enzyme_ID = dbo.T_Enzymes.Enzyme_ID INNER JOIN
                      dbo.T_Internal_Standards ON dbo.T_Experiments.EX_internal_standard_ID = dbo.T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Internal_Standards T_Internal_Standards_1 ON 
                      dbo.T_Experiments.EX_postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID

GO

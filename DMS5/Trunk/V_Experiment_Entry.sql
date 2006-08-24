/****** Object:  View [dbo].[V_Experiment_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Experiment_Entry
AS
SELECT     T_Experiments.Experiment_Num, T_Campaign.Campaign_Num AS EX_Campaign_Num, T_Experiments.EX_researcher_PRN, 
                      T_Experiments.EX_organism_name, T_Experiments.EX_reason, T_Experiments.EX_sample_concentration, T_Enzymes.Enzyme_Name, 
                      T_Experiments.EX_lab_notebook_ref, T_Experiments.EX_comment, dbo.GetExpCellCultureList(T_Experiments.Experiment_Num) 
                      AS EX_cell_culture_list, T_Experiments.EX_Labelling, T_Experiments.EX_sample_prep_request_ID AS samplePrepRequest, 
                      T_Internal_Standards.Name AS internalStandard, T_Internal_Standards_1.Name AS postdigestIntStd
FROM         T_Experiments INNER JOIN
                      T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID INNER JOIN
                      T_Enzymes ON T_Experiments.EX_enzyme_ID = T_Enzymes.Enzyme_ID INNER JOIN
                      T_Internal_Standards ON T_Experiments.EX_internal_standard_ID = T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      T_Internal_Standards T_Internal_Standards_1 ON T_Experiments.EX_postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID

GO

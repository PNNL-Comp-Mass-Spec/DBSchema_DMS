/****** Object:  View [dbo].[V_Experiment_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Experiment_Entry as 
SELECT        T_Experiments.Experiment_Num AS experimentNum, T_Campaign.Campaign_Num AS campaignNum, T_Experiments.EX_researcher_PRN AS researcherPRN, 
                         T_Organisms.OG_name AS organismName, T_Experiments.EX_reason AS reason, T_Experiments.EX_sample_concentration AS sampleConcentration, 
                         T_Enzymes.Enzyme_Name AS enzymeName, T_Experiments.EX_lab_notebook_ref AS labNotebookRef, T_Experiments.EX_comment AS comment, 
                         dbo.GetExpCellCultureList(T_Experiments.Experiment_Num) AS cellCultureList, T_Experiments.EX_Labelling AS labelling, 
                         T_Experiments.EX_sample_prep_request_ID AS samplePrepRequest, T_Internal_Standards.Name AS internalStandard, 
                         T_Internal_Standards_1.Name AS postdigestIntStd, T_Material_Containers.Tag AS container, T_Experiments.EX_wellplate_num AS wellplateNum, 
                         T_Experiments.EX_well_num AS wellNum, T_Experiments.EX_Alkylation AS alkylation
FROM            T_Experiments INNER JOIN
                         T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID INNER JOIN
                         T_Enzymes ON T_Experiments.EX_enzyme_ID = T_Enzymes.Enzyme_ID INNER JOIN
                         T_Internal_Standards ON T_Experiments.EX_internal_standard_ID = T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                         T_Internal_Standards AS T_Internal_Standards_1 ON T_Experiments.EX_postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID INNER JOIN
                         T_Organisms ON T_Experiments.EX_organism_ID = T_Organisms.Organism_ID INNER JOIN
                         T_Material_Containers ON T_Experiments.EX_Container_ID = T_Material_Containers.ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Entry] TO [PNL\D3M580] AS [dbo]
GO

/****** Object:  View [dbo].[V_Experiment_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Experiment_Entry] as 
SELECT E.Experiment_Num AS experimentNum,
       C.Campaign_Num AS campaignNum,
       E.EX_researcher_PRN AS researcherPRN,
       Org.OG_name AS organismName,
       E.EX_reason AS reason,
       E.EX_sample_concentration AS sampleConcentration,
       Enz.Enzyme_Name AS enzymeName,
       E.EX_lab_notebook_ref AS labNotebookRef,
       E.EX_comment AS [comment],
       dbo.GetExpCellCultureList(E.Experiment_Num) AS cellCultureList,
       E.EX_Labelling AS labelling,
       E.EX_sample_prep_request_ID AS samplePrepRequest,
       InstStd.Name AS internalStandard,
       PostDigestIntStd.Name AS postdigestIntStd,
       MC.Tag AS container,
       E.EX_wellplate_num AS wellplateNum,
       E.EX_well_num AS wellNum,
       E.EX_Alkylation AS alkylation,
       BTO.Tissue AS tissue,
       E.EX_Barcode As barcode
FROM T_Experiments E
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Enzymes Enz
       ON E.EX_enzyme_ID = Enz.Enzyme_ID
     INNER JOIN T_Internal_Standards InstStd
       ON E.EX_internal_standard_ID = InstStd.Internal_Std_Mix_ID
     INNER JOIN T_Internal_Standards PostDigestIntStd
       ON E.EX_postdigest_internal_std_ID = PostDigestIntStd.Internal_Std_Mix_ID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN T_Material_Containers MC
       ON E.EX_Container_ID = MC.ID
	LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
	  ON E.EX_Tissue_ID = BTO.Identifier

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Entry] TO [DDL_Viewer] AS [dbo]
GO

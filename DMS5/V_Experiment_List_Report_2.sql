/****** Object:  View [dbo].[V_Experiment_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_List_Report_2]
AS
SELECT E.Exp_ID AS id,
       E.Experiment_Num AS experiment,
       U.Name_with_PRN AS researcher,
       dbo.T_Organisms.OG_name AS organism,
       E.EX_reason AS reason,
       E.EX_comment AS comment,
       E.EX_sample_concentration AS concentration,
       E.EX_created AS created,
       C.Campaign_Num AS campaign,
       BTO.tissue,
       CEC.Cell_Culture_List AS biomaterial_list,
       CEC.Reference_Compound_List AS ref_compounds,
       Enz.Enzyme_Name AS enzyme,
       E.EX_lab_notebook_ref AS notebook,
       E.EX_Labelling AS labelling,
       IntStd1.Name AS predigest,
       IntStd2.Name AS postdigest,
       E.EX_sample_prep_request_ID AS request,
       MC.Tag AS container,
       ML.Tag AS location,
       E.EX_wellplate_num AS wellplate,
       E.EX_well_num AS well,
       E.EX_Alkylation AS alkylated
FROM T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Users U
       ON E.EX_researcher_PRN = U.U_PRN
     INNER JOIN dbo.T_Enzymes Enz
       ON E.EX_enzyme_ID = Enz.Enzyme_ID
     INNER JOIN dbo.T_Internal_Standards IntStd1
       ON E.EX_internal_standard_ID = IntStd1.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Internal_Standards AS IntStd2
       ON E.EX_postdigest_internal_std_ID = IntStd2.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Organisms
       ON E.EX_organism_ID = dbo.T_Organisms.Organism_ID
     INNER JOIN dbo.T_Material_Containers MC
       ON E.EX_Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
	  ON E.EX_Tissue_ID = BTO.Identifier
     LEFT OUTER JOIN T_Cached_Experiment_Components CEC
       ON E.Exp_ID = CEC.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO

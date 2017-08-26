/****** Object:  View [dbo].[V_Experiment_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_List_Report_2]
AS
SELECT E.Exp_ID AS ID,
       E.Experiment_Num AS Experiment,
       U.Name_with_PRN AS Researcher,
       dbo.T_Organisms.OG_name AS Organism,
       E.EX_reason AS Reason,
       E.EX_comment AS [Comment],
       E.EX_sample_concentration AS Concentration,
       E.EX_created AS Created,
       C.Campaign_Num AS Campaign,
       BTO.Tissue,
       E.EX_cell_culture_list AS [Cell Cultures],
       Enz.Enzyme_Name AS Enzyme,
       E.EX_lab_notebook_ref AS Notebook,
       E.EX_Labelling AS Labelling,
       IntStd1.Name AS Predigest,
       IntStd2.Name AS Postdigest,
       E.EX_sample_prep_request_ID AS Request,
       MC.Tag AS Container,
       ML.Tag AS Location,
       E.EX_wellplate_num AS Wellplate,
       E.EX_well_num AS Well,
       E.EX_Alkylation AS Alkylated
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



GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO

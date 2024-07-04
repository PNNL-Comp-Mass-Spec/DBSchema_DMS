/****** Object:  View [dbo].[V_Experiment_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Experiment_Metadata]
AS
SELECT E.Experiment_Num AS Name,
       E.Exp_ID AS ID,
       U.Name_with_PRN AS Researcher,
       Org.OG_name AS Organism,
       E.EX_reason AS Reason_for_Experiment,
       E.EX_comment AS [Comment],
       E.EX_created AS Created,
       E.EX_sample_concentration AS Sample_Concentration,
       Enz.Enzyme_Name AS Digestion_Enzyme,
       E.EX_lab_notebook_ref AS Lab_Notebook,
       C.Campaign_Num AS Campaign,
       CEC.Cell_Culture_List AS Cell_Cultures,
       CEC.Reference_Compound_List AS Ref_Compounds,
       E.EX_Labelling AS Labelling,
       IntStd1.Name AS Predigest_Int_Std,
       IntStd2.Name AS Postdigest_Int_Std,
       E.EX_sample_prep_request_ID AS Request
FROM T_Experiments E
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Users U
       ON E.EX_researcher_PRN = U.U_PRN
     INNER JOIN T_Enzymes Enz
       ON E.EX_enzyme_ID = Enz.Enzyme_ID
     INNER JOIN T_Internal_Standards IntStd1
       ON E.EX_internal_standard_ID = IntStd1.Internal_Std_Mix_ID
     INNER JOIN T_Internal_Standards IntStd2
       ON E.EX_postdigest_internal_std_ID = IntStd2.Internal_Std_Mix_ID
     INNER JOIN T_Organisms Org
       ON E.Ex_organism_ID = Org.Organism_ID
     LEFT OUTER JOIN T_Cached_Experiment_Components CEC
       ON E.Exp_ID = CEC.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Metadata] TO [DDL_Viewer] AS [dbo]
GO

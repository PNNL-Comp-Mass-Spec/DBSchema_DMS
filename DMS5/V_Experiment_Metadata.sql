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
       E.EX_reason AS [Reason for Experiment],
       E.EX_comment AS [Comment],
       E.EX_created AS Created,
       E.EX_sample_concentration AS [Sample Concentration],
       Enz.Enzyme_Name AS [Digestion Enzyme],
       E.EX_lab_notebook_ref AS [Lab Notebook],
       C.Campaign_Num AS Campaign,
       E.EX_cell_culture_list AS [Cell Cultures],
       E.EX_Labelling AS Labelling,
       IntStd1.Name AS [Predigest Int Std],
       IntStd2.Name AS [Postdigest Int Std],
       E.EX_sample_prep_request_ID AS Request
FROM dbo.T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Users U
       ON E.EX_researcher_PRN = U.U_PRN
     INNER JOIN dbo.T_Enzymes Enz
       ON E.EX_enzyme_ID = Enz.Enzyme_ID
     INNER JOIN dbo.T_Internal_Standards IntStd1
       ON E.EX_internal_standard_ID = IntStd1.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Internal_Standards IntStd2
       ON E.EX_postdigest_internal_std_ID = IntStd2.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.Ex_organism_ID = Org.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Metadata] TO [PNL\D3M578] AS [dbo]
GO

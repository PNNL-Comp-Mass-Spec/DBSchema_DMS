/****** Object:  View [dbo].[V_Experiment_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Experiment_Detail_Report_Ex
AS
SELECT     T_Experiments.Experiment_Num AS Experiment, T_Users.U_Name + ' (' + T_Experiments.EX_researcher_PRN + ')' AS Researcher, 
                      T_Experiments.EX_organism_name AS Organism, T_Experiments.EX_reason AS [Reason for Experiment], T_Experiments.EX_comment AS Comment, 
                      T_Experiments.EX_created AS Created, T_Experiments.EX_sample_concentration AS [Sample Concentration], 
                      T_Enzymes.Enzyme_Name AS [Digestion Enzyme], T_Experiments.EX_lab_notebook_ref AS [Lab Notebook], 
                      T_Campaign.Campaign_Num AS Campaign, T_Experiments.Exp_ID AS ID, T_Experiments.EX_cell_culture_list AS [Cell Cultures], 
                      T_Experiments.EX_Labelling AS Labelling, T_Internal_Standards.Name AS [Predigest Int Std], T_Internal_Standards_1.Name AS [Postdigest Int Std], 
                      M.Group_ID AS [Fraction Group], A.Datasets, T_Experiments.EX_sample_prep_request_ID AS Request
FROM         T_Experiments INNER JOIN
                      T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID INNER JOIN
                      T_Users ON T_Experiments.EX_researcher_PRN = T_Users.U_PRN INNER JOIN
                      T_Enzymes ON T_Experiments.EX_enzyme_ID = T_Enzymes.Enzyme_ID INNER JOIN
                      T_Internal_Standards ON T_Experiments.EX_internal_standard_ID = T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      T_Internal_Standards T_Internal_Standards_1 ON 
                      T_Experiments.EX_postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID LEFT OUTER JOIN
                          (SELECT     T_Experiment_Group_Members.Exp_ID, T_Experiment_Group_Members.Group_ID
                            FROM          T_Experiment_Group_Members INNER JOIN
                                                   T_Experiment_Groups ON T_Experiment_Group_Members.Group_ID = T_Experiment_Groups.Group_ID
                            WHERE      (T_Experiment_Groups.EG_Group_Type = 'Fraction')) M ON M.Exp_ID = T_Experiments.Exp_ID LEFT OUTER JOIN
                          (SELECT     COUNT(*) AS Datasets, Exp_ID
                            FROM          T_Dataset
                            GROUP BY Exp_ID) A ON A.Exp_ID = T_Experiments.Exp_ID

GO

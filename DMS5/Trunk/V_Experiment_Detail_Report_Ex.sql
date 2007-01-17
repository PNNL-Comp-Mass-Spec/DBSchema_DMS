/****** Object:  View [dbo].[V_Experiment_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_Detail_Report_Ex
AS
SELECT     dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Users.U_Name + ' (' + dbo.T_Experiments.EX_researcher_PRN + ')' AS Researcher, 
                      dbo.T_Organisms.OG_name AS Organism, dbo.T_Experiments.EX_reason AS [Reason for Experiment], dbo.T_Experiments.EX_comment AS Comment, 
                      dbo.T_Experiments.EX_created AS Created, dbo.T_Experiments.EX_sample_concentration AS [Sample Concentration], 
                      dbo.T_Enzymes.Enzyme_Name AS [Digestion Enzyme], dbo.T_Experiments.EX_lab_notebook_ref AS [Lab Notebook], 
                      dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Experiments.Exp_ID AS ID, dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures], 
                      dbo.T_Experiments.EX_Labelling AS Labelling, dbo.T_Internal_Standards.Name AS [Predigest Int Std], 
                      T_Internal_Standards_1.Name AS [Postdigest Int Std], M.Group_ID AS [Fraction Group], A.Datasets, 
                      dbo.T_Experiments.EX_sample_prep_request_ID AS Request
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Experiments.EX_researcher_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Enzymes ON dbo.T_Experiments.EX_enzyme_ID = dbo.T_Enzymes.Enzyme_ID INNER JOIN
                      dbo.T_Internal_Standards ON dbo.T_Experiments.EX_internal_standard_ID = dbo.T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Internal_Standards T_Internal_Standards_1 ON 
                      dbo.T_Experiments.EX_postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID LEFT OUTER JOIN
                          (SELECT     T_Experiment_Group_Members.Exp_ID, T_Experiment_Group_Members.Group_ID
                            FROM          T_Experiment_Group_Members INNER JOIN
                                                   T_Experiment_Groups ON T_Experiment_Group_Members.Group_ID = T_Experiment_Groups.Group_ID
                            WHERE      (T_Experiment_Groups.EG_Group_Type = 'Fraction')) M ON M.Exp_ID = dbo.T_Experiments.Exp_ID LEFT OUTER JOIN
                          (SELECT     COUNT(*) AS Datasets, Exp_ID
                            FROM          T_Dataset
                            GROUP BY Exp_ID) A ON A.Exp_ID = dbo.T_Experiments.Exp_ID

GO

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
                      dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures], 
                      dbo.T_Experiments.EX_Labelling AS Labelling, dbo.T_Internal_Standards.Name AS [Predigest Int Std], 
                      T_Internal_Standards_1.Name AS [Postdigest Int Std], dbo.T_Experiments.EX_sample_prep_request_ID AS Request, 
                      m.Group_ID AS [Experiment Group], a.DataSets, dbo.T_Experiments.Exp_ID AS ID, dbo.T_Material_Containers.Tag AS Container, 
                      dbo.T_Material_Locations.Tag AS Location, dbo.T_Experiments.Ex_Material_Active AS [Material Status]
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Experiments.EX_researcher_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Enzymes ON dbo.T_Experiments.EX_enzyme_ID = dbo.T_Enzymes.Enzyme_ID INNER JOIN
                      dbo.T_Internal_Standards ON dbo.T_Experiments.EX_internal_standard_ID = dbo.T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Internal_Standards AS T_Internal_Standards_1 ON 
                      dbo.T_Experiments.EX_postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.EX_organism_ID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.T_Material_Containers ON dbo.T_Experiments.EX_Container_ID = dbo.T_Material_Containers.ID INNER JOIN
                      dbo.T_Material_Locations ON dbo.T_Material_Containers.Location_ID = dbo.T_Material_Locations.ID LEFT OUTER JOIN
                          (SELECT     dbo.T_Experiment_Group_Members.Exp_ID, dbo.T_Experiment_Group_Members.Group_ID
                            FROM          dbo.T_Experiment_Group_Members INNER JOIN
                                                   dbo.T_Experiment_Groups ON dbo.T_Experiment_Group_Members.Group_ID = dbo.T_Experiment_Groups.Group_ID) AS m ON 
                      m.Exp_ID = dbo.T_Experiments.Exp_ID LEFT OUTER JOIN
                          (SELECT     COUNT(*) AS DataSets, Exp_ID
                            FROM          dbo.T_Dataset
                            GROUP BY Exp_ID) AS a ON a.Exp_ID = dbo.T_Experiments.Exp_ID

GO

/****** Object:  View [dbo].[V_Experiment_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_List_Report_2
AS
SELECT     dbo.T_Experiments.Exp_ID AS ID, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Users.U_Name + ' (' + dbo.T_Experiments.EX_researcher_PRN + ')' AS Researcher, dbo.T_Organisms.OG_name AS Organism, 
                      dbo.T_Experiments.EX_reason AS Reason, dbo.T_Experiments.EX_comment AS Comment, 
                      dbo.T_Experiments.EX_sample_concentration AS Concentration, dbo.T_Experiments.EX_created AS Created, 
                      dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures], 
                      dbo.T_Enzymes.Enzyme_Name AS Enzyme, dbo.T_Experiments.EX_lab_notebook_ref AS Notebook, dbo.T_Experiments.EX_Labelling AS Labelling, 
                      dbo.T_Internal_Standards.Name AS Predigest, T_Internal_Standards_1.Name AS Postdigest, 
                      dbo.T_Experiments.EX_sample_prep_request_ID AS Request, dbo.T_Material_Containers.Tag AS Container, 
                      dbo.T_Material_Locations.Tag AS Location, dbo.T_Experiments.EX_wellplate_num AS Wellplate, dbo.T_Experiments.EX_well_num AS Well
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Experiments.EX_researcher_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Enzymes ON dbo.T_Experiments.EX_enzyme_ID = dbo.T_Enzymes.Enzyme_ID INNER JOIN
                      dbo.T_Internal_Standards ON dbo.T_Experiments.EX_internal_standard_ID = dbo.T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Internal_Standards AS T_Internal_Standards_1 ON 
                      dbo.T_Experiments.EX_postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.EX_organism_ID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.T_Material_Containers ON dbo.T_Experiments.EX_Container_ID = dbo.T_Material_Containers.ID INNER JOIN
                      dbo.T_Material_Locations ON dbo.T_Material_Containers.Location_ID = dbo.T_Material_Locations.ID

GO

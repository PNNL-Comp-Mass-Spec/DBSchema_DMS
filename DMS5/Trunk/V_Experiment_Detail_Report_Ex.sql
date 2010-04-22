/****** Object:  View [dbo].[V_Experiment_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Detail_Report_Ex]
AS
SELECT E.Experiment_Num AS Experiment,
       U.U_Name + ' (' + E.EX_researcher_PRN + ')' AS Researcher,
       Org.OG_name AS Organism,
       E.EX_reason AS [Reason for Experiment],
       E.EX_comment AS Comment,
       E.EX_created AS Created,
       E.EX_sample_concentration AS [Sample Concentration],
       Enz.Enzyme_Name AS [Digestion Enzyme],
       E.EX_lab_notebook_ref AS [Lab Notebook],
       C.Campaign_Num AS Campaign,
       E.EX_cell_culture_list AS [Cell Cultures],
       E.EX_Labelling AS Labelling,
       IntStdPre.Name AS [Predigest Int Std],
       IntStdPost.Name AS [Postdigest Int Std],
       E.EX_sample_prep_request_ID AS Request,
       ISNULL(m.Group_ID, -1) AS [Experiment Group],
       'show list' AS [Experiment Group Members],
       ISNULL(DSCountQ.DataSets, 0) AS Datasets,
       E.Exp_ID AS ID,
       MC.Tag AS Container,
       ML.Tag AS Location,
       E.Ex_Material_Active AS [Material Status],
       E.EX_wellplate_num AS [Wellplate Number],
       E.EX_well_num AS [Well Number]
FROM dbo.T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Users U
       ON E.EX_researcher_PRN = U.U_PRN
     INNER JOIN dbo.T_Enzymes Enz
       ON E.EX_enzyme_ID = Enz.Enzyme_ID
     INNER JOIN dbo.T_Internal_Standards IntStdPre
       ON E.EX_internal_standard_ID = IntStdPre.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Internal_Standards AS IntStdPost
       ON E.EX_postdigest_internal_std_ID 
          = IntStdPost.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Material_Containers MC
       ON E.EX_Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     LEFT OUTER JOIN ( SELECT EGM.Exp_ID,
                              EGM.Group_ID
                       FROM dbo.T_Experiment_Group_Members EGM
                            INNER JOIN dbo.T_Experiment_Groups EG
                              ON EGM.Group_ID 
                                 = EG.Group_ID ) AS m
       ON m.Exp_ID = E.Exp_ID
     LEFT OUTER JOIN ( SELECT COUNT(*) AS DataSets,
                              Exp_ID
                       FROM dbo.T_Dataset
                       GROUP BY Exp_ID ) AS DSCountQ
       ON DSCountQ.Exp_ID = E.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Detail_Report_Ex] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Detail_Report_Ex] TO [PNL\D3M580] AS [dbo]
GO

/****** Object:  View [dbo].[V_Experiment_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Experiment_Detail_Report_Ex as
SELECT E.Experiment_Num AS Experiment,
       U.U_Name + ' (' + E.EX_researcher_PRN + ')' AS Researcher,
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
       IntStdPre.Name AS [Predigest Int Std],
       IntStdPost.Name AS [Postdigest Int Std],
       E.EX_Alkylation AS Alkylation,
       E.EX_sample_prep_request_ID AS Request,
       dbo.GetExperimentGroupList(E.Exp_ID) AS [Experiment Groups],
       ISNULL(DSCountQ.Datasets, 0) AS Datasets,
       DSCountQ.Most_Recent_Dataset AS [Most Recent Dataset],
       ISNULL(FC.Factor_Count, 0) AS Factors,
       ISNULL(ExpFileCount.FileCount, 0) AS [Experiment Files],
       ISNULL(ExpGroupFileCount.FileCount, 0) AS [Experiment Group Files],
       E.Exp_ID AS ID,
       MC.Tag AS Container,
       ML.Tag AS Location,
       E.Ex_Material_Active AS [Material Status],
       E.EX_wellplate_num AS [Wellplate Number],
       E.EX_well_num AS [Well Number]
FROM T_Experiments AS E
     INNER JOIN T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Users AS U
       ON E.EX_researcher_PRN = U.U_PRN
     INNER JOIN T_Enzymes AS Enz
       ON E.EX_enzyme_ID = Enz.Enzyme_ID
     INNER JOIN T_Internal_Standards AS IntStdPre
       ON E.EX_internal_standard_ID = IntStdPre.Internal_Std_Mix_ID
     INNER JOIN T_Internal_Standards AS IntStdPost
       ON E.EX_postdigest_internal_std_ID = IntStdPost.Internal_Std_Mix_ID
     INNER JOIN T_Organisms AS Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN T_Material_Containers AS MC
       ON E.EX_Container_ID = MC.ID
     INNER JOIN T_Material_Locations AS ML
       ON MC.Location_ID = ML.ID
     LEFT OUTER JOIN ( SELECT COUNT(*) AS Datasets,
                              MAX(DS_created) AS Most_Recent_Dataset,
                              Exp_ID
                       FROM T_Dataset
                       GROUP BY Exp_ID ) AS DSCountQ
       ON DSCountQ.Exp_ID = E.Exp_ID
     LEFT OUTER JOIN V_Factor_Count_By_Experiment AS FC
       ON FC.Exp_ID = E.Exp_ID
     LEFT OUTER JOIN (
		SELECT Entity_ID, COUNT(*) AS FileCount
		FROM T_File_Attachment
		WHERE (Entity_Type = 'experiment')
		GROUP BY Entity_ID
     ) AS ExpFileCount ON ExpFileCount.Entity_ID = E.Experiment_Num
     LEFT OUTER JOIN (
		SELECT EGM.Exp_ID, EGM.Group_ID, FA.FileCount
FROM T_Experiment_Group_Members EGM INNER JOIN
    T_Experiment_Groups EG ON EGM.Group_ID = EG.Group_ID INNER JOIN
        (SELECT Entity_ID, COUNT(*) AS FileCount
      FROM T_File_Attachment
      WHERE (Entity_Type = 'experiment_group')
      GROUP BY Entity_ID) FA ON EG.Group_ID = CONVERT(int, FA.Entity_ID)
     ) ExpGroupFileCount ON ExpGroupFileCount.Exp_ID = E.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Detail_Report_Ex] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Detail_Report_Ex] TO [PNL\D3M580] AS [dbo]
GO

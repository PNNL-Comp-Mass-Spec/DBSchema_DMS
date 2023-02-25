/****** Object:  View [dbo].[V_Experiment_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Experiment_Detail_Report_Ex]
AS
SELECT E.Experiment_Num AS experiment,
        U.Name_with_PRN AS researcher,
        Org.OG_name AS organism,
        E.EX_reason AS reason_for_experiment,
        E.EX_comment AS comment,
        E.EX_created AS created,
        E.EX_sample_concentration AS sample_concentration,
        Enz.Enzyme_Name AS digestion_enzyme,
        E.EX_lab_notebook_ref AS lab_notebook,
        C.Campaign_Num AS campaign,
        BTO.Tissue AS plant_or_animal_tissue,
        CEC.Cell_Culture_list AS biomaterial_list,
        CEC.Reference_Compound_list AS reference_compounds,
        E.EX_Labelling AS labelling,
        IntStdPre.Name AS predigest_int_std,
        IntStdPost.Name AS postdigest_int_std,
        E.EX_Alkylation AS alkylated,
        E.EX_sample_prep_request_ID AS request,
	   BTO.Identifier AS tissue_id,
        dbo.get_experiment_group_list(E.Exp_ID) AS experiment_groups,
        ISNULL(DSCountQ.datasets, 0) AS datasets,
        DSCountQ.Most_Recent_Dataset AS most_recent_dataset,
        ISNULL(FC.factor_count, 0) AS factors,
        ISNULL(ExpFileCount.filecount, 0) AS experiment_files,
        ISNULL(ExpGroupFileCount.filecount, 0) AS experiment_group_files,
        E.Exp_ID AS id,
        MC.Tag AS container,
        ML.Tag AS location,
        E.Ex_Material_Active AS material_status,
        E.Last_Used AS last_used,
        E.EX_wellplate_num AS wellplate,
        E.EX_well_num AS well,
        E.EX_Barcode AS barcode
FROM T_Experiments AS E
        INNER JOIN T_Campaign AS C ON E.EX_campaign_ID = C.Campaign_ID
        INNER JOIN T_Users AS U ON E.EX_researcher_PRN = U.U_PRN
        INNER JOIN T_Enzymes AS Enz ON E.EX_enzyme_ID = Enz.Enzyme_ID
        INNER JOIN T_Internal_Standards AS IntStdPre ON E.EX_internal_standard_ID = IntStdPre.Internal_Std_Mix_ID
        INNER JOIN T_Internal_Standards AS IntStdPost ON E.EX_postdigest_internal_std_ID = IntStdPost.Internal_Std_Mix_ID
        INNER JOIN T_Organisms AS Org ON E.EX_organism_ID = Org.Organism_ID
        INNER JOIN T_Material_Containers AS MC ON E.EX_Container_ID = MC.ID
        INNER JOIN T_Material_Locations AS ML ON MC.Location_ID = ML.ID
        LEFT OUTER JOIN ( SELECT COUNT(*) AS Datasets,
                                    MAX(DS_created) AS Most_Recent_Dataset,
                                    Exp_ID
                          FROM T_Dataset
                          GROUP BY  Exp_ID
                        ) AS DSCountQ ON DSCountQ.Exp_ID = E.Exp_ID
        LEFT OUTER JOIN V_Factor_Count_By_Experiment AS FC ON FC.Exp_ID = E.Exp_ID
        LEFT OUTER JOIN ( SELECT Entity_ID,
                                    COUNT(*) AS FileCount
                          FROM T_File_Attachment
                          WHERE     ( Entity_Type = 'experiment' )
                                    AND ( Active > 0 )
                          GROUP BY  Entity_ID
                        ) AS ExpFileCount ON ExpFileCount.Entity_ID = E.Experiment_Num
        LEFT OUTER JOIN ( SELECT EGM.Exp_ID,
                                    EGM.Group_ID,
                                    FA.FileCount
                          FROM T_Experiment_Group_Members AS EGM
                                    INNER JOIN T_Experiment_Groups AS EG ON EGM.Group_ID = EG.Group_ID
                                    INNER JOIN ( SELECT Entity_ID,
                                                        COUNT(*) AS FileCount
                                                 FROM T_File_Attachment
                                                 WHERE  ( Entity_Type = 'experiment_group' )
                                                        AND ( Active > 0 )
                                                 GROUP BY Entity_ID
                                               ) AS FA ON EG.Group_ID = CONVERT(INT, FA.Entity_ID)
                        ) AS ExpGroupFileCount ON ExpGroupFileCount.Exp_ID = E.Exp_ID
        LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
	     ON E.EX_Tissue_ID = BTO.Identifier
        LEFT OUTER JOIN T_Cached_Experiment_Components CEC
          ON E.Exp_ID = CEC.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Detail_Report_Ex] TO [DDL_Viewer] AS [dbo]
GO

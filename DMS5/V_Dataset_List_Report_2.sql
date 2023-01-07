/****** Object:  View [dbo].[V_Dataset_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_List_Report_2]
AS
SELECT DS.Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       E.Experiment_Num AS experiment,
       C.Campaign_Num AS campaign,
       DSN.DSS_name AS state,
       DSInst.instrument,
       DS.DS_created AS created,
       DS.DS_comment AS comment,
       DSRating.DRN_name AS rating,
       DTN.DST_name AS dataset_type,
       DS.DS_Oper_PRN AS operator,
       DL.Dataset_Folder_Path AS dataset_folder_path,
       -- Deprecated: DL.Archive_Folder_Path AS archive_folder_path,
       DL.QC_Link AS qc_link,
       ISNULL(DS.acq_time_start, RR.RDS_Run_Start) AS acq_start,
       ISNULL(DS.acq_time_end, RR.RDS_Run_Finish) AS acq_end,
       DS.Acq_Length_Minutes AS acq_length,
       DS.Scan_Count AS scan_count,
       Cast(DS.File_Size_Bytes / 1024.0 / 1024 AS decimal(9,2)) AS file_size_mb,
       CartConfig.Cart_Config_Name AS cart_config,
       LC.SC_Column_Number AS lc_column,
       DS.DS_sec_sep AS separation_type,
       -- Deprecated: RR.RDS_Blocking_Factor AS blocking_factor,
       -- Deprecated: RR.RDS_Block AS block,
       -- Deprecated: RR.RDS_Run_Order AS run_order,
       RR.ID AS request,
       -- Deprecated: RR.RDS_BatchID AS batch,
       EUT.Name AS usage,
       RR.RDS_EUS_Proposal_ID AS proposal,
       -- Deprecated to improve performance: EPT.Abbreviation AS eus_proposal_type,
       -- Deprecated to improve performance: EPT.Proposal_Type_Name AS proposal_type,
       RR.RDS_WorkPackage AS work_package,
       -- Deprecated: RR.RDS_Requestor_PRN AS requester,
       -- Deprecated: DASN.DASN_StateName AS archive_state,
       -- Deprecated: T_YesNo.Description AS inst_data_purged,
       Org.OG_name AS organism,
       BTO.tissue,
       DS.DateSortKey AS date_sort_key
FROM T_DatasetStateName DSN
     INNER JOIN T_Dataset DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN T_Cached_Dataset_Instruments DSInst
       ON DS.Dataset_ID = DSInst.Dataset_ID
     INNER JOIN T_DatasetRatingName DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     LEFT OUTER JOIN T_Cached_Dataset_Links AS DL
       ON DS.Dataset_ID = DL.Dataset_ID
     INNER JOIN T_LC_Column LC
       ON DS.DS_LC_column_ID = LC.ID
     INNER JOIN T_Organisms Org
       ON Org.Organism_ID = E.EX_organism_ID
     LEFT OUTER JOIN T_LC_Cart_Configuration CartConfig
       ON DS.Cart_Config_ID = CartConfig.Cart_Config_ID
     LEFT OUTER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     /*
      * Deprecated to improve performance:
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
     LEFT OUTER JOIN T_DatasetArchiveStateName DASN
                     INNER JOIN T_Dataset_Archive DA
                       ON DASN.DASN_StateID = DA.AS_state_ID
                     INNER JOIN T_YesNo
                       ON DA.AS_instrument_data_purged = T_YesNo.Flag
       ON DS.Dataset_ID = DA.AS_Dataset_ID
       */
     LEFT OUTER JOIN S_V_BTO_ID_to_Name AS BTO
       ON BTO.Identifier = E.EX_Tissue_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO

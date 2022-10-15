/****** Object:  View [dbo].[V_Dataset_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_List_Report_2] 
AS
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       DSN.DSS_name AS State,
       DSInst.Instrument,
       DS.DS_created AS Created,
       DS.DS_comment AS [Comment],
       DSRating.DRN_name AS Rating,
       DTN.DST_name AS [Dataset Type],
       DS.DS_Oper_PRN AS Operator,
       DL.Dataset_Folder_Path AS [Dataset Folder Path],
       DL.Archive_Folder_Path AS [Archive Folder Path],
       DL.QC_Link AS QC_Link,
       ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start) AS [Acq Start],
       ISNULL(DS.Acq_Time_End, RR.RDS_Run_Finish) AS [Acq. End],
       DS.Acq_Length_Minutes AS [Acq Length],
       DS.Scan_Count AS [Scan Count],
       Cast(DS.File_Size_Bytes / 1024.0 / 1024 AS decimal(9,2)) AS [File Size MB],
       CartConfig.Cart_Config_Name AS [Cart Config],
       LC.SC_Column_Number AS [LC Column],
       DS.DS_sec_sep AS [Separation Type],
       -- Deprecated: RR.RDS_Blocking_Factor AS [Blocking Factor],
       -- Deprecated: RR.RDS_Block AS [Block],
       -- Deprecated: RR.RDS_Run_Order AS [Run Order],
       RR.ID AS Request,
       RR.RDS_BatchID AS Batch,
       EUT.Name AS [Usage],
       RR.RDS_EUS_Proposal_ID AS [Proposal],
       EPT.Proposal_Type_Name AS [Proposal Type],    -- Alternatively, show EPT.Abbreviation
       RR.RDS_WorkPackage AS [Work Package],
       RR.RDS_Requestor_PRN AS Requester,
       -- Deprecated: DASN.DASN_StateName AS [Archive State],
       -- Deprecated: T_YesNo.Description AS [Inst. Data Purged],
       Org.OG_name AS Organism,
       BTO.Tissue,
       DS.DateSortKey AS #DateSortKey
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
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
     /*
      * Deprecated to improve performance: 
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

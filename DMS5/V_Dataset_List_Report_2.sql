/****** Object:  View [dbo].[V_Dataset_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Dataset_List_Report_2] as 

SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       Exp.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       DSN.DSS_name AS State,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DS.DS_comment AS [Comment],
       DSRating.DRN_name AS Rating,
       DTN.DST_name AS [Dataset Type],
       DS.DS_Oper_PRN AS Operator,
       DFP.Dataset_Folder_Path AS [Dataset Folder Path],
       CASE
           WHEN DA.MyEMSLState > 0 THEN 'MyEMSL'
           ELSE DFP.Archive_Folder_Path
       END AS [Archive Folder Path],
       DFP.Dataset_URL + 'QC/index.html' AS QC_Link,
       ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start) AS [Acq Start],
       ISNULL(DS.Acq_Time_End, RRH.RDS_Run_Finish) AS [Acq. End],
       DS.Acq_Length_Minutes AS [Acq Length],
       DS.Scan_Count AS [Scan Count],
       LC.SC_Column_Number AS [LC Column],
       DS.DS_sec_sep AS [Separation Type],
       RRH.RDS_Blocking_Factor AS [Blocking Factor],
       RRH.RDS_Block AS [Block],
       RRH.RDS_Run_Order AS [Run Order],
       RRH.ID AS Request,
       RRH.RDS_EUS_Proposal_ID AS [EMSL Proposal],
       RRH.RDS_WorkPackage AS [Work Package],
       RRH.RDS_Oper_PRN AS Requester,
       DASN.DASN_StateName AS [Archive State],
       T_YesNo.Description AS [Inst. Data Purged],
	   DS.DateSortKey AS #DateSortKey
FROM T_DatasetArchiveStateName DASN
     INNER JOIN T_Dataset_Archive DA
       ON DASN.DASN_StateID = DA.AS_state_ID
     LEFT OUTER JOIN T_YesNo
       ON DA.AS_instrument_data_purged = T_YesNo.Flag
     RIGHT OUTER JOIN T_DatasetStateName DSN
                      INNER JOIN T_Dataset DS
                        ON DSN.Dataset_state_ID = DS.DS_state_ID
                      INNER JOIN T_DatasetTypeName DTN
                        ON DS.DS_type_ID = DTN.DST_Type_ID
                      INNER JOIN T_Instrument_Name InstName
                        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                      INNER JOIN T_DatasetRatingName DSRating
                        ON DS.DS_rating = DSRating.DRN_state_ID
                      INNER JOIN T_Experiments Exp
                        ON DS.Exp_ID = Exp.Exp_ID
                      INNER JOIN T_Campaign C
                        ON Exp.EX_campaign_ID = C.Campaign_ID
                      INNER JOIN V_Dataset_Folder_Paths DFP
                        ON DS.Dataset_ID = DFP.Dataset_ID
                      INNER JOIN T_LC_Column LC
                        ON DS.DS_LC_column_ID = LC.ID
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN T_Requested_Run RRH
       ON DS.Dataset_ID = RRH.DatasetID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_List_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_List_Report_2] TO [PNL\D3M580] AS [dbo]
GO

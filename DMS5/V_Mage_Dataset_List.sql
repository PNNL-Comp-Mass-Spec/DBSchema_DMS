/****** Object:  View [dbo].[V_Mage_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mage_Dataset_List] AS 
SELECT DS.Dataset_ID AS Dataset_ID,
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       DSN.DSS_name AS [State],
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DTN.DST_name AS [Type],
       CASE
           WHEN ISNULL(DA.AS_instrument_data_purged, 0) = 0 THEN DFP.Dataset_Folder_Path
           ELSE CASE
                    WHEN DA.MyEMSLState >= 1 THEN DFP.MyEMSL_Path_Flag
                    ELSE DFP.Archive_Folder_Path
                END
       END AS Folder,
       DS.DS_comment AS [Comment],
	   Org.OG_name AS Organism
FROM T_Dataset DS
     INNER JOIN T_DatasetStateName DSN
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
	 INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     LEFT OUTER JOIN T_Dataset_Archive DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Dataset_List] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_DatasetFullDetails] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DatasetFullDetails]
As
SELECT DS.Dataset_Num,
       DS.DS_created,
       InstName.IN_name,
       DSN.DSS_name,
       ISNULL(DS.DS_comment, '') AS DS_comment,
       DS.DS_folder_name,
       SPath.SP_path,
       SPath.SP_vol_name_server,
       SPath.SP_vol_name_client,
       DTN.DST_name,
       DS.DS_sec_sep,
       LCCart.Cart_Name AS LC_Cart_Name,
       CartConfig.Cart_Config_Name AS LC_Cart_Config,
       LCCol.SC_Column_Number AS LC_Column,
       ISNULL(DS.DS_well_num, 'na') AS DS_Well_num,
       DS.DS_Oper_PRN AS DS_Oper_Username,
       DS.Dataset_ID,
       E.Experiment_Num,
       ISNULL(E.EX_reason, '') AS EX_Reason,
       Org.OG_name AS EX_organism_name,
       ISNULL(CCE.Cell_Culture_List, '') AS EX_cell_culture_list,
       E.EX_researcher_PRN AS EX_researcher_Username,
       ISNULL(E.EX_comment, '') AS EX_comment,
       ISNULL(E.EX_lab_notebook_ref, 'na') AS EX_lab_notebook_ref,
       C.Campaign_Num,
       C.CM_Project_Num,
       ISNULL(C.CM_comment, '') AS CM_Comment,
       C.CM_created,
       ISNULL(E.EX_sample_concentration, 'na') AS EX_sample_concentration,
       E.EX_Labelling,
       L.Reporter_Mz_Min,
       L.Reporter_Mz_Max
FROM T_Dataset DS
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Dataset_State_Name DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN T_Sample_Labelling L
       ON E.EX_Labelling = L.Label
     LEFT OUTER JOIN T_LC_Column AS LCCol
      ON DS.DS_LC_column_ID = LCCol.ID
     LEFT OUTER JOIN T_Cached_Experiment_Components CCE
       ON E.Exp_ID = CCE.Exp_ID
     LEFT OUTER JOIN T_LC_Cart AS LCCart
                     INNER JOIN T_Requested_Run AS RR
                       ON LCCart.ID = RR.RDS_Cart_ID
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN T_LC_Cart_Configuration AS CartConfig
       ON DS.Cart_Config_ID = CartConfig.Cart_Config_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetFullDetails] TO [DDL_Viewer] AS [dbo]
GO

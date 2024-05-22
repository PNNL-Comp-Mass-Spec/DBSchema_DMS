/****** Object:  View [dbo].[V_DMS_Dataset_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_DMS_Dataset_Metadata]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       TDT.DST_Name AS [Type],
       DS.DS_folder_name AS Directory,
       TIN.IN_class AS Instrument_Class,
       TIN.IN_name AS Instrument_Name,
       TIN.IN_capture_method AS Method,
       TIN.IN_Max_Simultaneous_Captures AS Max_Simultaneous_Captures,
       TIN.IN_Capture_Exclusion_Window AS Capture_Exclusion_Window,
       EUSInst.EUS_Instrument_ID,
       RR.RDS_EUS_Proposal_ID AS EUS_Proposal_ID,
       DS.DS_Oper_PRN AS Operator_Username,
       IsNull(EUSProposalUser.EUS_User_ID, EUSUser.EUS_Person_ID) AS EUS_Operator_ID,
       DS.DS_created AS Created,
       DS.Acq_Time_Start,
       DS.Acq_Time_End,
       RR.RDS_Run_Start AS Request_Run_Start,
       RR.RDS_Run_Finish AS Request_Run_Finish,
       TSrc.SP_path AS source_Path,
       TSrc.SP_vol_name_server AS source_Vol,
       TSrc.SP_path_ID AS Source_path_ID,
       TStor.SP_machine_name AS Storage_Server_Name,
       TStor.SP_vol_name_server AS Storage_Vol,
       TStor.SP_path AS Storage_Path,
       TStor.SP_vol_name_client AS Storage_Vol_External,
       TStor.SP_path_ID AS Storage_path_ID,
       TAP.AP_Server_Name AS Archive_Server,
       TAP.AP_archive_path AS Archive_Path,
       TAP.AP_network_share_path AS Archive_Network_Share_Path,
       TDA.AS_storage_path_ID AS Archive_Path_ID,
       TAP.AP_path_ID
FROM S_DMS_T_Dataset AS DS
     INNER JOIN S_DMS_T_Instrument_Name AS TIN
       ON DS.DS_instrument_name_ID = TIN.Instrument_ID
     INNER JOIN S_DMS_T_Dataset_Type_Name AS TDT
       ON DS.DS_type_ID = TDT.DST_Type_ID
     INNER JOIN S_DMS_t_storage_path AS TSrc
       ON TIN.IN_source_path_ID = TSrc.SP_path_ID
     INNER JOIN S_DMS_t_storage_path AS TStor
       ON TStor.SP_path_ID = DS.DS_storage_path_ID
     LEFT OUTER JOIN S_DMS_T_Dataset_Archive AS TDA
       ON DS.Dataset_ID = TDA.AS_Dataset_ID
     LEFT OUTER JOIN S_DMS_T_Archive_Path AS TAP
       ON TDA.AS_storage_path_ID = TAP.AP_path_ID
     LEFT OUTER JOIN S_DMS_V_EUS_Instrument_ID_Lookup EUSInst
       ON TIN.Instrument_ID = EUSInst.Instrument_ID
     LEFT OUTER JOIN S_DMS_T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
	 LEFT OUTER JOIN S_DMS_V_EUS_User_ID_Lookup EUSUser
	   ON DS.DS_Oper_PRN = EUSUser.Username
     LEFT OUTER JOIN S_DMS_V_EUS_Proposal_User_Lookup EUSProposalUser
       ON EUSProposalUser.Proposal_ID = RR.RDS_EUS_Proposal_ID And
          DS.DS_Oper_PRN = EUSProposalUser.Username And
          EUSProposalUser.Valid_EUS_ID > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Dataset_Metadata] TO [DDL_Viewer] AS [dbo]
GO

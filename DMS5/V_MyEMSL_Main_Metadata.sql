/****** Object:  View [dbo].[V_MyEMSL_Main_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Main_Metadata] 
AS 
SELECT DS.Dataset_ID AS dataset_id,
       DS.Dataset_Num AS dataset_name,
       DS.DS_Oper_PRN AS submitter_username,
       COALESCE(RR.RDS_EUS_Proposal_ID, '17797') AS proposal_id,
       COALESCE(DMSInstMap.EUS_Instrument_ID, 34127) AS instrument_id,
       DS.DS_created AS dataset_ctime,
       COALESCE(DS.File_Info_Last_Modified, DS.DS_created) AS dataset_mtime
FROM dbo.T_Dataset AS DS
     LEFT OUTER JOIN dbo.T_Requested_Run AS RR
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_EMSL_DMS_Instrument_Mapping AS DMSInstMap
       ON DMSInstMap.DMS_Instrument_ID = DS.DS_instrument_name_ID

GO

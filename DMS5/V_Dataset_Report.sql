/****** Object:  View [dbo].[V_Dataset_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_Report]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID AS ID,
       DSN.DSS_name AS State,
       DSR.DRN_name AS Rating,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DS.DS_comment AS [Comment],
       ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start) AS [Acq Start],
       DS.Acq_Length_Minutes AS [Acq Length],
       --DATEDIFF(MINUTE, ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start), ISNULL(DS.Acq_Time_End, RRH.RDS_Run_Finish)) AS [Acq Length],
       DS.DS_Oper_PRN AS [Oper.],
       DTN.DST_Name AS [Type],
       E.Experiment_Num AS Experiment,
	   C.Campaign_Num AS Campaign,
       RRH.ID AS Request,
       ISNULL(SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num), '') AS [Dataset Folder Path],
       ISNULL(DAP.Archive_Path + '\' + ISNULL(DS.DS_folder_name, DS.Dataset_Num), '') AS [Archive Folder Path]
FROM dbo.T_DatasetStateName AS DSN
     INNER JOIN dbo.T_Dataset AS DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN dbo.T_DatasetTypeName AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_DatasetRatingName AS DSR
       ON DS.DS_rating = DSR.DRN_state_ID
     INNER JOIN dbo.T_Experiments AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.t_storage_path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN dbo.T_Requested_Run AS RRH
       ON DS.Dataset_ID = RRH.DatasetID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path AS DAP
       ON DS.Dataset_ID = DAP.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Report] TO [DDL_Viewer] AS [dbo]
GO

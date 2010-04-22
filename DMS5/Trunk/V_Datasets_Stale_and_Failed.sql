/****** Object:  View [dbo].[V_Datasets_Stale_and_Failed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Datasets_Stale_and_Failed]
AS
SELECT *
FROM (
	SELECT CASE WHEN (DS.DS_State_ID IN (5, 8, 12) AND DS.DS_Last_Affected >= DATEADD(day, -14, GETDATE()) )  THEN 'Capture failed within the last 14 days'
				WHEN (DS.DS_State_ID IN (2, 7, 11) AND DATEDIFF(hour, DS.DS_Last_Affected, GetDate()) >= 12 ) THEN 'Capture in progress over 12 hours'
				WHEN (DS.DS_State_ID IN (1)        AND DATEDIFF(day, DS.DS_Last_Affected, GetDate()) >= 14 )  THEN 'Uncaptured (new) over 14 days'
				ELSE ''
		   END AS Warning_Message,
		   DS.Dataset_Num AS Dataset,
		   DS.Dataset_ID as Dataset_ID,
		   DS.DS_created AS Dataset_Created,
		   Instrument.IN_name AS Instrument,
		   CONVERT(varchar(64), DSN.DSS_name + ' (dataset)') AS State,
		   DS.DS_Last_Affected AS State_Date,
		   Spath.SP_vol_name_client + Spath.SP_path AS Storage_Path
	FROM dbo.T_Dataset DS
		 INNER JOIN dbo.T_DatasetStateName DSN
		   ON DS.DS_state_ID = DSN.Dataset_state_ID
		 INNER JOIN dbo.T_Instrument_Name Instrument
		   ON DS.DS_instrument_name_ID = Instrument.Instrument_ID
		 INNER JOIN dbo.t_storage_path Spath
		   ON DS.DS_storage_path_ID = Spath.SP_path_ID
	WHERE DS.DS_State_ID IN (1, 2, 5, 7, 8, 11, 12)
	UNION
	SELECT  CASE WHEN (DA.AS_state_ID IN (6, 8, 13) AND DA.AS_state_Last_Affected >= DATEADD(day, -14, GETDATE()) )  THEN 'Archive failed within the last 14 days'
				 WHEN (DA.AS_state_ID IN (2, 7, 12) AND DATEDIFF(hour, DA.AS_state_Last_Affected, GetDate()) >= 12 ) THEN 'Archive in progress over 12 hours'
				 WHEN (DA.AS_state_ID IN (1, 11)    AND DATEDIFF(day, DA.AS_state_Last_Affected, GetDate()) >= 14 )  THEN 'Archive State New or Verification Required over 14 days'
				 ELSE ''
		   END AS Warning_Message,
		   DS.Dataset_Num AS Dataset,
		   DS.Dataset_ID as Dataset_ID,
		   DS.DS_created AS Dataset_Created,
		   Instrument.IN_name AS Instrument,
		   CONVERT(varchar(64), DASN.DASN_StateName + ' (archive)') AS State,
		   DA.AS_state_Last_Affected AS State_Date, 
		   Spath.SP_vol_name_client + Spath.SP_path AS Storage_Path
	FROM dbo.T_Dataset_Archive DA
		 INNER JOIN dbo.T_DatasetArchiveStateName DASN
		   ON DA.AS_state_ID = DASN.DASN_StateID
		 INNER JOIN dbo.T_Archive_Update_State_Name AUSN
		   ON DA.AS_update_state_ID = AUSN.AUS_stateID
		 INNER JOIN dbo.T_Dataset DS
		   ON DA.AS_Dataset_ID = DS.Dataset_ID
		 INNER JOIN dbo.T_Instrument_Name Instrument
		   ON DS.DS_instrument_name_ID = Instrument.Instrument_ID
		 INNER JOIN dbo.t_storage_path Spath
		   ON DS.DS_storage_path_ID = Spath.SP_path_ID
	WHERE DA.AS_state_ID IN (1, 2, 6, 7, 8, 11, 12, 13)
	UNION
	SELECT  CASE WHEN (DA.AS_update_state_ID IN (5) AND DA.AS_update_state_Last_Affected >= DATEADD(day, -14, GETDATE()) )  THEN 'Archive update failed within the last 14 days'
				 WHEN (DA.AS_update_state_ID IN (3) AND DATEDIFF(hour, DA.AS_update_state_Last_Affected, GetDate()) >= 12 ) THEN 'Archive update in progress over 12 hours'
				 WHEN (DA.AS_update_state_ID IN (2) AND DATEDIFF(day, DA.AS_update_state_Last_Affected, GetDate()) >= 14 )  THEN 'Archive update required over 14 days'
				 ELSE ''
		   END AS Warning_Message,
		   DS.Dataset_Num AS Dataset,
		   DS.Dataset_ID as Dataset_ID,
		   DS.DS_created AS Dataset_Created,
		   Instrument.IN_name AS Instrument,
		   CONVERT(varchar(64), AUSN.AUS_name + ' (archive update)') AS State,
		   DA.AS_update_state_Last_Affected AS State_Date,
		   Spath.SP_vol_name_client + Spath.SP_path AS Storage_Path
	FROM dbo.T_Dataset_Archive DA
		 INNER JOIN dbo.T_DatasetArchiveStateName DASN
		   ON DA.AS_state_ID = DASN.DASN_StateID
		 INNER JOIN dbo.T_Archive_Update_State_Name AUSN
		   ON DA.AS_update_state_ID = AUSN.AUS_stateID
		 INNER JOIN dbo.T_Dataset DS
		   ON DA.AS_Dataset_ID = DS.Dataset_ID
		 INNER JOIN dbo.T_Instrument_Name Instrument
		   ON DS.DS_instrument_name_ID = Instrument.Instrument_ID
		 INNER JOIN dbo.t_storage_path Spath
		   ON DS.DS_storage_path_ID = Spath.SP_path_ID
	WHERE DA.AS_update_state_ID IN (2, 3, 5)
) UnionQ
WHERE Warning_Message <> ''
GO
GRANT VIEW DEFINITION ON [dbo].[V_Datasets_Stale_and_Failed] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Datasets_Stale_and_Failed] TO [PNL\D3M580] AS [dbo]
GO

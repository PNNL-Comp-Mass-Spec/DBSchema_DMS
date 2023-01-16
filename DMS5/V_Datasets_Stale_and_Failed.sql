/****** Object:  View [dbo].[V_Datasets_Stale_and_Failed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Datasets_Stale_and_Failed]
AS
WITH JobStepStatus (Dataset_ID, ActiveSteps, ActiveArchiveStatusSteps)
AS (
	SELECT J.Dataset_ID, COUNT(*) AS ActiveSteps, SUM(CASE WHEN JS.Step_Tool IN ('ArchiveStatusCheck', 'ArchiveVerify') 
	   THEN 1 ELSE 0 END) AS ActiveArchiveStatusSteps
	FROM DMS_Capture.dbo.T_Job_Steps JS INNER JOIN
	   DMS_Capture.dbo.T_Jobs J ON JS.Job = J.Job INNER JOIN
	   T_Dataset_Archive DA ON J.Dataset_ID = DA.AS_Dataset_ID
	WHERE (DA.AS_state_ID IN (2, 7, 12)) AND (JS.State NOT IN (3, 5))
	GROUP BY J.Dataset_ID
)
SELECT *
FROM (
	SELECT TSF.Warning_Message,
		   DS.Dataset_Num AS Dataset,
		   DS.Dataset_ID as Dataset_ID,
		   DS.DS_created AS Dataset_Created,
		   Instrument.IN_name AS Instrument,
		   CONVERT(varchar(64), DSN.DSS_name + ' (dataset)') AS State,
		   DS.DS_Last_Affected AS State_Date,
		   TSF.Script,
	       TSF.Tool,
	       TSF.RunTime_Minutes,
	       TSF.State_Name AS Step_State,
	       TSF.Processor,
	       TSF.Start,
	       TSF.Step,
		   Spath.SP_vol_name_client + Spath.SP_path AS Storage_Path
	FROM DMS_Capture.dbo.V_Task_Steps_Stale_and_Failed TSF 
	     INNER JOIN dbo.T_Dataset DS
	       ON TSF.Dataset_ID = DS.Dataset_ID
		 INNER JOIN dbo.T_DatasetStateName DSN
		   ON DS.DS_state_ID = DSN.Dataset_state_ID
		 INNER JOIN dbo.T_Instrument_Name Instrument
		   ON DS.DS_instrument_name_ID = Instrument.Instrument_ID
		 INNER JOIN dbo.t_storage_path Spath
		   ON DS.DS_storage_path_ID = Spath.SP_path_ID
    UNION
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
           '' AS Script,
	       '' AS Tool,
	       0 AS RunTime_Minutes,
	       '' AS Step_State,
	       '' AS Processor,
	       Null AS Start,
	       0 AS Step,
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
				 WHEN (DA.AS_state_ID IN (2, 7, 12) AND DATEDIFF(hour, DA.AS_state_Last_Affected, GetDate()) >= 12 ) AND 
				      JobStepStatus.ActiveSteps > JobStepStatus.ActiveArchiveStatusSteps THEN 'Archive in progress over 12 hours'
				 WHEN (DA.AS_state_ID IN (2, 7, 12) AND DATEDIFF(day, DA.AS_state_Last_Affected, GetDate()) >= 5 )   THEN 'Archive verification in progress over 5 days'
				 WHEN (DA.AS_state_ID IN (1, 11)    AND DATEDIFF(day, DA.AS_state_Last_Affected, GetDate()) >= 14 )  THEN 'Archive State New or Verification Required over 14 days'
				 ELSE ''
		   END AS Warning_Message,
		   DS.Dataset_Num AS Dataset,
		   DS.Dataset_ID as Dataset_ID,
		   DS.DS_created AS Dataset_Created,
		   Instrument.IN_name AS Instrument,
		   CONVERT(varchar(64), DASN.DASN_StateName + ' (archive)') AS State,
		   DA.AS_state_Last_Affected AS State_Date, 
		   '' AS Script,
	       '' AS Tool,
	       0 AS RunTime_Minutes,
	       '' AS Step_State,
	       '' AS Processor,
	       Null AS Start,
	       0 AS Step,
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
	     LEFT OUTER JOIN JobStepStatus 
		   ON DA.AS_Dataset_ID = JobStepStatus.Dataset_ID		    
	WHERE DA.AS_state_ID IN (1, 2, 6, 7, 8, 11, 12, 13) AND 
	      NOT Exists (Select * FROM T_MiscOptions WHERE Name = 'ArchiveDisabled' and Value = 1)
) UnionQ
WHERE Warning_Message <> ''


GO
GRANT VIEW DEFINITION ON [dbo].[V_Datasets_Stale_and_Failed] TO [DDL_Viewer] AS [dbo]
GO

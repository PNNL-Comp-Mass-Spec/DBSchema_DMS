/****** Object:  View [dbo].[V_Event_Log_24_Hour_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log_24_Hour_Summary]
AS
SELECT '    DMS ACTIVITY REPORT (Previous 24 Hours)' AS label, cast(getdate() AS varchar(24)) AS value
UNION
SELECT '(A) NEW ENTRIES' AS label, '' AS value
UNION
SELECT '(D) DATASET ACTIVITY' AS label, '' AS value
UNION
SELECT '(J) ANALYSIS JOB ACTIVITY' AS label, '' AS value
UNION
SELECT '(V) ARCHIVE ACTIVITY' AS label, '' AS value
UNION
SELECT '(A1) Campaigns entered' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Campaign
WHERE     CM_created > DateAdd(Hour, -24, GetDate())
UNION
SELECT '(A2) Cell Cultures entered' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Cell_Culture
WHERE     CC_created > DateAdd(Hour, -24, GetDate())
UNION
SELECT '(A3) Experiments entered' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Experiments
WHERE     EX_created > DateAdd(Hour, -24, GetDate())
UNION
SELECT '(A4) Datasets entered' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Dataset
WHERE     DS_created > DateAdd(Hour, -24, GetDate())
UNION
SELECT '(A5) Analysis Jobs entered (total)' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Analysis_Job
WHERE     AJ_created > DateAdd(Hour, -24, GetDate())
UNION
SELECT '(A6) Analysis Jobs entered (auto)' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Analysis_Job
WHERE     AJ_created > DateAdd(Hour, -24, GetDate()) AND (AJ_Comment LIKE '%Auto predefined%')
UNION
SELECT '(D1) Dataset Capture Successful' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 4) AND (Target_State = 3)
UNION
SELECT '(D2) Dataset Received Successful' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 4) AND (Target_State = 6)
UNION
SELECT '(X1) Dataset Capture Failed' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 4) AND (Target_State = 5)
UNION
SELECT '(X2) Dataset Prep Failed' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 4) AND (Target_State = 8)
UNION
SELECT '(V1) Dataset Archive Successful' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 6) AND (Target_State = 3)
UNION
SELECT '(V1) Dataset Purge Successful' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 6) AND (Target_State = 4)
UNION
SELECT '(X7) Dataset Archive Fail' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 6) AND (Target_State = 6)
UNION
SELECT '(X8) Dataset Purge Fail' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 6) AND (Target_State = 8)
UNION
SELECT '(J1) Analysis Jobs Successful' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 5) AND (Target_State = 4)
UNION
SELECT '(X3) Analysis Jobs Fail (no intermed. files)' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 5) AND (Target_State = 7)
UNION
SELECT '(X4) Analysis Jobs Fail (transfer)' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 5) AND (Target_State = 6)
UNION
SELECT '(X5) Analysis Jobs Fail (spectra req`d.)' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 5) AND (Target_State = 12)
UNION
SELECT '(X6) Analysis Jobs Fail (just failed)' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (Target_Type = 5) AND (Target_State = 5)
UNION
SELECT '(X) FAILURES' AS label, CASE WHEN COUNT(*) > 0 THEN 'Errors Detected: ' + Convert(varchar(12), COUNT(*)) ELSE '' END AS value
FROM T_Event_Log
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (((Target_Type = 4) AND (Target_State = 5)) OR
                      ((Target_Type = 4) AND (Target_State = 8)) OR
                      ((Target_Type = 6) AND (Target_State = 6)) OR
                      ((Target_Type = 6) AND (Target_State = 8)) OR
                      ((Target_Type = 5) AND (Target_State = 7)) OR
                      ((Target_Type = 5) AND (Target_State = 6)) OR
                      ((Target_Type = 5) AND (Target_State = 5)) OR
                      ((Target_Type = 5) AND (Target_State = 12)))
UNION
SELECT '(A5a) Analysis Jobs entered (' + T_Analysis_Tool.AJT_toolName + ')' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Analysis_Job INNER JOIN
                      T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID
WHERE     T_Analysis_Job.AJ_Created > DateAdd(Hour, -24, GetDate())
GROUP BY T_Analysis_Tool.AJT_toolName
UNION
SELECT '(J1a) Analysis Jobs Successful (' + T_Analysis_Tool.AJT_toolName + ')' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log INNER JOIN
                      T_Analysis_Job ON T_Event_Log.Target_ID = T_Analysis_Job.AJ_jobID INNER JOIN
                      T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID
WHERE     T_Event_Log.Entered > DateAdd(Hour, -24, GetDate()) AND (T_Event_Log.Target_Type = 5) AND (T_Event_Log.Target_State = 4)
GROUP BY T_Analysis_Tool.AJT_toolName
UNION
SELECT '(A4a) Datasets entered (' + T_Instrument_Name.IN_class + ')' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Dataset INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE     T_Dataset.DS_Created > DateAdd(Hour, -24, GetDate())
GROUP BY T_Instrument_Name.IN_class
UNION
SELECT '(A4a) Datasets entered (' + T_Instrument_Name.IN_class + ')' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Dataset INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE     T_Dataset.DS_Created > DateAdd(Hour, -24, GetDate())
GROUP BY T_Instrument_Name.IN_class
UNION
SELECT '(D1a) Dataset Capture Successful (' + T_Instrument_Name.IN_class + ')' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Event_Log INNER JOIN
                      T_Dataset ON T_Event_Log.Target_ID = T_Dataset.Dataset_ID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE     T_Event_Log.Entered > DateAdd(Hour, -24, GetDate()) AND (T_Event_Log.Target_Type = 4) AND (T_Event_Log.Target_State = 3)
GROUP BY T_Instrument_Name.IN_class
UNION
SELECT '(X9) Warnings' AS label, CAST(COUNT(*) AS varchar(12)) AS value
FROM T_Log_Entries
WHERE     Entered > DateAdd(Hour, -24, GetDate()) AND (type = 'Warning')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log_24_Hour_Summary] TO [DDL_Viewer] AS [dbo]
GO

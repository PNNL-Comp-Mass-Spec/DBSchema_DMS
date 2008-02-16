/****** Object:  View [dbo].[V_Event_Log_24_Hour_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Event_Log
AS
SELECT EL."Index",
       EL.Target_Type,
       CASE EL.Target_Type
           WHEN 1 THEN 'Campaign'
           WHEN 2 THEN 'Cell Culture'
           WHEN 3 THEN 'Experiment'
           WHEN 4 THEN 'Dataset'
           WHEN 5 THEN 'Job'
           WHEN 6 THEN 'DS Archive'
           WHEN 7 THEN 'DS ArchUpdate'
           WHEN 8 THEN 'DS Rating'
           ELSE NULL
       END AS Target,
       EL.Target_ID,
       EL.Target_State,
       CASE EL.Target_Type
           WHEN 1 THEN CASE Target_State
                           WHEN 1 THEN 'Created'
                           WHEN 0 THEN 'Deleted'
                           ELSE NULL
                       END
           WHEN 2 THEN CASE Target_State
                           WHEN 1 THEN 'Created'
                           WHEN 0 THEN 'Deleted'
                           ELSE NULL
                       END
           WHEN 3 THEN CASE Target_State
                           WHEN 1 THEN 'Created'
                           WHEN 0 THEN 'Deleted'
                           ELSE NULL
                       END
           WHEN 4 THEN DSSN.DSS_name
           WHEN 5 THEN AJSN.AJS_name
           WHEN 6 THEN DASN.DASN_StateName
           WHEN 7 THEN AUSN.AUS_name
           WHEN 8 THEN DSRN.DRN_name
           ELSE NULL
       END AS State_Name,
       EL.Prev_Target_State,
       EL.Entered,
       EL.Entered_By
FROM dbo.T_Event_Log EL
     LEFT OUTER JOIN dbo.T_DatasetRatingName DSRN
       ON EL.Target_State = DSRN.DRN_state_ID AND
          EL.Target_Type = 8
     LEFT OUTER JOIN dbo.T_DatasetStateName DSSN
       ON EL.Target_State = DSSN.Dataset_state_ID AND
          EL.Target_Type = 4
     LEFT OUTER JOIN dbo.T_Archive_Update_State_Name AUSN
       ON EL.Target_State = AUSN.AUS_stateID AND
          EL.Target_Type = 7
     LEFT OUTER JOIN dbo.T_DatasetArchiveStateName DASN
       ON EL.Target_State = DASN.DASN_StateID AND
          EL.Target_Type = 6
     LEFT OUTER JOIN dbo.T_Analysis_State_Name AJSN
       ON EL.Target_State = AJSN.AJS_stateID AND
          EL.Target_Type = 5

GO
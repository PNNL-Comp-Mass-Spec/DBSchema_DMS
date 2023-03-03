/****** Object:  View [dbo].[V_Event_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Event_Log]
AS
SELECT EL.Event_ID,
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
           WHEN 9 THEN 'Campaign Percent EMSL Funded'
           WHEN 10 THEN 'Campaign Data Release State'
           WHEN 11 THEN 'Requested Run'
           WHEN 12 THEN 'Analysis Job Request'
           When 13 Then 'Reference Compound'
           ELSE NULL
       END AS Target,
       EL.Target_ID,
       EL.Target_State,
       CASE
           WHEN EL.Target_Type In (1, 2, 3, 13) THEN
                       CASE Target_State
                           WHEN 1 THEN 'Created'
                           WHEN 0 THEN 'Deleted'
                           ELSE NULL
                       END
           WHEN EL.Target_Type = 4 THEN
                CASE WHEN EL.Target_State = 0 And EL.Prev_Target_State > 0 THEN 'Deleted'
                     ELSE DSSN.DSS_name
                END
           WHEN EL.Target_Type = 5 THEN
                CASE WHEN EL.Target_State = 0 And EL.Prev_Target_State > 0 THEN 'Deleted'
                     ELSE AJSN.AJS_name
                END
           WHEN EL.Target_Type = 6 THEN
                CASE WHEN EL.Target_State = 0 And EL.Prev_Target_State > 0 THEN 'Deleted'
                     ELSE DASN.archive_state
                END
           WHEN EL.Target_Type = 7 THEN AUSN.AUS_name
           WHEN EL.Target_Type = 8 THEN DSRN.DRN_name
           WHEN EL.Target_Type = 9 THEN '% EMSL Funded'
           WHEN EL.Target_Type = 10 THEN DRR.Name
           WHEN EL.Target_Type = 11 THEN
                CASE WHEN EL.Target_State = 0 And EL.Prev_Target_State > 0 THEN 'Deleted'
                     ELSE RRSN.State_Name
                END
           WHEN EL.Target_Type = 12 THEN
                CASE WHEN EL.Target_State = 0 And EL.Prev_Target_State > 0 THEN 'Deleted'
                     ELSE AJRS.StateName
                END
           ELSE NULL
       END AS State_Name,
       EL.Prev_Target_State,
       EL.Entered,
       EL.Entered_By
FROM dbo.T_Event_Log EL
     LEFT OUTER JOIN dbo.T_Dataset_Rating_Name DSRN
       ON EL.Target_State = DSRN.DRN_state_ID AND
          EL.Target_Type = 8
     LEFT OUTER JOIN dbo.T_Dataset_State_Name DSSN
       ON EL.Target_State = DSSN.Dataset_state_ID AND
          EL.Target_Type = 4
     LEFT OUTER JOIN dbo.T_Archive_Update_State_Name AUSN
       ON EL.Target_State = AUSN.AUS_stateID AND
          EL.Target_Type = 7
     LEFT OUTER JOIN dbo.T_Dataset_Archive_State_Name DASN
       ON EL.Target_State = DASN.archive_state_id AND
          EL.Target_Type = 6
     LEFT OUTER JOIN dbo.T_Analysis_State_Name AJSN
       ON EL.Target_State = AJSN.AJS_stateID AND
          EL.Target_Type = 5
     LEFT OUTER JOIN dbo.T_Data_Release_Restrictions DRR
       ON EL.Target_State = DRR.ID AND
          EL.Target_Type = 10
     LEFT OUTER JOIN T_Requested_Run_State_Name RRSN
       ON EL.Target_State = RRSN.State_ID AND
          EL.Target_Type = 11
     LEFT OUTER JOIN T_Analysis_Job_Request_State AJRS
       ON EL.Target_State = AJRS.ID AND
          EL.Target_Type = 12

GO
GRANT VIEW DEFINITION ON [dbo].[V_Event_Log] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Analysis_Job_Duration_Precise] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Duration_Precise]
AS
SELECT StartQ.Job,
       StartQ.Entered AS Job_Start,
       EndQ.Entered AS Job_Finish,
       T_Analysis_Job.AJ_ProcessingTimeMinutes AS Job_Length_Minutes,
       DATEDIFF(SECOND, StartQ.Entered, EndQ.Entered) / 60.0 AS Active_Queue_Time_Minutes
FROM ( SELECT Target_ID AS Job,
              MAX(entered) AS Entered
       FROM T_Event_Log
       WHERE (Target_type = 5) AND
             (Target_State = 2)
       GROUP BY Target_ID ) StartQ
     INNER JOIN T_Analysis_Job
       ON StartQ.Job = T_Analysis_Job.AJ_jobID
     LEFT OUTER JOIN ( SELECT Target_ID AS Job,
                              MAX(entered) AS Entered
                       FROM T_Event_Log
                       WHERE (Target_type = 5) AND
                             (Prev_Target_State = 2) AND
                             Target_state NOT IN (1, 2, 8)
                       GROUP BY Target_ID ) EndQ
       ON StartQ.Job = EndQ.Job AND
          StartQ.Entered < EndQ.Entered

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Duration_Precise] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Job_Step_Processing_Log_Retries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Processing_Log_Retries]
As
-- Job steps started within the last week where the step was reset at least once
SELECT JSL.Event_ID,
       JSL.Job,
       JSL.Step,
       JSL.Processor,
       JSL.Remote_Info_ID,
       JSL.Entered,
       JSL.Entered_By
FROM T_Job_Step_Processing_Log AS JSL
     INNER JOIN ( SELECT Job,
                         Step
                  FROM T_Job_Step_Processing_Log
                  WHERE (Entered >= DATEADD(DAY, -7, GETDATE()))
                  GROUP BY Job, Step
                  HAVING (COUNT(*) > 1) ) AS FilterQ
       ON JSL.Job = FilterQ.Job AND
          JSL.Step = FilterQ.Step


GO

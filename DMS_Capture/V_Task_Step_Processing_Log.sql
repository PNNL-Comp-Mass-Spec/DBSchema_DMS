/****** Object:  View [dbo].[V_Task_Step_Processing_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Task_Step_Processing_Log]
AS
With RankQ (Job, Step, JobStart, JSLRank) AS 
  (SELECT Job, Step, Entered AS JobStart, Row_Number() OVER (Partition BY Job, Step ORDER BY Entered) AS JSLRank
   FROM T_Job_Step_Processing_Log
  )
SELECT JSPL.job,
       JSPL.step,
       JSPL.processor,
       JSPL.entered,
       JSE.Entered AS entered_state,
       JSE.target_state,
       '\\' + LP.Machine + '\DMS_Programs\CaptureTaskManager' + 
         CASE
                    WHEN JSPL.Processor LIKE '%[-_][1-9]' THEN RIGHT(JSPL.Processor, 2)
                    ELSE ''
                END + '\Logs\CapTaskMan_' + 
         CASE
             WHEN Month(JSPL.Entered) < 10 THEN '0' + CONVERT(varchar(2), Month(JSPL.Entered))
             ELSE CONVERT(varchar(2), Month(JSPL.Entered))
         END + '-' + 
         CASE
             WHEN Day(JSPL.Entered) < 10 THEN '0' + CONVERT(varchar(2), Day(JSPL.Entered))
             ELSE CONVERT(varchar(2), Day(JSPL.Entered))
         END + '-' + 
         CONVERT(varchar(4), YEAR(JSPL.Entered)) + '.txt' AS log_file_path
FROM T_Job_Step_Processing_Log JSPL
     INNER JOIN T_Job_Step_Events JSE
       ON JSPL.Job = JSE.Job AND
          JSPL.Step = JSE.Step AND
          JSE.Entered >= DateAdd(second, -1, JSPL.Entered)
     INNER JOIN RankQ As ThisJSPL ON JSPL.Job = ThisJSPL.Job AND JSPL.Step = ThisJSPL.Step AND JSPL.Entered = ThisJSPL.JobStart
     LEFT OUTER JOIN RankQ AS NextJSPL ON JSPL.Job = NextJSPL.Job AND JSPL.Step = NextJSPL.Step AND ThisJSPL.JSLRank + 1 = NextJSPL.JSLRank
     INNER JOIN T_Local_Processors LP
       ON JSPL.Processor = LP.Processor_Name
WHERE JSE.Entered < IsNull(NextJSPL.JobStart, GETDATE()) AND JSE.Target_State NOT IN (0,1,2)


GO

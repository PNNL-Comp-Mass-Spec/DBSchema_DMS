/****** Object:  View [dbo].[V_Job_Step_Processing_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Processing_Log]
AS
With RankQ (Job, Step, JobStart, JSLRank) AS 
  (SELECT Job, Step, Entered AS JobStart, Row_Number() OVER (Partition BY Job, Step ORDER BY Entered) AS JSLRank
   FROM T_Job_Step_Processing_Log
  )
SELECT JSPL.Job,
       JSPL.Step,
       JSPL.Processor,
       JSPL.Entered,
       JSE.Entered AS Entered_State,
       JSE.Target_State,
       '\\' + LP.Machine + '\DMS_Programs\AnalysisToolManager' + 
         CONVERT(varchar(6), LP.ProcTool_Mgr_ID) + '\Logs\AnalysisMgr_' + 
         CASE
             WHEN Month(JSPL.Entered) < 10 THEN '0' + CONVERT(varchar(2), Month(JSPL.Entered))
             ELSE CONVERT(varchar(2), Month(JSPL.Entered))
         END + '-' + 
         CASE
             WHEN Day(JSPL.Entered) < 10 THEN '0' + CONVERT(varchar(2), Day(JSPL.Entered))
             ELSE CONVERT(varchar(2), Day(JSPL.Entered))
         END + '-' + 
         CONVERT(varchar(4), YEAR(JSPL.Entered)) + '.txt' AS LogFilePath
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

/****** Object:  View [dbo].[V_Pipeline_Jobs_Backfill] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Jobs_Backfill]
AS
SELECT J.Job,
       J.Priority,
       J.Script,
       J.State,
       J.Dataset,
       J.Results_Folder_Name,
       J.Imported,
       J.Start,
       J.Finish,
       J.Transfer_Folder_Path,
       J.[Comment],
       J.Owner,
       JPT.ProcessingTimeMinutes,
       J.DataPkgID
FROM T_Jobs J
     INNER JOIN T_Scripts S
       ON J.Script = S.Script
     INNER JOIN V_Job_Processing_Time JPT
       ON J.Job = JPT.Job
WHERE (S.Backfill_to_DMS = 1)


GO

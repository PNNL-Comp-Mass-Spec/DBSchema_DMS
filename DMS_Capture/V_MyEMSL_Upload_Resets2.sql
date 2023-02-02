/****** Object:  View [dbo].[V_MyEMSL_Upload_Resets2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Upload_Resets2]
AS
SELECT R.Entry_ID,
       R.Job,
       R.Dataset_ID,
       R.Subfolder,
       R.Error_Message,
       R.Entered,
       TS.Step,
       TS.Tool,
       TS.State_Name,
       TS.State,
       TS.Finish,
       TS.Processor,
       TS.Dataset,
	   U.Entry_ID AS Upload_Entry_ID,
       U.File_Count_New,
       U.File_Count_Updated,
       U.MB,
       U.Upload_Time_Seconds,
       U.Status_Num,
       U.Error_Code,
       U.Status_URI,
       U.Verified,
       U.Ingest_Steps_Completed
FROM T_MyEMSL_Upload_Resets R
     INNER JOIN V_Task_Steps TS
       ON R.Job = TS.Job
     INNER JOIN V_MyEMSL_Uploads U
       ON R.Job = U.Job
WHERE (TS.Step = 1)


GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Upload_Resets2] TO [DDL_Viewer] AS [dbo]
GO

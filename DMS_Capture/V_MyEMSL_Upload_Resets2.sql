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
       JS.Step,
       JS.Tool,
       JS.StateName,
       JS.State,
       JS.Finish,
       JS.Processor,
       JS.Dataset,
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
     INNER JOIN V_Job_Steps JS
       ON R.Job = JS.Job
     INNER JOIN V_MyEMSL_Uploads U
       ON R.Job = U.Job
WHERE (JS.Step = 1)


GO

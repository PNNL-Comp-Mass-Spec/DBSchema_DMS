/****** Object:  View [dbo].[V_MyEMSL_Upload_Resets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Upload_Resets]
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
       JS.Dataset
FROM T_MyEMSL_Upload_Resets R
     INNER JOIN V_Job_Steps JS
       ON R.Job = JS.Job
WHERE (JS.Step = 1)


GO

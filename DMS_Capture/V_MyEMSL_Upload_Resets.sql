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
       TS.Step,
       TS.Tool,
       TS.State_Name,
       TS.State,
       TS.Finish,
       TS.Processor,
       TS.Dataset
FROM T_MyEMSL_Upload_Resets R
     INNER JOIN V_Task_Steps TS
       ON R.Job = TS.Job
WHERE (TS.Step = 1)


GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Upload_Resets] TO [DDL_Viewer] AS [dbo]
GO

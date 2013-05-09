/****** Object:  View [dbo].[V_Job_Steps_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps_History]
AS
SELECT JS.Job,
       J.Dataset,
       J.Dataset_ID,
       JS.Step_Number AS Step,
       S.Script,
       JS.Step_Tool AS Tool,
       SSN.Name AS StateName,
       JS.State,
       JS.Start,
       JS.Finish,
       CONVERT(decimal(9, 1), DATEDIFF(SECOND, JS.Start, ISNULL(JS.Finish, GETDATE())) / 60.0) AS RunTime_Minutes,
       JS.Processor,
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       DInst.Instrument,
       JS.Tool_Version_ID,
       STV.Tool_Version,
       DI.SP_vol_name_client + DI.SP_path + DI.DS_folder_name AS Dataset_Folder_Path,
       DI.SP_vol_name_server + DI.SP_path + DI.DS_folder_name AS Server_Folder_Path,
       J.State AS Job_State
FROM T_Job_Steps_History JS
     INNER JOIN T_Job_Step_State_Name SSN
       ON JS.State = SSN.ID
     INNER JOIN T_Jobs_History J
       ON JS.Job = J.Job AND
          JS.Saved = J.Saved
     INNER JOIN T_Scripts S
       ON J.Script = S.Script
     INNER JOIN V_DMS_Dataset_Instruments DInst
       ON J.Dataset_ID = DInst.Dataset_ID
     LEFT OUTER JOIN V_DMS_Get_Dataset_Info DI
       ON J.Dataset = DI.Dataset_Num
     LEFT OUTER JOIN T_Step_Tool_Versions STV
       ON JS.Tool_Version_ID = STV.Tool_Version_ID


GO

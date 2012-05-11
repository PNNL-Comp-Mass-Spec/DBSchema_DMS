/****** Object:  View [dbo].[V_Job_Steps_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps_History]
AS
SELECT JS.Job,
       J.Dataset,
       JS.Step_Number AS Step,
       S.Script,
       JS.Step_Tool AS Tool,
       SSN.Name AS StateName,
       JS.State,
       JS.Start,
       JS.Finish,
       JS.Processor,
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Signature,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       JS.Tool_Version_ID,
       STV.Tool_Version,
       JS.Saved,
       JS.Most_Recent_Entry
FROM T_Step_Tool_Versions STV
     RIGHT OUTER JOIN T_Job_Steps_History JS
                      INNER JOIN T_Job_Step_State_Name SSN
                        ON JS.State = SSN.ID
       ON STV.Tool_Version_ID = JS.Tool_Version_ID
     LEFT OUTER JOIN T_Scripts S
                     INNER JOIN T_Jobs_History J
                       ON S.Script = J.Script
       ON JS.Job = J.Job AND
          JS.Saved = J.Saved
WHERE J.Most_Recent_Entry = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_History] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_History] TO [PNL\D3M580] AS [dbo]
GO

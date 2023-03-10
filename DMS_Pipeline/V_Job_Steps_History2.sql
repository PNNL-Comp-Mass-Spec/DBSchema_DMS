/****** Object:  View [dbo].[V_Job_Steps_History2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Job_Steps_History2]
AS
SELECT JS.Job,
       J.Dataset,
       JS.Step,
       S.Script,
       JS.Tool,
       ParamQ.Settings_File,
       ParamQ.Parameter_File,
       SSN.Name AS State_Name,
       JS.State,
       JS.Start,
       JS.Finish,
       CASE WHEN (JS.Remote_Info_ID > 1) AND NOT JS.Remote_Start IS NULL
            THEN CONVERT(decimal(9, 1), DATEDIFF(second, JS.Remote_Start, ISNULL(JS.Remote_Finish, GetDate())) / 60.0)
            WHEN NOT JS.Finish IS NULL
            THEN CONVERT(decimal(9, 1), DATEDIFF(SECOND, JS.Start, ISNULL(JS.Finish, GetDate())) / 60.0)
            ELSE NULL
       END AS RunTime_Minutes,
       JS.Processor,
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Signature,
       JS.Tool_Version_ID,
       STV.Tool_Version,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       JS.Remote_Info_ID,
       RI.Remote_Info,
       JS.Remote_Start,
       JS.Remote_Finish,
       J.Dataset_ID,
       LP.Machine,
       JS.Saved,
       JS.Most_Recent_Entry,
       ParamQ.Dataset_Storage_Path + J.Dataset AS Dataset_Folder_Path
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
     LEFT OUTER JOIN T_Remote_Info RI
       ON JS.Remote_Info_ID = RI.Remote_Info_ID
     LEFT OUTER JOIN T_Local_Processors LP
       On JS.Processor = LP.Processor_Name
     LEFT OUTER JOIN (
          SELECT Job,
                 Parameters.query('Param[@Name = "SettingsFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Settings_File,
                 Parameters.query('Param[@Name = "ParamFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Parameter_File,
                 Parameters.query('Param[@Name = "DatasetStoragePath"]').value('(/Param/@Value)[1]', 'varchar(256)') as Dataset_Storage_Path
          FROM [T_Job_Parameters_History]
          WHERE Most_Recent_Entry = 1
     ) ParamQ ON ParamQ.Job = JS.Job
WHERE J.Most_Recent_Entry = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_History2] TO [DDL_Viewer] AS [dbo]
GO

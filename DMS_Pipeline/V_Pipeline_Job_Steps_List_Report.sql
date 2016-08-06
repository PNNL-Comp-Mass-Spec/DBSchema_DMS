/****** Object:  View [dbo].[V_Pipeline_Job_Steps_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Job_Steps_List_Report]
AS
SELECT JS.Job,
       JS.Step_Number AS Step,
       J.Script,
       JS.Step_Tool AS Tool,
	   ParamQ.Parameter_File,
	   SSN.Name AS Step_State,
       JSN.Name as Job_State_B,
       J.Dataset,
       JS.Start,
       JS.Finish,
       Convert(decimal(9,2), DATEDIFF(second, JS.Start, IsNull(JS.Finish, GetDate())) / 60.0) as Runtime,
       JS.Processor,      
       JS.State,
		CASE WHEN JS.State = 4 THEN Convert(DECIMAL(9,2), PS.Progress)
		     WHEN JS.State = 5 THEN 100
		     ELSE 0 
		END AS [Job Progress],
		CASE WHEN JS.State = 4 AND JS.Step_Tool = 'XTandem' THEN 0						-- We cannot predict runtime for X!Tandem jobs since progress is not properly reported
		     WHEN JS.State = 4 AND PS.Progress > 0     THEN 
		             CONVERT(DECIMAL(9,2), DATEDIFF(second, JS.Start, ISNULL(JS.Finish, GetDate())) /
                                           (PS.Progress / 100.0) / 60.0 / 60.0)
             WHEN JS.State = 5 THEN Convert(decimal(9,2), DATEDIFF(second, JS.Start, IsNull(JS.Finish, GetDate())) / 60.0 / 60.0)
			 ELSE 0
		END AS [RunTime Predicted Hours],
	   Convert(decimal(9,1), DATEDIFF(second, PS.Status_Date, GetDate()) / 60.0) AS [Last CPU Status Minutes],
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Signature,
       JS.CPU_Load,
	   JS.Actual_CPU_Load,
       JS.Memory_Usage_MB,
       JS.Tool_Version_ID,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
	   ParamQ.Settings_File,
	   ParamQ.Dataset_Storage_Path + J.Dataset AS Dataset_Folder_Path,
       JS.Job_Plus_Step AS [#ID]
FROM dbo.T_Job_Steps AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Jobs AS J
       ON JS.Job = J.Job
     INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID
     LEFT OUTER JOIN dbo.T_Processor_Status (READUNCOMMITTED) PS
      ON JS.Processor = PS.Processor_Name
	 LEFT OUTER JOIN ( 
          SELECT Job,
                 Parameters.query('Param[@Name = "SettingsFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Settings_File,
                 Parameters.query('Param[@Name = "ParmFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Parameter_File,
                 Parameters.query('Param[@Name = "DatasetStoragePath"]').value('(/Param/@Value)[1]', 'varchar(256)') as Dataset_Storage_Path                         
          FROM [T_Job_Parameters] 
     ) ParamQ ON ParamQ.Job = JS.Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_List_Report] TO [PNL\D3M578] AS [dbo]
GO

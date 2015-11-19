/****** Object:  View [dbo].[V_Pipeline_Job_Steps_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Job_Steps_History_Detail_Report]
AS
SELECT JS.JobStepSavedCombo AS ID,
       JS.Job,
       JS.Step_Number AS Step,
       J.Dataset,
       J.Script,
       JS.Step_Tool AS Tool,
       SSN.Name AS Step_State,
       JSN.Name as Job_State_B,
       JS.State AS StateID,
       JS.Start,
       JS.Finish,
       Convert(decimal(9,2), DATEDIFF(second, JS.Start, IsNull(JS.Finish, GetDate())) / 60.0) as Runtime_Minutes,      
       JS.Processor,
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Signature,
       0 AS CPU_Load,
	   0 AS Actual_CPU_Load,
       Memory_Usage_MB,
       JS.Tool_Version_ID,
       STV.Tool_Version,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       ParamQ.Dataset_Storage_Path + Dataset AS [Dataset Folder Path],
       J.Transfer_Folder_Path
FROM dbo.T_Job_Steps_History AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
       INNER JOIN ( SELECT Job, Dataset, Script, State, Priority, Transfer_Folder_Path
                    FROM T_Jobs_History
				    WHERE Most_Recent_Entry = 1
				 ) AS J
       ON JS.Job = J.Job 
   INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID   
   LEFT OUTER JOIN ( 
          SELECT Job,
				 Parameters.query('Param[@Name = "SettingsFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Settings_File,
				 Parameters.query('Param[@Name = "ParmFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Parameter_File,
				 Parameters.query('Param[@Name = "DatasetStoragePath"]').value('(/Param/@Value)[1]', 'varchar(256)') as Dataset_Storage_Path
		  FROM [T_Job_Parameters_History] 
		  WHERE Most_Recent_Entry = 1
     ) ParamQ ON ParamQ.Job = JS.Job
     LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV 
       ON JS.Tool_Version_ID = STV.Tool_Version_ID
WHERE Most_Recent_Entry = 1




GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_History_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_History_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO

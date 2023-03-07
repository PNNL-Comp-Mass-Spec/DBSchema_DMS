/****** Object:  View [dbo].[V_Failed_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Failed_Job_Steps]
AS
SELECT JS.Job, JS.Dataset, JS.Step, JS.Script, JS.Tool, 
    JS.State_Name, JS.State, JS.Start, JS.Finish, 
    JS.RunTime_Minutes, JS.Processor, LocalProcs.Machine, 
    JS.Input_Folder, JS.Output_Folder,
    JS.Completion_Code, JS.Completion_Message, 
    JS.Evaluation_Code, JS.Evaluation_Message, 
    JS.Transfer_Folder_Path, 
    '\\' + LocalProcs.Machine + '\DMS_FailedResults\' + JS.Output_Folder AS Failed_Results_Folder_Path
FROM dbo.V_Job_Steps JS INNER JOIN
    dbo.T_Local_Processors LocalProcs ON 
    JS.Processor = LocalProcs.Processor_Name
WHERE (JS.State = 6)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Failed_Job_Steps] TO [DDL_Viewer] AS [dbo]
GO

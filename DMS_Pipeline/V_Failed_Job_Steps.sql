/****** Object:  View [dbo].[V_Failed_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Failed_Job_Steps]
AS
SELECT JS.Job, JS.Dataset, JS.Step, JS.Script, JS.Tool, 
    JS.StateName, JS.State, JS.Start, JS.Finish, 
    JS.RunTime_Minutes, JS.Processor, LocalProcs.Machine, 
    JS.Input_Folder, JS.Output_Folder,
    JS.Completion_Code, JS.Completion_Message, 
    JS.Evaluation_Code, JS.Evaluation_Message, 
    JS.Transfer_Folder_Path, 
    '\\' + LocalProcs.Machine + '\' + SUBSTRING(FailureFolderQ.Value,
     1, 1) + '$' + SUBSTRING(FailureFolderQ.Value, 3, 150) 
    + '\' + JS.Output_Folder AS Failed_Results_Folder_Path
FROM dbo.V_Job_Steps JS INNER JOIN
    dbo.T_Local_Processors LocalProcs ON 
    JS.Processor = LocalProcs.Processor_Name INNER JOIN
        (SELECT M.M_Name, V.Value
      FROM PROTEINSEQS.Manager_Control.dbo.T_ParamType T INNER
            JOIN
           PROTEINSEQS.Manager_Control.dbo.T_ParamValue V ON
            T.ParamID = V.TypeID INNER JOIN
           PROTEINSEQS.Manager_Control.dbo.T_Mgrs M ON 
           V.MgrID = M.M_ID
      WHERE (T.ParamID = 114)) FailureFolderQ ON 
    LocalProcs.Processor_Name = FailureFolderQ.M_Name
WHERE (JS.State = 6) OR 
		-- Use a Bitwise Or to look for Evaluation_Codes that include Code 2,
		--  which indicates for Sequest that NodeCountActive is less than the expected value
      (JS.Evaluation_Code & 2) = 2 AND Start >= DATEADD(day, -2, GETDATE())
  

GO
GRANT VIEW DEFINITION ON [dbo].[V_Failed_Job_Steps] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Failed_Job_Steps] TO [PNL\D3M580] AS [dbo]
GO

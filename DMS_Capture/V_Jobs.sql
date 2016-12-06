/****** Object:  View [dbo].[V_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Jobs]
AS
SELECT J.Job,
       J.Priority,
       J.Script,
       J.[State],
       JSN.Name AS State_Name,
       J.Dataset,
       J.Dataset_ID,
       J.Storage_Server,
       J.Instrument,
       J.Instrument_Class,
       J.Max_Simultaneous_Captures,
       J.Results_Folder_Name,
       J.Imported,
       J.Start,
       J.Finish,
       J.Archive_Busy,
       J.Transfer_Folder_Path,
       J.[Comment],
	   J.Capture_Subfolder
FROM T_Jobs J
     INNER JOIN T_Job_State_Name JSN
       ON J.State = JSN.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Jobs] TO [DDL_Viewer] AS [dbo]
GO

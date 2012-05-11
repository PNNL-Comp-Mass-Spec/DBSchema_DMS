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
       JSN.Name AS State_Name,
       J.[State],
       J.Dataset,
       J.Dataset_ID,
       J.Results_Folder_Name,
       J.Organism_DB_Name,
       J.Imported,
       J.Start,
       J.Finish,
       J.Archive_Busy,
       J.Transfer_Folder_Path,
       J.[Comment],
       J.Storage_Server
FROM T_Jobs J
     INNER JOIN T_Job_State_Name JSN
       ON J.State = JSN.ID


GO
GRANT INSERT ON [dbo].[V_Jobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Jobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Jobs] TO [Limited_Table_Write] AS [dbo]
GO

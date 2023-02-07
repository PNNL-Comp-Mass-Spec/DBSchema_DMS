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
       J.State,
       JSN.Name AS Job_State,
       J.Dataset,
       J.Dataset_ID,
       J.Results_Folder_Name,
       J.Organism_DB_Name,
       J.Imported,
       J.Start,
       J.Finish,
       J.Archive_Busy,
       J.Transfer_Folder_Path,
       J.Owner,
       J.DataPkgID AS Data_Pkg_ID,
       J.[Comment],
       J.Storage_Server,
       J.Special_Processing
FROM T_Job_State_Name JSN
     INNER JOIN T_Jobs J
       ON JSN.ID = J.State

GO
GRANT VIEW DEFINITION ON [dbo].[V_Jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[V_Jobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Jobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Jobs] TO [Limited_Table_Write] AS [dbo]
GO

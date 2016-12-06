/****** Object:  View [dbo].[V_Jobs_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Jobs_History]
AS
SELECT JH.Job,
       JH.[Priority],
       JH.Script,
       JH.[State],
       JSN.Name,
       JH.Dataset,
       JH.Dataset_ID,
       JH.Results_Folder_Name,
       JH.Organism_DB_Name,
       JH.Imported,
       JH.Start,
       JH.Finish,
       JH.Saved,
       JH.Most_Recent_Entry,
       JH.Transfer_Folder_Path,
       JH.[Owner],
       JH.DataPkgID,
       JH.[Comment],
       JH.Special_Processing
FROM T_Job_State_Name JSN
     INNER JOIN T_Jobs_History JH
       ON JSN.ID = JH.State


GO
GRANT VIEW DEFINITION ON [dbo].[V_Jobs_History] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Jobs_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Jobs_History]
AS
SELECT J.Job,
       J.Priority,
       J.Script,
       J.State,
       JSN.Name AS State_Name,
       DS.Dataset_Num AS Dataset,
       J.Dataset_ID,
       Inst.IN_Name AS Instrument,
       Inst.IN_Class AS Instrument_Class,
       J.Results_Folder_Name,
       J.Imported,
       J.Start,
       J.Finish,
       J.Saved
FROM T_Jobs_History J
     INNER JOIN T_Job_State_Name JSN
       ON J.State = JSN.ID
     LEFT OUTER JOIN S_DMS_T_Dataset DS
       ON J.Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN S_DMS_T_Instrument_Name Inst
       ON DS.DS_Instrument_Name_ID = Inst.Instrument_ID

GO

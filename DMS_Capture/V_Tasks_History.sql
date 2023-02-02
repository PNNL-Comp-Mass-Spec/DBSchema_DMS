/****** Object:  View [dbo].[V_Tasks_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Tasks_History]
AS
SELECT J.job,
       J.priority,
       J.script,
       J.state,
       JSN.Name AS state_name,
       DS.Dataset_Num AS dataset,
       J.dataset_id,
       Inst.IN_Name AS instrument,
       Inst.IN_Class AS instrument_class,
       J.results_folder_name,
       J.imported,
       J.start,
       J.finish,
       J.saved
FROM T_Jobs_History J
     INNER JOIN T_Job_State_Name JSN
       ON J.State = JSN.ID
     LEFT OUTER JOIN S_DMS_T_Dataset DS
       ON J.Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN S_DMS_T_Instrument_Name Inst
       ON DS.DS_Instrument_Name_ID = Inst.Instrument_ID


GO

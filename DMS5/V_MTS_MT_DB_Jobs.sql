/****** Object:  View [dbo].[V_MTS_MT_DB_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_MT_DB_Jobs]
AS
SELECT JM.Job,
       DS.Dataset_Num AS Dataset,
       JM.Server_Name,
       JM.MT_DB_Name,
       JM.ResultType,
       JM.Last_Affected,
       JM.Process_State,
       Inst.IN_name AS Instrument,
       C.Campaign_Num AS Campaign,
       AnTool.AJT_toolName as [Tool],
       AJ.AJ_parmFileName as [Parm File],
       AJ.AJ_settingsFileName as [Settings File],
       AJ.AJ_proteinCollectionList as [Protein Collection List],
       DS.DS_sec_sep AS [Separation Type],
	   DFP.Dataset_Folder_Path AS [Dataset Folder Path],
       JM.SortKey AS #SortKey
FROM T_MTS_MT_DB_Jobs_Cached JM
     INNER JOIN T_MTS_MT_DBs_Cached MTDBs
       ON JM.MT_DB_Name = MTDBs.MT_DB_Name
     LEFT OUTER JOIN T_Dataset DS
                     INNER JOIN V_Dataset_Folder_Paths DFP
                       ON DS.Dataset_ID = DFP.Dataset_ID
                     INNER JOIN T_Analysis_Job AJ
                       ON DS.Dataset_ID = AJ.AJ_datasetID
                     INNER JOIN T_Instrument_Name Inst
                       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
                     INNER JOIN T_Experiments E
                       ON DS.Exp_ID = E.Exp_ID
                     INNER JOIN T_Campaign C
                       ON E.EX_campaign_ID = C.Campaign_ID
                     INNER JOIN T_Analysis_Tool AnTool
                       ON AJ.AJ_analysisToolID = ANTool.AJT_toolID
       ON JM.Job = AJ.AJ_jobID


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DB_Jobs] TO [PNL\D3M578] AS [dbo]
GO

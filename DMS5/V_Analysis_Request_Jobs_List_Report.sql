/****** Object:  View [dbo].[V_Analysis_Request_Jobs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Request_Jobs_List_Report]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_priority AS [Pri.],
       ASN.AJS_name AS State,
       Tool.AJT_toolName AS [Tool Name],
       DS.Dataset_Num AS Dataset,
       AJ.AJ_parmFileName AS [Parm File],
       AJ.AJ_settingsFileName AS [Settings File],
       Org.OG_name AS Organism,
       AJ.AJ_organismDBName AS [Organism DB],
       AJ.AJ_proteinCollectionList AS [ProteinCollectionList],
       AJ.AJ_proteinOptionsList AS [ProteinOptions],
       AJ.AJ_comment AS Comment,
       AJ.AJ_created AS Created,
       AJ.AJ_start AS Started,
       AJ.AJ_finish AS Finished,
       AJ.AJ_batchID AS Batch,
       AJ.AJ_requestID AS [#ReqestID],
       DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName AS ResultsFolder,
       DFP.Archive_Folder_Path + '\' + AJ.AJ_resultsFolderName AS ResultsFolder_Archive,
       Convert(decimal(9,2), AJ.AJ_ProcessingTimeMinutes) AS Runtime,
	   DS.Dataset_ID
FROM dbo.T_Analysis_Job AJ
     INNER JOIN dbo.T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Organisms Org
       ON AJ.AJ_organismID = Org.Organism_ID
     INNER JOIN dbo.T_Analysis_Tool Tool
       ON AJ.AJ_analysisToolID = Tool.AJT_toolID
     INNER JOIN dbo.T_Analysis_State_Name ASN
       ON AJ.AJ_StateID = ASN.AJS_stateID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON AJ.AJ_datasetID = DFP.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Request_Jobs_List_Report] TO [PNL\D3M578] AS [dbo]
GO

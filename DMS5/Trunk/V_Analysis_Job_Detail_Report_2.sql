/****** Object:  View [dbo].[V_Analysis_Job_Detail_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Detail_Report_2]
AS
SELECT --CONVERT(varchar(32), AJ.AJ_jobID) AS JobNum,
       AJ.AJ_jobID AS JobNum,
       DS.Dataset_Num AS Dataset,
       DS.DS_folder_name AS [Dataset Folder],
       DFP.Dataset_Folder_Path AS [Dataset Folder Path],
       DFP.Archive_Folder_Path AS [Archive Folder Path],
       InstName.IN_name AS Instrument,
       AnalysisTool.AJT_toolName AS [Tool Name],
       AJ.AJ_parmFileName AS [Parm File],
       AnalysisTool.AJT_parmFileStoragePath AS [Parm File Storage Path],
       AJ.AJ_settingsFileName AS [Settings File],
       Org.OG_name AS Organism,
       AJ.AJ_organismDBName AS [Organism DB],
       dbo.GetFASTAFilePath(AJ.AJ_organismDBName, Org.OG_name) AS [Organism DB Storage Path],
       AJ.AJ_proteinCollectionList AS [Protein Collection List],
       AJ.AJ_proteinOptionsList AS [Protein Options List],
       ASN.AJS_name AS State,
       Convert(decimal(9,2), AJ.AJ_ProcessingTimeMinutes) AS [Runtime Minutes],
       AJ.AJ_owner AS Owner,
       AJ.AJ_priority AS Priority,
       AJ.AJ_comment AS Comment,
       AJ.AJ_assignedProcessorName AS [Assigned Processor],
       AJ.AJ_extractionProcessor AS [DEX Processor],
       DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName AS [Results Folder Path],
       DFP.Archive_Folder_Path + '\' + AJ.AJ_resultsFolderName AS [Archive Results Folder Path],
       AJ.AJ_created AS Created,
       AJ.AJ_start AS Started,
       AJ.AJ_finish AS Finished,
       AJ.AJ_requestID AS Request,
       AJPGA.Group_ID AS [Processor Group ID],
       AJPG.Group_Name AS [Processor Group Name],
       AJPGA.Entered_By AS [Processor Group Assignee],
       AJ.AJ_Analysis_Manager_Error AS [AM Code],
       dbo.GetDEMCodeString(AJ.AJ_Data_Extraction_Error) AS [DEM Code],
       CASE AJ.AJ_propagationMode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS [Export Mode]
FROM dbo.T_Organisms AS Org
     INNER JOIN dbo.T_Analysis_Job AS AJ
                INNER JOIN dbo.T_Dataset AS DS
                  ON AJ.AJ_datasetID = DS.Dataset_ID
                INNER JOIN dbo.V_Dataset_Folder_Paths AS DFP
                  ON DFP.Dataset_ID = DS.Dataset_ID
                INNER JOIN dbo.t_storage_path AS SPath
                  ON DS.DS_storage_path_ID = SPath.SP_path_ID
                INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool
                  ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
                INNER JOIN dbo.T_Analysis_State_Name AS ASN
                  ON AJ.AJ_StateID = ASN.AJS_stateID
                INNER JOIN dbo.T_Instrument_Name AS InstName
                  ON DS.DS_instrument_name_ID = InstName.Instrument_ID
       ON Org.Organism_ID = AJ.AJ_organismID
     LEFT OUTER JOIN dbo.T_Analysis_Job_Processor_Group AS AJPG
                     INNER JOIN dbo.T_Analysis_Job_Processor_Group_Associations AS AJPGA
                       ON AJPG.ID = AJPGA.Group_ID
       ON AJ.AJ_jobID = AJPGA.Job_ID

GO

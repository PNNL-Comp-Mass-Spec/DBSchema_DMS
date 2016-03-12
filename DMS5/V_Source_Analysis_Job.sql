/****** Object:  View [dbo].[V_Source_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Source_Analysis_Job] as
SELECT  AJ.AJ_jobID AS Job ,
        AJ.AJ_StateNameCached AS State ,
        AnalysisTool.AJT_toolName AS Tool ,
        DS.Dataset_Num AS Dataset ,
        E.Experiment_Num AS Experiment ,
        InstName.IN_name AS Instrument ,
        AJ.AJ_parmFileName AS [Parm File] ,
        AJ.AJ_settingsFileName AS Settings_File ,
        AJ.AJ_comment AS Comment ,
        AJ.AJ_requestID AS [Job Request] ,
        ISNULL(AJ.AJ_resultsFolderName, '(none)') AS [Results Folder] ,
        InstClass.raw_data_type AS RawDataType ,
        SPath.SP_vol_name_client + 'DMS3_XFER\' AS transferFolderPath,
        ArchPath.AP_network_share_path AS [Archive Folder Path],
        SP.SP_vol_name_client + SP.SP_path AS [Dataset Storage Path],
		DSArch.AS_instrument_data_purged As InstrumentDataPurged
FROM    dbo.T_Analysis_Job AS AJ
        INNER JOIN dbo.T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID
        INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
        INNER JOIN dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
        INNER JOIN dbo.T_Instrument_Class AS InstClass ON InstClass.IN_class = InstName.IN_class
        INNER JOIN dbo.T_Experiments AS E ON DS.Exp_ID = E.Exp_ID
        INNER JOIN dbo.t_storage_path AS SPath ON DS.DS_storage_path_ID = SPath.SP_path_ID
        INNER JOIN dbo.T_Dataset_Archive AS DSArch ON DS.Dataset_ID = DSArch.AS_Dataset_ID
        INNER JOIN dbo.T_Archive_Path AS ArchPath ON DSArch.AS_storage_path_ID = ArchPath.AP_path_ID
        INNER JOIN dbo.t_storage_path AS SP ON DS.DS_storage_path_ID = SP.SP_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Source_Analysis_Job] TO [PNL\D3M578] AS [dbo]
GO

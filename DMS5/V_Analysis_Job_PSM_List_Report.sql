/****** Object:  View [dbo].[V_Analysis_Job_PSM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Analysis_Job_PSM_List_Report] as
SELECT  AJ.AJ_jobID AS Job,
        AJ.AJ_StateNameCached AS State,
        AnalysisTool.AJT_toolName AS Tool,
        DS.Dataset_Num AS Dataset,
        InstName.IN_name AS Instrument,
        PSM.Spectra_Searched,
        PSM.Total_PSMs AS [Total PSMs MSGF],
        PSM.Unique_Peptides AS [Unique Peptides MSGF],
        PSM.Unique_Proteins AS [Unique Proteins MSGF],
        PSM.Total_PSMs_FDR_Filter AS [Total PSMs FDR],
        PSM.Unique_Peptides_FDR_Filter AS [Unique Peptides FDR],
        PSM.Unique_Proteins_FDR_Filter AS [Unique Proteins FDR],
        PSM.MSGF_Threshold AS [MSGF Threshold], 
        Convert(decimal(9,2), PSM.FDR_Threshold * 100.0) AS [FDR Threshold (%)], 
		-- CAST(QCM.P_4A * 100 AS decimal(9,1)) AS PctTryptic,
	    -- CAST(QCM.P_4B * 100 AS decimal(9,1)) AS PctMissedClvg,
	    -- QCM.P_2A AS TrypticPSMs,
	    -- QCM.Keratin_2A AS KeratinPSMs,
		-- QCM.Trypsin_2A AS TrypsinPSMs,
		PSM.Tryptic_Peptides_FDR AS [Unique Tryptic Peptides],
	    CAST(PSM.Tryptic_Peptides_FDR / Cast(NullIf(PSM.Unique_Peptides_FDR_Filter, 0) as float) * 100 AS decimal(9,1)) AS PctTryptic,
		CAST(PSM.Missed_Cleavage_Ratio_FDR * 100 AS decimal(9,1)) AS PctMissedClvg,
	    PSM.Keratin_Peptides_FDR AS [KeratinPep],
	    PSM.Trypsin_Peptides_FDR AS [TrypsinPep],
        PSM.Last_Affected AS [PSM Stats Date],
	    PhosphoPSM.PhosphoPeptides AS PhosphoPep,
		PhosphoPSM.CTermK_Phosphopeptides AS [CTermK PhosphoPep],
		PhosphoPSM.CTermR_Phosphopeptides AS [CTermR PhosphoPep],
		CAST(PhosphoPSM.MissedCleavageRatio * 100 AS decimal(9,1)) AS [Phospho PctMissedClvg],
        C.Campaign_Num AS Campaign,
        E.Experiment_Num AS Experiment,
        AJ.AJ_parmFileName AS [Parm File],
        AJ.AJ_settingsFileName AS Settings_File,
        Org.OG_name AS Organism,
        AJ.AJ_organismDBName AS [Organism DB],
        AJ.AJ_proteinCollectionList AS [Protein Collection List],
        AJ.AJ_proteinOptionsList AS [Protein Options],
        AJ.AJ_comment AS Comment,
        AJ.AJ_finish AS Finished,
        CONVERT(DECIMAL(9, 2), AJ.AJ_ProcessingTimeMinutes) AS Runtime,
        AJ.AJ_requestID AS [Job Request],
        ISNULL(AJ.AJ_resultsFolderName, '(none)') AS [Results Folder],
        CASE WHEN AJ.AJ_Purged = 0
        THEN SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName 
        ELSE DAP.Archive_Path + '\' + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName 
        END AS [Results Folder Path],        
        DR.DRN_name AS Rating,
        DS.Acq_Length_Minutes AS [Acq Length],
        DS.Dataset_ID,
        DS.Acq_Time_Start,
        AJ.AJ_StateID AS StateID,
        CAST(AJ.Progress AS DECIMAL(9,2)) AS Job_Progress,
	    CAST(AJ.ETA_Minutes AS DECIMAL(18,1)) AS Job_ETA_Minutes
FROM    dbo.V_Dataset_Archive_Path AS DAP
        RIGHT OUTER JOIN dbo.T_Analysis_Job AS AJ
        INNER JOIN dbo.T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID
        INNER JOIN dbo.T_Storage_Path SPath ON DS.DS_storage_path_ID = SPath.SP_path_ID
        INNER JOIN dbo.T_DatasetRatingName AS DR ON DS.DS_rating = DR.DRN_state_ID
        INNER JOIN dbo.T_Organisms AS Org ON AJ.AJ_organismID = Org.Organism_ID
        INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
        INNER JOIN dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
        INNER JOIN dbo.T_Experiments AS E ON DS.Exp_ID = E.Exp_ID
        INNER JOIN dbo.T_Campaign AS C ON E.EX_campaign_ID = C.Campaign_ID ON DAP.Dataset_ID = DS.Dataset_ID        
        LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats PSM ON AJ.AJ_JobID = PSM.Job
		LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats_Phospho PhosphoPSM ON PSM.Job = PhosphoPSM.Job
WHERE AJ.AJ_analysisToolID IN ( SELECT AJT_toolID
                                FROM T_Analysis_Tool
                                WHERE AJT_resultType LIKE '%peptide_hit' OR 
								      AJT_resultType = 'Gly_ID')





GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_PSM_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_PSM_List_Report] TO [PNL\D3M580] AS [dbo]
GO

/****** Object:  View [dbo].[V_Ext_Analysis_Job_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW[dbo].[V_Ext_Analysis_Job_List_Report]
AS
SELECT  AJ.AJ_jobID AS Job, 
       'x' as Sel,
        AJ.AJ_StateNameCached AS State, 
        AnalysisTool.AJT_toolName AS Tool, 
        DS.Dataset_Num AS Dataset, 
        C.Campaign_Num AS Campaign, 
        E.Experiment_Num AS Experiment, 
        InstName.IN_name AS Instrument, 
        AJ.AJ_parmFileName AS [Parm File], 
        AJ.AJ_settingsFileName AS Settings_File, 
        Org.OG_name AS Organism, 
        AJ.AJ_organismDBName AS [Organism DB], 
        AJ.AJ_proteinCollectionList AS [Protein Collection List], 
        AJ.AJ_proteinOptionsList AS [Protein Options], 
        AJ.AJ_comment AS Comment, 
        AJ.AJ_created AS Created
FROM    dbo.T_Analysis_Job AS AJ 
        JOIN dbo.T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID 
        JOIN dbo.T_Organisms AS Org ON AJ.AJ_organismID = Org.Organism_ID 
        JOIN dbo.T_Analysis_Tool AS AnalysisTool ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID 
        JOIN dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID 
        JOIN dbo.T_Experiments AS E ON DS.Exp_ID = E.Exp_ID 
        JOIN dbo.T_Campaign AS C ON E.EX_campaign_ID = C.Campaign_ID
WHERE EXISTS 
		(
			SELECT 1
			FROM T_Analysis_Job AJ1
				JOIN T_Dataset_Archive DSA ON DSA.AS_Dataset_ID = AJ1.AJ_DatasetID 
				JOIN T_DatasetArchiveStateName DSN ON DSN.DASN_StateID = DSA.AS_state_ID AND DSN.DASN_StateName = 'Complete'
			WHERE AJ.AJ_JobID = AJ1.AJ_JobID
		)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Analysis_Job_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Analysis_Job_List_Report] TO [PNL\D3M580] AS [dbo]
GO

/****** Object:  View [dbo].[V_Predefined_Analysis_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Predefined_Analysis_List_Report
AS
SELECT     TOP 100 PERCENT AD_ID AS ID, AD_instrumentClassCriteria AS [Instrument Class], AD_level AS [Level], AD_sequence AS [Seq.], 
                      AD_nextLevel AS [Next Lvl.], AD_analysisToolName AS [Analysis Tool], AD_instrumentNameCriteria AS [Instrument Crit.], 
                      AD_organismNameCriteria AS [Organism Crit.], AD_campaignNameCriteria AS [Campaign Crit.], AD_experimentNameCriteria AS [Experiment Crit.], 
                      AD_labellingInclCriteria AS [ExpLabelingCrit.], AD_datasetNameCriteria AS [DatasetCrit.], AD_expCommentCriteria AS [ExpCommentCrit.], 
                      AD_parmFileName AS [Parm File], AD_settingsFileName AS [Settings File], AD_organismName AS Organism, AD_organismDBName AS [Organism DB], 
                      AD_proteinCollectionList AS [Prot. Coll. List], AD_proteinOptionsList AS [Prot. Opts. List], AD_priority AS priority
FROM         dbo.T_Predefined_Analysis
WHERE     (AD_enabled > 0)
ORDER BY AD_instrumentClassCriteria, AD_level, AD_sequence, AD_ID


GO

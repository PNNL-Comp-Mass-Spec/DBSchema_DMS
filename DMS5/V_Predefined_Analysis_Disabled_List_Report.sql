/****** Object:  View [dbo].[V_Predefined_Analysis_Disabled_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Predefined_Analysis_Disabled_List_Report]
AS
SELECT PA.AD_ID AS ID,
       PA.AD_instrumentClassCriteria AS [Instrument Class],
       PA.AD_level AS [Level],
       PA.AD_sequence AS [Seq.],
       PA.AD_nextLevel AS [Next Lvl.],
       PA.AD_analysisToolName AS [Analysis Tool],
       CASE WHEN PA.Trigger_Before_Disposition = 1
            THEN 'Before Disposition' 
            ELSE 'Normal' 
            END AS [Trigger Mode],
       CASE PA.Propagation_Mode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS [Export Mode],
       PA.AD_instrumentNameCriteria AS [Instrument Crit.],
       PA.AD_organismNameCriteria AS [Organism Crit.],
       PA.AD_campaignNameCriteria AS [Campaign Crit.],
       PA.AD_experimentNameCriteria AS [Experiment Crit.],
       PA.AD_labellingInclCriteria AS [ExpLabelingCrit.],
       PA.AD_labellingExclCriteria AS [ExpLabeling Excl.],
       PA.AD_datasetNameCriteria AS [DatasetCrit.],
       PA.AD_expCommentCriteria AS [ExpCommentCrit.],
       PA.AD_separationTypeCriteria AS [Separation Crit.],
       PA.AD_campaignExclCriteria AS [Campaign Excl. Crit.],
       PA.AD_experimentExclCriteria AS [Experiment Excl. Crit.],
       PA.AD_datasetExclCriteria AS [Dataset Excl. Crit.],
       PA.AD_datasetTypeCriteria AS [Dataset Type Crit.],
       PA.AD_parmFileName AS [Parm File],
       PA.AD_settingsFileName AS [Settings File],
       Org.OG_name AS Organism,
       PA.AD_organismDBName AS [Organism DB],
       PA.AD_proteinCollectionList AS [Prot. Coll. List],
       PA.AD_proteinOptionsList AS [Prot. Opts. List],
       PA.AD_priority AS priority,
       PA.Last_Affected
FROM dbo.T_Predefined_Analysis AS PA
     INNER JOIN dbo.T_Organisms AS Org
       ON PA.AD_organism_ID = Org.Organism_ID
WHERE (PA.AD_enabled = 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Disabled_List_Report] TO [DDL_Viewer] AS [dbo]
GO

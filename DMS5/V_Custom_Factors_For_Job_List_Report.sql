/****** Object:  View [dbo].[V_Custom_Factors_For_Job_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Custom_Factors_For_Job_List_Report
AS
SELECT TAJ.AJ_jobID AS job,
       TTOOL.AJT_toolName AS tool,
       TFAC.factor,
       TFAC.value,
       DS.Dataset_Num AS dataset,
       RR.DatasetID AS dataset_id,
       RR.ID AS request,
       ISNULL(DSExp.Experiment_Num, RRExp.Experiment_Num) AS experiment,
       ISNULL(DSCampaign.Campaign_Num, RRCampaign.Campaign_Num) AS campaign
FROM ( SELECT TargetID AS RequestID,
              Name AS Factor,
              value
       FROM T_Factor AS F
       WHERE type = 'Run_Request' ) AS TFAC
     INNER JOIN T_Requested_Run AS RR
       ON TFAC.RequestID = RR.ID
     LEFT OUTER JOIN T_Dataset AS DS
       ON RR.DatasetID = DS.Dataset_ID
     INNER JOIN T_Campaign AS RRCampaign
                INNER JOIN T_Experiments AS RRExp
                  ON RRCampaign.Campaign_ID = RRExp.EX_campaign_ID
       ON RR.Exp_ID = RRExp.Exp_ID
     LEFT OUTER JOIN T_Experiments AS DSExp
       ON DS.Exp_ID = DSExp.Exp_ID
     LEFT OUTER JOIN T_Campaign AS DSCampaign
       ON DSExp.EX_campaign_ID = DSCampaign.Campaign_ID
     INNER JOIN T_Analysis_Job AS TAJ
       ON TAJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Analysis_Tool AS TTOOL
       ON TAJ.AJ_analysisToolID = TTOOL.AJT_toolID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Custom_Factors_For_Job_List_Report] TO [DDL_Viewer] AS [dbo]
GO

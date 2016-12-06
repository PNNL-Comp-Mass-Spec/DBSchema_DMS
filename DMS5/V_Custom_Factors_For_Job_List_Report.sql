/****** Object:  View [dbo].[V_Custom_Factors_For_Job_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view V_Custom_Factors_For_Job_List_Report as
SELECT  TAJ.AJ_jobID AS Job ,
        TTOOL.AJT_toolName AS Tool ,
        TFAC.Factor ,
        TFAC.Value ,
        DS.Dataset_Num AS Dataset ,
        RR.DatasetID AS Dataset_ID ,
        RR.ID AS Request ,
        ISNULL(DSExp.Experiment_Num, RRExp.Experiment_Num) AS Experiment ,
        ISNULL(DSCampaign.Campaign_Num, RRCampaign.Campaign_Num) AS Campaign
FROM    ( SELECT    TargetID AS RequestID ,
                    Name AS Factor ,
                    Value
          FROM      T_Factor AS F
          WHERE     ( Type = 'Run_Request' )
        ) AS TFAC
        INNER JOIN T_Requested_Run AS RR ON TFAC.RequestID = RR.ID
        LEFT OUTER JOIN T_Dataset AS DS ON RR.DatasetID = DS.Dataset_ID
        INNER JOIN T_Campaign AS RRCampaign
        INNER JOIN T_Experiments AS RRExp ON RRCampaign.Campaign_ID = RRExp.EX_campaign_ID ON RR.Exp_ID = RRExp.Exp_ID
        LEFT OUTER JOIN T_Experiments AS DSExp ON DS.Exp_ID = DSExp.Exp_ID
        LEFT OUTER JOIN T_Campaign AS DSCampaign ON DSExp.EX_campaign_ID = DSCampaign.Campaign_ID
        INNER JOIN T_Analysis_Job AS TAJ ON TAJ.AJ_datasetID = DS.Dataset_ID
        INNER JOIN T_Analysis_Tool AS TTOOL ON TAJ.AJ_analysisToolID = TTOOL.AJT_toolID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Custom_Factors_For_Job_List_Report] TO [DDL_Viewer] AS [dbo]
GO

/****** Object:  View [dbo].[V_Factors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Factors_List_Report] as
SELECT F.Factor,
       F.Value,
       RR.ID AS Request,
       RR.RDS_BatchID AS Batch,
       RR.DatasetID,
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign
FROM T_Dataset DS
     RIGHT OUTER JOIN T_Campaign C
                      INNER JOIN T_Experiments E
                        ON C.Campaign_ID = E.EX_campaign_ID
                      RIGHT OUTER JOIN (SELECT TargetID AS RequestID,
                                               Name AS Factor,
                                               Value
                                        FROM T_Factor F
                                        WHERE (TYPE = 'Run_Request')
                                        UNION
                                        SELECT ID AS RequestID,
                                               'Block' AS Factor,
                                               Convert(varchar(12), RDS_Block) AS Value
                                        FROM T_Requested_Run
                                        WHERE NOT RDS_Block IS NULL
                                        UNION
                                        SELECT ID AS RequestID,
                                               'Requested_Run_Order' AS Factor,
                                               Convert(varchar(12), RDS_Run_Order) AS Value
                                        FROM T_Requested_Run
                                        WHERE NOT RDS_Run_Order IS NULL 
										) F
                                       INNER JOIN T_Requested_Run RR
                                         ON F.RequestID = RR.ID
                        ON E.Exp_ID = RR.Exp_ID
       ON DS.Dataset_ID = RR.DatasetID
    

GO

/****** Object:  View [dbo].[V_Run_Factors_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Run_Factors_Export as
SELECT
  F.Name AS Factor,
  F.Value,
  RR.ID AS Request,
  RR.RDS_BatchID AS Batch,
  RR.DatasetID,
  DS.Dataset_Num AS Dataset,
  E.Experiment_Num AS Experiment,
  C.Campaign_Num AS Campaign
FROM
  T_Dataset AS DS
  INNER JOIN T_Experiments AS E ON E.Exp_ID = DS.Exp_ID
  INNER JOIN T_Requested_Run AS RR  ON DS.Dataset_ID = RR.DatasetID
  INNER JOIN T_Campaign AS C ON C.Campaign_ID = E.EX_campaign_ID
  INNER JOIN T_Factor AS F ON F.TargetID = RR.ID
WHERE
  ( F.Type = 'Run_Request' )


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Factors_Export] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Factors_Export] TO [PNL\D3M580] AS [dbo]
GO

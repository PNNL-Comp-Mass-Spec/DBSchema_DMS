/****** Object:  View [dbo].[V_Dataset_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Tracking]
AS
SELECT DS.Dataset_Num AS dataset,
       DSN.DSS_name AS state,
       DS.DS_created AS created,
       E.Experiment_Num AS experiment,
       E.EX_created AS [created (ex)],
       CCE.Cell_Culture_List AS [cell cultures],
       C.Campaign_Num AS campaign,
       DS.Dataset_ID AS id
FROM T_Dataset DS
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Dataset_State_Name DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     LEFT OUTER JOIN T_Cached_Experiment_Components CCE
       ON E.Exp_ID = CCE.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Tracking] TO [DDL_Viewer] AS [dbo]
GO

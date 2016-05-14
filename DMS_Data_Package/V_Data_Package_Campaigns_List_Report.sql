/****** Object:  View [dbo].[V_Data_Package_Campaigns_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Data_Package_Campaigns_List_Report]
AS
SELECT DISTINCT DPE.Data_Package_ID AS ID,
                C.Campaign_Num AS Campaign,
				E.EX_campaign_ID AS Campaign_ID
FROM T_Data_Package_Experiments DPE
     INNER JOIN S_Experiment_List E
       ON DPE.Experiment_ID = E.Exp_ID
     INNER JOIN S_Campaign_List C
       ON E.ex_Campaign_ID = C.Campaign_ID
UNION
SELECT DISTINCT DPD.Data_Package_ID AS ID,
                C.Campaign_Num AS Campaign,
				E.ex_Campaign_ID AS Campaign_ID
FROM T_Data_Package_Datasets DPD
     INNER JOIN S_Dataset D
       ON DPD.Dataset_ID = D.Dataset_ID
     INNER JOIN S_Experiment_List E
       ON D.Exp_ID = E.Exp_ID
     INNER JOIN S_Campaign_List C
       ON E.ex_Campaign_ID = C.Campaign_ID


GO

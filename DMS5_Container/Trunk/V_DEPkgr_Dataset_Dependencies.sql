/****** Object:  View [dbo].[V_DEPkgr_Dataset_Dependencies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Dataset_Dependencies
AS
SELECT     TOP 100 PERCENT dbo.V_DEPkgr_Datasets.Dataset_ID, dbo.V_DEPkgr_Datasets.Dataset_Name, dbo.V_DEPkgr_All_Run_Requests.Request_ID, 
                      dbo.V_DEPkgr_Datasets.Created_Date, dbo.V_DEPkgr_ExpCCMap.Culture_ID, dbo.V_DEPkgr_Datasets.Experiment_ID, 
                      dbo.V_DEPkgr_Experiments.Experiment_Name, dbo.V_DEPkgr_Experiments.Campaign_ID
FROM         dbo.V_DEPkgr_ExpCCMap INNER JOIN
                      dbo.V_DEPkgr_Experiments ON dbo.V_DEPkgr_ExpCCMap.Experiment_ID = dbo.V_DEPkgr_Experiments.Experiment_ID INNER JOIN
                      dbo.V_DEPkgr_Datasets ON dbo.V_DEPkgr_Experiments.Experiment_ID = dbo.V_DEPkgr_Datasets.Experiment_ID FULL OUTER JOIN
                      dbo.V_DEPkgr_All_Run_Requests ON dbo.V_DEPkgr_Datasets.Dataset_ID = dbo.V_DEPkgr_All_Run_Requests.Dataset_ID
ORDER BY dbo.V_DEPkgr_All_Run_Requests.Request_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Dataset_Dependencies] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Dataset_Dependencies] TO [PNL\D3M580] AS [dbo]
GO
